import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/product_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../widgets/product_card.dart';
import 'cart_screen.dart';
import 'qr_scanner_screen.dart';
import 'order_history_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1200
        ? 4
        : width >= 760
        ? 3
        : 2;
    final cardWidth = (width - 40 - ((columns - 1) * 16)) / columns;
    final cardAspectRatio = cardWidth / (cardWidth / 1.15 + 170);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),
      appBar: _buildAppBar(context, cart),
      drawer: _buildDrawer(context, auth),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: products.loadProducts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _StoreNavigation(products: products)),
            SliverToBoxAdapter(
              child: _HeroSection(onScan: () => _openScanner(context)),
            ),
            SliverToBoxAdapter(child: _TrustStrip()),
            SliverToBoxAdapter(
              child: _SectionHeading(
                eyebrow: 'KHÁM PHÁ TƯƠI NGON',
                title: 'Mua theo danh mục',
                action: 'Xem tất cả',
                onAction: () => products.setCategory('Tất cả'),
              ),
            ),
            SliverToBoxAdapter(child: _CategoryRail(products: products)),
            SliverToBoxAdapter(
              child: _SectionHeading(
                eyebrow: 'GỢI Ý CHO BẠN',
                title: 'Nông sản nổi bật',
                action: 'Xem tất cả',
                onAction: () => products.setCategory('Tất cả'),
              ),
            ),
            SliverToBoxAdapter(child: _FeaturedRail(products: products)),
            SliverToBoxAdapter(
              child: _PromoBar(onScan: () => _openScanner(context)),
            ),
            SliverToBoxAdapter(child: _ShopToolbar(products: products)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: products.isLoading
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  : SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ProductCard(
                          product: products.filteredProducts[index],
                        ),
                        childCount: products.filteredProducts.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: cardAspectRatio,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, CartProvider cart) =>
      AppBar(
        backgroundColor: const Color(0xFFF7F8F4),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 76,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: const Row(
          children: [
            Icon(Icons.eco_rounded, color: AppColors.accent, size: 28),
            SizedBox(width: 8),
            Text(
              'freshfarm',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Quét mã QR',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => _openScanner(context),
          ),
          Stack(
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
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      );

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.eco_rounded,
                    color: AppColors.accent,
                    size: 32,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    user?.name ?? 'Khách hàng',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Tài khoản khách hàng',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Đơn hàng của tôi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Truy xuất nguồn gốc'),
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
              title: const Text('Giỏ hàng'),
              onTap: () {
                Navigator.pop(context);
                _openCart(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.switch_account_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Đổi tài khoản demo'),
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
                'FRESHFARM • NÔNG SẢN MINH BẠCH',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: .6,
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
  void _openScanner(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
  );

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
                'Chọn không gian làm việc',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...UserRole.values.map(
                (role) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _roleIcon(role),
                    color: role == auth.activeRole
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    role.displayName,
                    style: TextStyle(
                      fontWeight: role == auth.activeRole
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
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
}

class _StoreNavigation extends StatelessWidget {
  final ProductProvider products;
  const _StoreNavigation({required this.products});

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE6EAE2)),
    ),
    child: Row(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Icon(Icons.storefront_rounded, color: AppColors.primary),
        ),
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _NavItem(
                label: 'Trang chủ',
                selected: true,
                onTap: () => products.setCategory('Tất cả'),
              ),
              ...products.categories
                  .skip(1)
                  .map(
                    (category) => _NavItem(
                      label: category,
                      onTap: () => products.setCategory(category),
                    ),
                  ),
            ],
          ),
        ),
        Container(width: 1, height: 24, color: const Color(0xFFE5E8E2)),
        IconButton(
          tooltip: 'Tìm kiếm sản phẩm',
          onPressed: () => Scrollable.ensureVisible(context),
          icon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
    borderRadius: BorderRadius.circular(12),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE8F4E9) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    ),
  );
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onScan;
  const _HeroSection({required this.onScan});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
    child: Container(
      constraints: const BoxConstraints(minHeight: 265, maxHeight: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF143F2C), Color(0xFF26734D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x302E7D32),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (MediaQuery.sizeOf(context).width >= 700)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: MediaQuery.sizeOf(context).width * .34,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(28),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0x00143F2C), Color(0xCC143F2C)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            right: -24,
            bottom: -58,
            child: Icon(
              Icons.eco_rounded,
              size: 250,
              color: Colors.white.withOpacity(.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'TƯƠI MỖI NGÀY  •  GIAO TẬN NHÀ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Bữa ăn lành mạnh\nbắt đầu từ hôm nay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Nông sản chọn lọc từ những vùng trồng đáng tin cậy, minh bạch từng hành trình.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text('Quét để biết nguồn gốc'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white54),
                    backgroundColor: Colors.white12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PromoBar extends StatelessWidget {
  final VoidCallback onScan;
  const _PromoBar({required this.onScan});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 28, 20, 4),
    padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4D9),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF5DFAB)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mỗi sản phẩm là một câu chuyện',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              SizedBox(height: 3),
              Text(
                'Quét QR để xem nông trại, lô trồng và hành trình thu hoạch.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onScan,
          child: const Text(
            'Khám phá',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _TrustStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    child: Row(
      children: const [
        _TrustItem(
          icon: Icons.verified_rounded,
          title: 'Chuẩn kiểm định',
          subtitle: 'VietGAP & Organic',
        ),
        _TrustItem(
          icon: Icons.local_shipping_outlined,
          title: 'Giao nhanh trong ngày',
          subtitle: 'Đóng gói cẩn thận',
        ),
        _TrustItem(
          icon: Icons.favorite_border_rounded,
          title: 'Tươi ngon mỗi ngày',
          subtitle: 'Đổi trả dễ dàng',
        ),
      ],
    ),
  );
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _TrustItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 23),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow, title, action;
  final VoidCallback onAction;
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.action,
    required this.onAction,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
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
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            action,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

class _CategoryRail extends StatelessWidget {
  final ProductProvider products;
  const _CategoryRail({required this.products});
  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.grid_view_rounded,
      Icons.eco_outlined,
      Icons.apple_rounded,
      Icons.spa_outlined,
      Icons.local_florist_outlined,
    ];
    return SizedBox(
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: products.categories.length,
        itemBuilder: (context, index) {
          final cat = products.categories[index];
          final selected = cat == products.selectedCategory;
          return GestureDetector(
            onTap: () => products.setCategory(cat),
            child: Container(
              width: 82,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFE7EAE4),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(.18),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[index % icons.length],
                    color: selected ? Colors.white : AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedRail extends StatelessWidget {
  final ProductProvider products;
  const _FeaturedRail({required this.products});
  @override
  Widget build(BuildContext context) {
    final items = products.featuredProducts.isEmpty
        ? products.filteredProducts.take(4).toList()
        : products.featuredProducts.take(4).toList();
    return SizedBox(
      height: 405,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (context, index) => SizedBox(
          width: 260,
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ProductCard(product: items[index]),
          ),
        ),
      ),
    );
  }
}

class _ShopToolbar extends StatelessWidget {
  final ProductProvider products;
  const _ShopToolbar({required this.products});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
    child: Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tất cả nông sản',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${products.filteredProducts.length} sản phẩm',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: products.setSearchQuery,
          decoration: InputDecoration(
            hintText: 'Tìm rau củ, trái cây, vùng trồng...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
            ),
            suffixIcon: products.searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () => products.setSearchQuery(''),
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.certifications.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cert = products.certifications[index];
              final selected = cert == products.selectedCertification;
              return ChoiceChip(
                label: Text(cert),
                selected: selected,
                onSelected: (_) => products.setCertification(cert),
                selectedColor: AppColors.accent,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  fontSize: 11,
                  color: selected ? Colors.black87 : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
                side: BorderSide(
                  color: selected ? AppColors.accent : const Color(0xFFE2E6DF),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
