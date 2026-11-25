import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/traceability_provider.dart';
import '../../widgets/freshfarm_image.dart';
import '../../widgets/product_card.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'traceability_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  int get _discountPercent {
    final original = widget.product.originalPrice;
    if (original == null || original <= widget.product.price) return 0;
    return (((original - widget.product.price) / original) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final prodProv = context.watch<ProductProvider>();
    final trace = context.read<TraceabilityProvider>();
    final p = widget.product;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 860;
    final related = prodProv.products
        .where((item) => item.id != p.id && item.category == p.category)
        .take(4)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.softBorder),
        ),
        title: Text(
          p.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Giỏ hàng',
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 7,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: isWide ? null : _buildMobileBottomBar(context, p),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 24 : 16,
          vertical: isWide ? 24 : 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildHeroImage(p, height: 420),
                            const SizedBox(height: 16),
                            _buildTraceabilityCard(context, trace, p),
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoCard(p),
                            const SizedBox(height: 16),
                            _buildWideActionPanel(context, p),
                            const SizedBox(height: 16),
                            _buildSpecsCard(p),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildHeroImage(p, height: 280),
                  const SizedBox(height: 16),
                  _buildInfoCard(p),
                  const SizedBox(height: 14),
                  _buildTraceabilityCard(context, trace, p),
                  const SizedBox(height: 14),
                  _buildSpecsCard(p),
                ],
                if (related.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Nông sản tương tự',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 820) {
                        const gap = 14.0;
                        final cols = related.length >= 4 ? 4 : related.length;
                        final cardWidth =
                            (constraints.maxWidth - (gap * (4 - 1))) / 4;
                        final cardHeight = (cardWidth / 1.18) + 158;
                        return Row(
                          children: [
                            for (int i = 0; i < cols; i++) ...[
                              SizedBox(
                                width: cardWidth,
                                height: cardHeight,
                                child: ProductCard(product: related[i]),
                              ),
                              if (i < cols - 1) const SizedBox(width: gap),
                            ],
                          ],
                        );
                      }
                      return SizedBox(
                        height: 360,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: related.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, idx) => SizedBox(
                            width: 230,
                            child: ProductCard(product: related[idx]),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(ProductModel p, {required double height}) {
    final discount = _discountPercent;
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FreshFarmImage(
            imageUrl: p.imageUrl,
            productId: p.id,
            fit: BoxFit.cover,
            fallbackIconSize: 72,
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.vietGap,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 8),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Colors.white, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    p.certification,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (discount > 0)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Giảm $discount%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ProductModel p) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.softBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                p.category,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${p.rating} (${p.reviewCount} đánh giá)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          p.name,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            height: 1.2,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              CurrencyFormatter.format(p.price),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
              ),
            ),
            Text(
              '/ ${p.unit}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (p.originalPrice != null && p.originalPrice! > p.price)
              Text(
                CurrencyFormatter.format(p.originalPrice!),
                style: const TextStyle(
                  fontSize: 15,
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.farmName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Vùng trồng: ${p.region}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Mô tả sản phẩm & Cam kết chất lượng',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          p.description,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),
      ],
    ),
  );

  Widget _buildTraceabilityCard(
    BuildContext context,
    TraceabilityProvider trace,
    ProductModel p,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primaryDark, AppColors.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Truy xuất nguồn gốc lô hàng',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mã lô: ${p.batchId}',
                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final nav = Navigator.of(context);
            final b = await trace.findBatch(p.batchId);
            if (!mounted) return;
            if (b != null) {
              nav.push(
                MaterialPageRoute(
                  builder: (_) => TraceabilityScreen(batch: b),
                ),
              );
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Không tìm thấy thông tin lô hàng'),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black87,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Xem chuỗi 5 bước',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );

  Widget _buildWideActionPanel(BuildContext context, ProductModel p) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.softBorder),
        ),
        child: Row(
          children: [
            _quantitySelector(p),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: p.stockQuantity <= 0
                    ? null
                    : () => _addToCart(context, p),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                label: const Text('Thêm vào giỏ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: p.stockQuantity <= 0
                    ? null
                    : () => _buyNow(context, p),
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: const Text('Mua ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildMobileBottomBar(BuildContext context, ProductModel p) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.softBorder)),
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              _quantitySelector(p),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: p.stockQuantity <= 0
                      ? null
                      : () => _addToCart(context, p),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Thêm giỏ'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: p.stockQuantity <= 0
                      ? null
                      : () => _buyNow(context, p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Mua ngay'),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _quantitySelector(ProductModel p) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.softBorder),
      borderRadius: BorderRadius.circular(12),
      color: AppColors.background,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_rounded, size: 17),
          onPressed: () {
            if (_quantity > 1) setState(() => _quantity--);
          },
        ),
        Text(
          '$_quantity',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        IconButton(
          icon: const Icon(Icons.add_rounded, size: 17),
          onPressed: () {
            if (_quantity < p.stockQuantity) setState(() => _quantity++);
          },
        ),
      ],
    ),
  );

  void _addToCart(BuildContext context, ProductModel p) {
    context.read<CartProvider>().addToCart(p, quantity: _quantity);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Đã thêm $_quantity ${p.unit} vào giỏ hàng!'),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Xem giỏ',
            textColor: AppColors.accent,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ),
      );
  }

  void _buyNow(BuildContext context, ProductModel p) {
    context.read<CartProvider>().addToCart(p, quantity: _quantity);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  Widget _buildSpecsCard(ProductModel p) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.softBorder),
    ),
    child: Column(
      children: [
        _specRow('Tiêu chuẩn chứng nhận', p.certification),
        const Divider(height: 16, color: AppColors.divider),
        _specRow('Tồn kho khả dụng', '${p.stockQuantity} ${p.unit}'),
        const Divider(height: 16, color: AppColors.divider),
        _specRow('Hạn sử dụng khuyến nghị', '7 - 10 ngày bảo quản lạnh'),
        const Divider(height: 16, color: AppColors.divider),
        _specRow('Chính sách kiểm hàng', 'Được kiểm tra trước khi nhận'),
      ],
    ),
  );

  Widget _specRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    ],
  );
}
