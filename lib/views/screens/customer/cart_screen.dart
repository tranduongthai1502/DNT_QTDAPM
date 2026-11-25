import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/cart_provider.dart';
import '../../widgets/freshfarm_image.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 860;

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
          'Giỏ hàng (${cart.itemCount})',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Xóa hết'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xác nhận'),
                    content: const Text(
                      'Bạn có chắc muốn xóa tất cả sản phẩm trong giỏ hàng?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          cart.clearCart();
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Xóa hết'),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyState(context)
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: isWide
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  _buildIncentiveBanner(cart),
                                  const SizedBox(height: 14),
                                  Expanded(child: _buildItemList(context, cart)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 4,
                              child: _buildSummaryCard(context, cart),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: _buildIncentiveBanner(cart),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: _buildItemList(context, cart),
                            ),
                          ),
                          _buildMobileSummary(context, cart),
                        ],
                      ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Giỏ hàng của bạn đang trống',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Khám phá các nông sản chuẩn VietGAP, GlobalGAP thu hoạch trong ngày và thêm vào giỏ nhé.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.storefront_rounded, size: 18),
            label: const Text('Quay lại mua sắm'),
          ),
        ],
      ),
    ),
  );

  Widget _buildIncentiveBanner(CartProvider cart) {
    final freeShipProgress = (cart.subtotal / 300000).clamp(0.0, 1.0);
    final reachedFreeShip = cart.subtotal >= 300000;
    final reachedBigDiscount = cart.subtotal >= 400000;

    String message;
    if (reachedBigDiscount) {
      message = 'Tuyệt vời! Bạn đã được MIỄN PHÍ SHIP và GIẢM 30.000đ đơn lớn.';
    } else if (reachedFreeShip) {
      message =
          'Đã MIỄN PHÍ SHIP! Mua thêm ${CurrencyFormatter.format(400000 - cart.subtotal)} để giảm thêm 30.000đ.';
    } else {
      message =
          'Mua thêm ${CurrencyFormatter.format(300000 - cart.subtotal)} để được MIỄN PHÍ VẬN CHUYỂN.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: reachedFreeShip ? AppColors.surfaceVariant : AppColors.warmCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reachedFreeShip
              ? AppColors.primary.withOpacity(0.25)
              : const Color(0xFFF3DCA2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                reachedFreeShip
                    ? Icons.check_circle_rounded
                    : Icons.local_shipping_outlined,
                size: 18,
                color: reachedFreeShip
                    ? AppColors.primaryDark
                    : const Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: reachedFreeShip
                        ? AppColors.primaryDark
                        : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: freeShipProgress,
              minHeight: 6,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(
                reachedFreeShip ? AppColors.primary : AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(BuildContext context, CartProvider cart) =>
      ListView.separated(
        itemCount: cart.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = cart.items[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.softBorder),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FreshFarmImage(
                    imageUrl: item.product.imageUrl,
                    productId: item.product.id,
                    width: 82,
                    height: 82,
                    fallbackIconSize: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () =>
                                cart.removeFromCart(item.product.id),
                          ),
                        ],
                      ),
                      Text(
                        '${item.product.farmName} • ${item.product.certification}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${CurrencyFormatter.format(item.product.price)} / ${item.product.unit}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  border: Border.all(
                                    color: AppColors.softBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                      ),
                                      iconSize: 15,
                                      icon: const Icon(Icons.remove_rounded),
                                      onPressed: () => cart.updateQuantity(
                                        item.product.id,
                                        item.quantity - 1,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                      ),
                                      iconSize: 15,
                                      icon: const Icon(Icons.add_rounded),
                                      onPressed: item.quantity <
                                              item.product.stockQuantity
                                          ? () => cart.updateQuantity(
                                              item.product.id,
                                              item.quantity + 1,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                CurrencyFormatter.format(item.totalPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildSummaryCard(BuildContext context, CartProvider cart) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.softBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tóm tắt đơn hàng',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            _summaryContent(context, cart),
          ],
        ),
      );

  Widget _buildMobileSummary(BuildContext context, CartProvider cart) =>
      Container(
        padding: const EdgeInsets.all(16),
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
        child: SafeArea(child: _summaryContent(context, cart)),
      );

  Widget _summaryContent(BuildContext context, CartProvider cart) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _row('Tạm tính (${cart.itemCount} sản phẩm):', CurrencyFormatter.format(cart.subtotal)),
      const SizedBox(height: 6),
      _row(
        'Phí vận chuyển lạnh:',
        cart.shippingFee == 0
            ? 'Miễn phí'
            : CurrencyFormatter.format(cart.shippingFee),
        valueColor: cart.shippingFee == 0 ? AppColors.primary : null,
      ),
      if (cart.discountAmount > 0) ...[
        const SizedBox(height: 6),
        _row(
          'Ưu đãi đơn lớn (≥ 400k):',
          '-${CurrencyFormatter.format(cart.discountAmount)}',
          valueColor: const Color(0xFFD97706),
        ),
      ],
      const Divider(height: 18, color: AppColors.divider),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tổng thanh toán:',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          Text(
            CurrencyFormatter.format(cart.totalAmount),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
            );
          },
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('Tiến hành đặt hàng'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    ],
  );

  Widget _row(String label, String value, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: valueColor ?? AppColors.textPrimary,
        ),
      ),
    ],
  );
}
