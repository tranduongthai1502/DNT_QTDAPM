import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/farm_model.dart';
import '../../../models/order_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/traceability_provider.dart';
import '../../../services/mock_data_service.dart';
import '../../widgets/product_card.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'qr_scanner_screen.dart';
import 'traceability_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _catalogKey = GlobalKey();
  final GlobalKey _farmsKey = GlobalKey();
  final GlobalKey _flowKey = GlobalKey();
  final List<FarmModel> _farms = MockDataService.getMockFarms();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  }

  void _syncSearchText(String query) {
    if (_searchController.text != query) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    final trace = context.watch<TraceabilityProvider>();

    _syncSearchText(products.searchQuery);

    final width = MediaQuery.sizeOf(context).width;
    final activeOrderCount = orders.orders
        .where(
          (o) =>
              o.status != OrderStatus.delivered &&
              o.status != OrderStatus.cancelled,
        )
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildHeader(
        context: context,
        cart: cart,
        auth: auth,
        activeOrderCount: activeOrderCount,
        width: width,
      ),
      drawer: _buildDrawer(context, auth, activeOrderCount),
      bottomNavigationBar: cart.itemCount > 0
          ? _FloatingMiniCartBar(
              cart: cart,
              onOpenCart: () => _openCart(context),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: products.loadProducts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _TopAnnouncementStrip(width: width)),
            SliverToBoxAdapter(
              child: _CenteredSection(
                width: width,
                child: _StoreUtilityBar(
                  products: products,
                  searchController: _searchController,
                  onSelectCategory: (cat) {
                    products.setCategory(cat);
                    _scrollTo(_catalogKey);
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CenteredSection(
                width: width,
                child: _HeroSection(
                  productCount: products.products.length,
                  farmCount: _farms.length,
                  onShopNow: () => _scrollTo(_catalogKey),
                  onScan: () => _openScanner(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CenteredSection(width: width, child: const _TrustStrip()),
            ),
            SliverToBoxAdapter(
              child: _CenteredSection(
                width: width,
                child: _CategoryShowcase(
                  products: products,
                  onSelectCategory: (cat) {
                    products.setCategory(cat);
                    _scrollTo(_catalogKey);
                  },
                  onSelectGapSpecial: () {
                    products.resetFilters();
                    products.setSortOption(ProductSortOption.ratingDesc);
                    _scrollTo(_catalogKey);
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CenteredSection(
                width: width,
                child: _FeaturedSection(
                  products: products,
                  onSeeAll: () {
                    products.resetFilters();
                    _scrollTo(_catalogKey);
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CenteredSection(
                width: width,
                child: _TraceabilityShowcaseBanner(
                  traceProvider: trace,
                  onOpenScanner: () => _openScanner(context),
                  onOpenBatch: (batchId) => _openBatchTrace(context, batchId),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CenteredSection(
                width: width,
                child: Container(
                  key: _catalogKey,
                  child: _CatalogToolbar(
                    products: products,
                    farms: _farms,
                    searchController: _searchController,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CenteredSection(
                width: width,
                child: _CatalogGridSection(products: products),
              ),
            ),
            SliverToBoxAdapter(
              child: _CenteredSection(
                width: width,
                child: Container(
                  key: _farmsKey,
                  child: _PartnerFarmsSection(
                    farms: _farms,
                    selectedFarmId: products.selectedFarmId,
                    onSelectFarm: (farmId) {
                      products.setFarmFilter(farmId);
                      _scrollTo(_catalogKey);
                    },
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CenteredSection(
                width: width,
                child: Container(
                  key: _flowKey,
                  child: _CustomerFlowSection(
                    onShop: () => _scrollTo(_catalogKey),
                    onScan: () => _openScanner(context),
                    onOrders: () => _openOrders(context),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _StoreFooter(
                onOpenOrders: () => _openOrders(context),
                onOpenScanner: () => _openScanner(context),
                onOpenCart: () => _openCart(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader({
    required BuildContext context,
    required CartProvider cart,
    required AuthProvider auth,
    required int activeOrderCount,
    required double width,
  }) {
    final isDesktop = width >= 980;
    final isCompact = width < 560;

    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.white,
      toolbarHeight: 72,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.softBorder),
      ),
      leading: Builder(
        builder: (ctx) => IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      titleSpacing: 4,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppColors.accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'freshfarm',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  height: 1,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!isCompact)
                const Text(
                  'Nông sản chuẩn GAP • Truy xuất QR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (isDesktop) ...[
            const SizedBox(width: 28),
            _HeaderNavButton(
              label: 'Cửa hàng',
              onTap: () => _scrollTo(_catalogKey),
            ),
            _HeaderNavButton(
              label: 'Vùng trồng',
              onTap: () => _scrollTo(_farmsKey),
            ),
            _HeaderNavButton(
              label: 'Quy trình mua',
              onTap: () => _scrollTo(_flowKey),
            ),
            _HeaderNavButton(
              label: 'Quét QR',
              onTap: () => _openScanner(context),
            ),
          ],
        ],
      ),
      actions: [
        if (!isCompact)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _showRolePicker(context, auth),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _roleIcon(auth.activeRole),
                      size: 15,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      auth.activeRole.shortTag,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Order history quick pill/button
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              isDesktop
                  ? OutlinedButton.icon(
                      onPressed: () => _openOrders(context),
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text('Đơn hàng'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.softBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Đơn hàng của tôi',
                      icon: const Icon(Icons.receipt_long_rounded),
                      onPressed: () => _openOrders(context),
                    ),
              if (activeOrderCount > 0)
                Positioned(
                  right: isDesktop ? -4 : 6,
                  top: isDesktop ? -4 : 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeOrderCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!isDesktop)
          IconButton(
            tooltip: 'Quét mã QR',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => _openScanner(context),
          ),
        // Cart button
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: isDesktop
              ? ElevatedButton.icon(
                  onPressed: () => _openCart(context),
                  icon: const Icon(Icons.shopping_bag_rounded, size: 17),
                  label: Text(
                    cart.itemCount > 0
                        ? 'Giỏ (${cart.itemCount}) • ${CurrencyFormatter.format(cart.subtotal)}'
                        : 'Giỏ hàng (0)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Giỏ hàng',
                      icon: const Icon(Icons.shopping_bag_outlined),
                      onPressed: () => _openCart(context),
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 6,
                        top: 9,
                        child: Container(
                          padding: const EdgeInsets.all(4.5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    AuthProvider auth,
    int activeOrderCount,
  ) {
    final user = auth.currentUser;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 24, 20, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: AppColors.accent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'freshfarm',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    user?.name ?? 'Khách hàng FreshFarm',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user?.email ?? 'Tài khoản người tiêu dùng',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Trang bán hàng'),
              onTap: () {
                Navigator.pop(context);
                _scrollTo(_catalogKey);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Đơn hàng của tôi'),
              trailing: activeOrderCount > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$activeOrderCount đang xử lý',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                _openOrders(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Quét QR Truy xuất nguồn gốc'),
              onTap: () {
                Navigator.pop(context);
                _openScanner(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Giỏ hàng & Thanh toán'),
              onTap: () {
                Navigator.pop(context);
                _openCart(context);
              },
            ),
            const Divider(height: 20),
            ListTile(
              leading: const Icon(
                Icons.switch_account_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Đổi vai trò hệ thống'),
              subtitle: const Text('Khách hàng • Nông hộ • Kho vận • Admin'),
              onTap: () {
                Navigator.pop(context);
                _showRolePicker(context, auth);
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'FRESHFARM VKU • NÔNG SẢN MINH BẠCH',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.6,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCart(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CartScreen()),
  );

  void _openOrders(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
  );

  void _openScanner(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
  );

  Future<void> _openBatchTrace(BuildContext context, String batchId) async {
    final trace = context.read<TraceabilityProvider>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final batch = await trace.findBatch(batchId);
    if (!mounted) return;
    if (batch != null) {
      nav.push(
        MaterialPageRoute(builder: (_) => TraceabilityScreen(batch: batch)),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin lô hàng')),
      );
    }
  }

  void _showRolePicker(BuildContext context, AuthProvider auth) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chuyển vai trò trải nghiệm',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kiểm tra nhanh 4 góc nhìn nghiệp vụ trong hệ thống FreshFarm.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ...UserRole.values.map(
                (role) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: role == auth.activeRole
                          ? AppColors.surfaceVariant
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _roleIcon(role),
                      color: role == auth.activeRole
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  title: Text(
                    role.displayName,
                    style: TextStyle(
                      fontWeight: role == auth.activeRole
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _roleSubtitle(role),
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: role == auth.activeRole
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    auth.switchRole(role);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return Icons.shopping_basket_outlined;
      case UserRole.farmer:
        return Icons.agriculture_rounded;
      case UserRole.supplier:
        return Icons.warehouse_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }

  String _roleSubtitle(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Mua sắm nông sản, quét QR, thanh toán VietQR & theo dõi đơn';
      case UserRole.farmer:
        return 'Quản lý trang trại, tạo lô hàng & sinh tem QR';
      case UserRole.supplier:
        return 'Quản lý tồn kho FIFO & điều phối vận chuyển';
      case UserRole.admin:
        return 'Dashboard doanh thu TMĐT & Quản trị dự án EVM';
    }
  }
}

class _HeaderNavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _HeaderNavButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
    child: Text(label),
  );
}

class _CenteredSection extends StatelessWidget {
  final double width;
  final Widget child;
  const _CenteredSection({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    final horizontal = width >= 760 ? 24.0 : 16.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: child,
        ),
      ),
    );
  }
}

class _TopAnnouncementStrip extends StatelessWidget {
  final double width;
  const _TopAnnouncementStrip({required this.width});

  @override
  Widget build(BuildContext context) {
    final isWide = width >= 820;
    return Container(
      width: double.infinity,
      color: const Color(0xFF133A27),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _CenteredSection(
        width: width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Thu hoạch tươi mới mỗi sáng từ Đà Lạt • Mộc Châu • Bến Tre • Tiền Giang',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isWide)
              const Text(
                'Freeship đơn từ 300.000đ  •  Giảm 30.000đ đơn từ 400.000đ',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoreUtilityBar extends StatelessWidget {
  final ProductProvider products;
  final TextEditingController searchController;
  final ValueChanged<String> onSelectCategory;

  const _StoreUtilityBar({
    required this.products,
    required this.searchController,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 880;
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 14),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, right: 6),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: products.categories
                          .map(
                            (category) => _NavItem(
                              label: category == 'Tất cả'
                                  ? 'Tất cả nông sản'
                                  : category,
                              selected: products.selectedCategory == category,
                              onTap: () => onSelectCategory(category),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 320,
                  child: _InlineSearchField(
                    controller: searchController,
                    products: products,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _InlineSearchField(
                  controller: searchController,
                  products: products,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: products.categories
                        .map(
                          (category) => _NavItem(
                            label: category == 'Tất cả'
                                ? 'Tất cả nông sản'
                                : category,
                            selected: products.selectedCategory == category,
                            onTap: () => onSelectCategory(category),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
    );
  }
}

class _InlineSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ProductProvider products;

  const _InlineSearchField({
    required this.controller,
    required this.products,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: products.setSearchQuery,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      hintText: 'Tìm cà chua, dưa lưới, Đà Lạt, VietGAP...',
      hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
      prefixIcon: const Icon(
        Icons.search_rounded,
        color: AppColors.primary,
        size: 19,
      ),
      suffixIcon: products.searchQuery.isNotEmpty
          ? IconButton(
              iconSize: 18,
              onPressed: () {
                controller.clear();
                products.setSearchQuery('');
              },
              icon: const Icon(Icons.close_rounded),
            )
          : null,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF6F7F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    ),
  );
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryDark : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    ),
  );
}

class _HeroSection extends StatelessWidget {
  final int productCount;
  final int farmCount;
  final VoidCallback onShopNow;
  final VoidCallback onScan;

  const _HeroSection({
    required this.productCount,
    required this.farmCount,
    required this.onShopNow,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 840;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF113624), Color(0xFF1D5B3A), Color(0xFF287249)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x281B5E20),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: isWide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(38, 34, 24, 34),
                      child: _heroContent(),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/hero_freshfarm.jpg',
                          fit: BoxFit.cover,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF1E5D3B),
                                Color(0x551E5D3B),
                                Color(0x001E5D3B),
                              ],
                              stops: [0.0, 0.28, 0.72],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 18,
                          bottom: 18,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.94),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x24000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Kiểm định dư lượng 0.00 mg/kg',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Giao xe lạnh giữ nhiệt 18°C',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.22,
                    child: Image.asset(
                      'assets/images/hero_freshfarm.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF113624).withOpacity(0.95),
                          const Color(0xFF1D5B3A).withOpacity(0.84),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                  child: _heroContent(),
                ),
              ],
            ),
    );
  }

  Widget _heroContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Text(
          'VIETGAP • GLOBALGAP • OCOP 4 SAO',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Nông sản tươi sạch\ntừ nông trại đến bàn ăn',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          height: 1.12,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Thu hoạch đúng vụ từ các hợp tác xã uy tín, bảo quản lạnh xuyên suốt và minh bạch hành trình từng lô hàng qua mã QR động.',
        style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
      ),
      const SizedBox(height: 22),
      Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          ElevatedButton.icon(
            onPressed: onShopNow,
            icon: const Icon(Icons.shopping_bag_rounded, size: 18),
            label: const Text('Mua sắm ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black87,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: const Text('Quét QR nguồn gốc'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.1),
              side: const BorderSide(color: Colors.white38),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Wrap(
        spacing: 22,
        runSpacing: 10,
        children: [
          _heroStat('$productCount+', 'Nông sản sạch'),
          _heroStat('$farmCount vùng', 'Trang trại chuẩn GAP'),
          _heroStat('< 1.5s', 'Truy xuất QR động'),
        ],
      ),
    ],
  );

  Widget _heroStat(String value, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    final items = const [
      (
        icon: Icons.verified_user_rounded,
        title: 'Chuẩn VietGAP & GlobalGAP',
        subtitle: 'Kiểm định dư lượng BVTV 0.00 mg/kg',
        tint: Color(0xFFE7F4EA),
        color: AppColors.primary,
      ),
      (
        icon: Icons.ac_unit_rounded,
        title: 'Xe lạnh bảo quản 18°C',
        subtitle: 'Giao nhanh trong ngày giữ độ tươi giòn',
        tint: Color(0xFFE4F2FA),
        color: AppColors.info,
      ),
      (
        icon: Icons.local_shipping_rounded,
        title: 'Freeship từ 300.000đ',
        subtitle: 'Giảm thêm 30.000đ cho đơn từ 400.000đ',
        tint: Color(0xFFFFF4DC),
        color: Color(0xFFD97706),
      ),
      (
        icon: Icons.qr_code_2_rounded,
        title: 'Truy xuất lô hàng 5 bước',
        subtitle: 'Xem nông trại & ngày thu hoạch tức thì',
        tint: Color(0xFFEDE8F8),
        color: Color(0xFF5E35B1),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth >= 960
              ? 4
              : constraints.maxWidth >= 560
              ? 2
              : 1;
          const gap = 12.0;
          final itemWidth = (constraints.maxWidth - (gap * (cols - 1))) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: items.map((item) {
              return SizedBox(
                width: itemWidth,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.softBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: item.tint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (action != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: Text(
              action!,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
            label: const Icon(Icons.arrow_forward_rounded, size: 15),
          ),
      ],
    ),
  );
}

class _CategoryShowcase extends StatelessWidget {
  final ProductProvider products;
  final ValueChanged<String> onSelectCategory;
  final VoidCallback onSelectGapSpecial;

  const _CategoryShowcase({
    required this.products,
    required this.onSelectCategory,
    required this.onSelectGapSpecial,
  });

  @override
  Widget build(BuildContext context) {
    final allCount = products.products.length;
    final vegCount = products.products
        .where((p) => p.category == 'Rau củ hữu cơ')
        .length;
    final fruitCount = products.products
        .where((p) => p.category == 'Trái cây sạch')
        .length;
    final featuredCount = products.featuredProducts.length;

    final cards = [
      (
        title: 'Tất cả nông sản',
        subtitle: '$allCount sản phẩm thu hoạch mới',
        icon: Icons.grid_view_rounded,
        tint: const Color(0xFFE7F3EA),
        selected: products.selectedCategory == 'Tất cả',
        onTap: () => onSelectCategory('Tất cả'),
      ),
      (
        title: 'Rau củ hữu cơ',
        subtitle: '$vegCount mặt hàng Đà Lạt & Bến Tre',
        icon: Icons.eco_rounded,
        tint: const Color(0xFFEAF7EE),
        selected: products.selectedCategory == 'Rau củ hữu cơ',
        onTap: () => onSelectCategory('Rau củ hữu cơ'),
      ),
      (
        title: 'Trái cây sạch',
        subtitle: '$fruitCount đặc sản miền Tây & Tây Bắc',
        icon: Icons.local_florist_rounded,
        tint: const Color(0xFFFFF4DC),
        selected: products.selectedCategory == 'Trái cây sạch',
        onTap: () => onSelectCategory('Trái cây sạch'),
      ),
      (
        title: 'Đánh giá 4.8★+',
        subtitle: '$featuredCount nông sản nổi bật chuẩn GAP',
        icon: Icons.workspace_premium_rounded,
        tint: const Color(0xFFE8F1FB),
        selected: products.sortOption == ProductSortOption.ratingDesc &&
            products.selectedCategory == 'Tất cả',
        onTap: onSelectGapSpecial,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            eyebrow: 'KHÁM PHÁ TƯƠI NGON',
            title: 'Mua theo danh mục',
            action: 'Xem tất cả',
            onAction: () => onSelectCategory('Tất cả'),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 900 ? 4 : 2;
              const gap = 12.0;
              final itemWidth = (constraints.maxWidth - (gap * (cols - 1))) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: cards.map((card) {
                  return SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      onTap: card.onTap,
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: card.selected
                              ? AppColors.primaryDark
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: card.selected
                                ? AppColors.primaryDark
                                : AppColors.softBorder,
                          ),
                          boxShadow: card.selected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x221B5E20),
                                    blurRadius: 14,
                                    offset: Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: card.selected
                                    ? Colors.white.withOpacity(0.16)
                                    : card.tint,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                card.icon,
                                color: card.selected
                                    ? AppColors.accent
                                    : AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: card.selected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    card.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: card.selected
                                          ? Colors.white70
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeaturedSection extends StatelessWidget {
  final ProductProvider products;
  final VoidCallback onSeeAll;

  const _FeaturedSection({required this.products, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final items = products.featuredProducts.isEmpty
        ? products.products.take(4).toList()
        : products.featuredProducts.take(4).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            eyebrow: 'TUYỂN CHỌN TRONG TUẦN',
            title: 'Nông sản nổi bật',
            action: 'Khám phá thêm',
            onAction: onSeeAll,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                const gap = 16.0;
                final cardWidth = (constraints.maxWidth - (gap * 3)) / 4;
                final cardHeight = (cardWidth / 1.18) + 158;
                return Row(
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: ProductCard(product: items[i]),
                      ),
                      if (i < items.length - 1) const SizedBox(width: gap),
                    ],
                  ],
                );
              }

              return SizedBox(
                height: 368,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) => SizedBox(
                    width: 244,
                    child: ProductCard(product: items[index]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TraceabilityShowcaseBanner extends StatelessWidget {
  final TraceabilityProvider traceProvider;
  final VoidCallback onOpenScanner;
  final ValueChanged<String> onOpenBatch;

  const _TraceabilityShowcaseBanner({
    required this.traceProvider,
    required this.onOpenScanner,
    required this.onOpenBatch,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 820;
    final sampleBatches = traceProvider.batches.take(3).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: EdgeInsets.all(isWide ? 24 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E6), Color(0xFFFFF1CF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3DCA2)),
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(
                  flex: 6,
                  child: _content(sampleBatches),
                ),
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  onPressed: onOpenScanner,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
                  label: const Text('Mở Camera Quét QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _content(sampleBatches),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onOpenScanner,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text('Mở Camera Quét QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _content(List sampleBatches) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: Colors.black87,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mỗi sản phẩm là một câu chuyện minh bạch',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Chạm vào mã lô mẫu bên dưới hoặc quét tem QR để xem đầy đủ 5 bước từ nông trại tới bàn ăn.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      if (sampleBatches.isNotEmpty) ...[
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sampleBatches.map<Widget>((b) {
            return InkWell(
              onTap: () => onOpenBatch(b.id),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7C97E)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timeline_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${b.id} • ${b.certType}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ],
  );
}

class _CatalogToolbar extends StatelessWidget {
  final ProductProvider products;
  final List<FarmModel> farms;
  final TextEditingController searchController;

  const _CatalogToolbar({
    required this.products,
    required this.farms,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final activeFarm = products.selectedFarmId == null
        ? null
        : farms.where((f) => f.id == products.selectedFarmId).firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GIAN HÀNG TRỰC TUYẾN',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tất cả nông sản',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.softBorder),
                ),
                child: Text(
                  '${products.filteredProducts.length} / ${products.products.length} sản phẩm',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...products.certifications.map((cert) {
                final selected = cert == products.selectedCertification;
                return ChoiceChip(
                  label: Text(cert),
                  selected: selected,
                  onSelected: (_) => products.setCertification(cert),
                  selectedColor: AppColors.accent,
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                  avatar: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.black87,
                        )
                      : null,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.black87 : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.accent : AppColors.softBorder,
                  ),
                );
              }),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.softBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ProductSortOption>(
                    value: products.sortOption,
                    icon: const Icon(Icons.sort_rounded, size: 17),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    items: ProductSortOption.values
                        .map(
                          (opt) => DropdownMenuItem(
                            value: opt,
                            child: Text(opt.label),
                          ),
                        )
                        .toList(),
                    onChanged: (opt) {
                      if (opt != null) products.setSortOption(opt);
                    },
                  ),
                ),
              ),
              if (activeFarm != null)
                InputChip(
                  label: Text(
                    'Nông trại: ${activeFarm.province}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  backgroundColor: AppColors.surfaceVariant,
                  deleteIconColor: AppColors.primaryDark,
                  onDeleted: () => products.setFarmFilter(null),
                ),
              if (products.hasActiveFilters)
                TextButton.icon(
                  onPressed: () {
                    searchController.clear();
                    products.resetFilters();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'Đặt lại bộ lọc',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatalogGridSection extends StatelessWidget {
  final ProductProvider products;
  const _CatalogGridSection({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final list = products.filteredProducts;
    if (list.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 32),
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.softBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Không tìm thấy nông sản phù hợp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thử thay đổi từ khóa tìm kiếm hoặc bỏ bớt tiêu chuẩn lọc để xem toàn bộ gian hàng.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: products.resetFilters,
              child: const Text('Hiển thị tất cả sản phẩm'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final columns = w >= 1080
              ? 4
              : w >= 740
              ? 3
              : w >= 420
              ? 2
              : 1;
          const gap = 16.0;
          final cardWidth = (w - (gap * (columns - 1))) / columns;
          final extraBody = w < 520 ? 168.0 : 158.0;
          final mainAxisExtent = (cardWidth / 1.18) + extraBody;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              mainAxisExtent: mainAxisExtent,
            ),
            itemBuilder: (context, index) => ProductCard(product: list[index]),
          );
        },
      ),
    );
  }
}

class _PartnerFarmsSection extends StatelessWidget {
  final List<FarmModel> farms;
  final String? selectedFarmId;
  final ValueChanged<String> onSelectFarm;

  const _PartnerFarmsSection({
    required this.farms,
    required this.selectedFarmId,
    required this.onSelectFarm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            eyebrow: 'NGUỒN GỐC ĐƯỢC CHỨNG NHẬN',
            title: 'Vùng trồng & Nông hộ đối tác',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 980
                  ? 4
                  : constraints.maxWidth >= 600
                  ? 2
                  : 1;
              const gap = 14.0;
              final itemWidth = (constraints.maxWidth - (gap * (cols - 1))) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: farms.map((farm) {
                  final selected = selectedFarmId == farm.id;
                  return SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      onTap: () => onSelectFarm(farm.id),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.softBorder,
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    farm.province,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${farm.areaHectares} ha',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              farm.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Chủ hộ: ${farm.ownerName}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chứng nhận: ${farm.vietGapCertNo}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  selected
                                      ? 'Đang lọc theo nông trại'
                                      : 'Xem sản phẩm vùng này',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? AppColors.primaryDark
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CustomerFlowSection extends StatelessWidget {
  final VoidCallback onShop;
  final VoidCallback onScan;
  final VoidCallback onOrders;

  const _CustomerFlowSection({
    required this.onShop,
    required this.onScan,
    required this.onOrders,
  });

  @override
  Widget build(BuildContext context) {
    final steps = const [
      (
        num: '01',
        title: 'Chọn nông sản & Lọc chuẩn',
        desc: 'Tìm kiếm theo tên, vùng trồng hoặc lọc chuẩn VietGAP / GlobalGAP / OCOP.',
        icon: Icons.manage_search_rounded,
      ),
      (
        num: '02',
        title: 'Quét QR kiểm tra lô hàng',
        desc: 'Xem nhật ký 5 bước từ gieo hạt, kiểm nghiệm BVTV đến thu hoạch.',
        icon: Icons.qr_code_scanner_rounded,
      ),
      (
        num: '03',
        title: 'Đặt hàng & VietQR / COD',
        desc: 'Freeship từ 300k, giảm 30k từ 400k, thanh toán chuyển khoản VietQR tức thì.',
        icon: Icons.payments_rounded,
      ),
      (
        num: '04',
        title: 'Theo dõi bản đồ & Chat NCC',
        desc: 'Theo dõi lộ trình giao hàng xe lạnh trực quan và trao đổi trực tiếp nhà cung cấp.',
        icon: Icons.local_shipping_rounded,
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 36),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRẢI NGHIỆM KHÁCH HÀNG',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Luồng mua hàng minh bạch 4 bước',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: onScan,
                    child: const Text('Thử quét QR'),
                  ),
                  ElevatedButton(
                    onPressed: onOrders,
                    child: const Text('Đơn hàng của tôi'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 960
                  ? 4
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1;
              const gap = 14.0;
              final itemWidth = (constraints.maxWidth - (gap * (cols - 1))) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: steps.map((s) {
                  return SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      onTap: s.num == '02'
                          ? onScan
                          : s.num == '04'
                          ? onOrders
                          : onShop,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.softBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    s.icon,
                                    color: AppColors.primaryDark,
                                    size: 20,
                                  ),
                                ),
                                Text(
                                  s.num,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFD2DBD0),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              s.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.desc,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StoreFooter extends StatelessWidget {
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenCart;

  const _StoreFooter({
    required this.onOpenOrders,
    required this.onOpenScanner,
    required this.onOpenCart,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      width: double.infinity,
      color: const Color(0xFF133A27),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: _CenteredSection(
        width: width,
        child: Wrap(
          spacing: 32,
          runSpacing: 20,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco_rounded, color: AppColors.accent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'freshfarm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Hệ thống TMĐT Nông sản sạch & Truy xuất QR động • Nhóm 6 VKU',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              children: [
                TextButton(
                  onPressed: onOpenScanner,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Quét QR'),
                ),
                TextButton(
                  onPressed: onOpenCart,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Giỏ hàng'),
                ),
                TextButton(
                  onPressed: onOpenOrders,
                  style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                  child: const Text('Đơn hàng của tôi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingMiniCartBar extends StatelessWidget {
  final CartProvider cart;
  final VoidCallback onOpenCart;

  const _FloatingMiniCartBar({
    required this.cart,
    required this.onOpenCart,
  });

  @override
  Widget build(BuildContext context) {
    final missingForFreeShip = (300000 - cart.subtotal).clamp(0, 300000);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.softBorder)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cart.itemCount} sản phẩm • Tạm tính ${CurrencyFormatter.format(cart.subtotal)}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          missingForFreeShip == 0
                              ? 'Đủ điều kiện MIỄN PHÍ VẬN CHUYỂN!'
                              : 'Mua thêm ${CurrencyFormatter.format(missingForFreeShip)} để được Freeship',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: missingForFreeShip == 0
                                ? AppColors.primary
                                : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: onOpenCart,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                    label: const Text('Xem giỏ & Đặt hàng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
