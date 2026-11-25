import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/traceability_provider.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/product_detail_screen.dart';
import '../screens/customer/traceability_screen.dart';
import 'freshfarm_image.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  int get _discountPercent {
    final original = widget.product.originalPrice;
    if (original == null || original <= widget.product.price) return 0;
    return (((original - widget.product.price) / original) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final qtyInCart = context.select<CartProvider, int>((cart) {
      for (final item in cart.items) {
        if (item.product.id == p.id) return item.quantity;
      }
      return 0;
    });
    final isOutOfStock = p.stockQuantity <= 0;
    final isLowStock = p.stockQuantity > 0 && p.stockQuantity < 45;
    final discount = _discountPercent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? AppColors.primary.withOpacity(0.45)
                : AppColors.softBorder,
            width: _hovered ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0x181B5E20)
                  : const Color(0x0A000000),
              blurRadius: _hovered ? 20 : 10,
              offset: Offset(0, _hovered ? 8 : 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: p),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.18,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: FreshFarmImage(
                          imageUrl: p.imageUrl,
                          productId: p.id,
                          fit: BoxFit.cover,
                          fallbackIconSize: 44,
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.08),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.28),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Top-left certification badge
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _certColor(p.certification),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x28000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 11,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                p.certification,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Top-right discount or out-of-stock badge
                      if (isOutOfStock)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _pillTag('Tạm hết', const Color(0xFFD32F2F)),
                        )
                      else if (discount > 0)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _pillTag('-$discount%', const Color(0xFFE65100)),
                        ),
                      // Bottom-left quick QR traceability pill
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: InkWell(
                          onTap: () => _openTraceability(context, p.batchId),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.qr_code_2_rounded,
                                  color: AppColors.primaryDark,
                                  size: 13,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'QR Lô',
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Bottom-right rating pill
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.68),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${p.rating} (${p.reviewCount})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.region.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (isLowStock)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  'Còn ${p.stockQuantity}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.agriculture_rounded,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                p.farmName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(p.price),
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      if (p.originalPrice != null &&
                                          p.originalPrice! > p.price)
                                        Text(
                                          CurrencyFormatter.format(
                                            p.originalPrice!,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    '/ ${p.unit}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildCartAction(context, p, qtyInCart, isOutOfStock),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartAction(
    BuildContext context,
    ProductModel p,
    int qtyInCart,
    bool isOutOfStock,
  ) {
    final cart = context.read<CartProvider>();
    if (isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Hết hàng',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    if (qtyInCart > 0) {
      return Container(
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepButton(
              icon: Icons.remove_rounded,
              onTap: () => cart.updateQuantity(p.id, qtyInCart - 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                '$qtyInCart',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            _stepButton(
              icon: Icons.add_rounded,
              onTap: qtyInCart < p.stockQuantity
                  ? () => cart.updateQuantity(p.id, qtyInCart + 1)
                  : null,
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        cart.addToCart(p);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Đã thêm ${p.name} vào giỏ hàng'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.primaryDark,
              action: SnackBarAction(
                label: 'Xem giỏ',
                textColor: AppColors.accent,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
            ),
          );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x282E7D32),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 15),
            SizedBox(width: 4),
            Text(
              'Thêm',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepButton({required IconData icon, VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 26,
      height: 32,
      child: Icon(
        icon,
        size: 15,
        color: onTap != null ? AppColors.primaryDark : AppColors.textMuted,
      ),
    ),
  );

  Widget _pillTag(String label, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Future<void> _openTraceability(BuildContext context, String batchId) async {
    final trace = context.read<TraceabilityProvider>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final batch = await trace.findBatch(batchId);
    if (!context.mounted) return;
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

  Color _certColor(String cert) {
    if (cert.contains('GlobalGAP')) return AppColors.globalGap;
    if (cert.contains('Organic')) return AppColors.organic;
    if (cert.contains('OCOP')) return AppColors.accent;
    return AppColors.vietGap;
  }
}
