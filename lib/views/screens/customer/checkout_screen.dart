import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/vietqr_dialog.dart';
import 'order_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _noteController;

  PaymentMethod _selectedPayment = PaymentMethod.vietqr;
  String _selectedLogistics = 'AhaMove Xe Lạnh Chuẩn 18°C';

  final List<String> _logisticsOptions = [
    'AhaMove Xe Lạnh Chuẩn 18°C',
    'Giao Hàng Nhanh (FastCold)',
    'Viettel Post Nông Sản',
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    _nameController = TextEditingController(
      text: user?.name ?? 'Trần Dương Thái',
    );
    _phoneController = TextEditingController(text: user?.phone ?? '0905123456');
    _addressController = TextEditingController(
      text: user?.address ??
          '470 Đường Trần Đại Nghĩa, Q. Ngũ Hành Sơn, TP. Đà Nẵng',
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder({bool isPrepaid = false}) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final prodProv = Provider.of<ProductProvider>(context, listen: false);

    if (!_formKey.currentState!.validate()) return;

    final orderItems = cart.items.map((item) {
      prodProv.deductStock(item.product.id, item.quantity);
      return OrderItemModel(
        productId: item.product.id,
        productName: item.product.name,
        imageUrl: item.product.imageUrl,
        price: item.product.price,
        quantity: item.quantity,
        unit: item.product.unit,
      );
    }).toList();

    final order = await orderProv.createOrder(
      userId: auth.currentUser?.id ?? 'USR-001',
      userName: _nameController.text.trim(),
      userPhone: _phoneController.text.trim(),
      shippingAddress: _addressController.text.trim(),
      items: orderItems,
      totalAmount: cart.subtotal,
      shippingFee: cart.shippingFee,
      discountAmount: cart.discountAmount,
      finalAmount: cart.totalAmount,
      paymentMethod: _selectedPayment,
      isPaid: isPrepaid,
      deliveryPartner: _selectedLogistics,
    );

    cart.clearCart();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đặt hàng thành công! Mã đơn: ${order.id}'),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
      );
    }
  }

  void _handlePlaceOrder() {
    if (!_formKey.currentState!.validate()) return;
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (_selectedPayment == PaymentMethod.vietqr) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => VietQRDialog(
          orderId: 'DEMO-${DateTime.now().millisecondsSinceEpoch % 10000}',
          amount: cart.totalAmount,
          onPaymentConfirmed: () {
            _submitOrder(isPrepaid: true);
          },
        ),
      );
    } else {
      _submitOrder(isPrepaid: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 880;

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
        title: const Text(
          'Xác nhận đặt hàng & Thanh toán',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 24 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Form(
              key: _formKey,
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: _buildLeftForm()),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: _buildRightSummary(cart)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildLeftForm(),
                        const SizedBox(height: 16),
                        _buildRightSummary(cart),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftForm() => Column(
    children: [
      _sectionCard(
        icon: Icons.location_on_outlined,
        title: 'Thông tin người nhận & Địa chỉ giao hàng',
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên người nhận',
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại liên lạc',
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ nhận hàng chi tiết',
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú cho đơn hàng (không bắt buộc)',
                hintText: 'VD: Giao giờ hành chính, gọi trước khi đến...',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _sectionCard(
        icon: Icons.local_shipping_outlined,
        title: 'Đơn vị vận chuyển chuyên dụng',
        child: Column(
          children: _logisticsOptions.map((opt) {
            return RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: Text(
                opt,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: const Text(
                'Bảo quản thùng xốp giữ nhiệt lạnh 18°C - 22°C',
                style: TextStyle(fontSize: 11.5),
              ),
              value: opt,
              groupValue: _selectedLogistics,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _selectedLogistics = val!),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 16),
      _sectionCard(
        icon: Icons.payments_outlined,
        title: 'Phương thức thanh toán',
        child: Column(
          children: [
            RadioListTile<PaymentMethod>(
              contentPadding: EdgeInsets.zero,
              value: PaymentMethod.vietqr,
              groupValue: _selectedPayment,
              activeColor: AppColors.primary,
              title: const Row(
                children: [
                  Icon(Icons.qr_code_2, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chuyển khoản VietQR Napas 247 (Khuyên dùng)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: const Text(
                'Tự động sinh mã QR chuyển khoản MBBank đúng số tiền và nội dung đơn',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              onChanged: (val) => setState(() => _selectedPayment = val!),
            ),
            const Divider(height: 1, color: AppColors.divider),
            RadioListTile<PaymentMethod>(
              contentPadding: EdgeInsets.zero,
              value: PaymentMethod.cod,
              groupValue: _selectedPayment,
              activeColor: AppColors.primary,
              title: const Row(
                children: [
                  Icon(Icons.money, color: AppColors.accent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thanh toán khi nhận hàng (COD)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: const Text(
                'Kiểm tra hàng tươi ngon chuẩn VietGAP trước khi thanh toán cho shipper',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              onChanged: (val) => setState(() => _selectedPayment = val!),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildRightSummary(CartProvider cart) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.softBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(
          Icons.receipt_long_outlined,
          'Tóm tắt đơn hàng (${cart.itemCount} sản phẩm)',
        ),
        const SizedBox(height: 14),
        ...cart.items.map(
          (it) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${it.product.name} (x${it.quantity})',
                    style: const TextStyle(fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.format(it.totalPrice),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 20, color: AppColors.divider),
        _sumRow('Tổng tiền hàng:', CurrencyFormatter.format(cart.subtotal)),
        const SizedBox(height: 6),
        _sumRow(
          'Phí giao hàng lạnh:',
          cart.shippingFee == 0
              ? 'Miễn phí'
              : CurrencyFormatter.format(cart.shippingFee),
          color: cart.shippingFee == 0 ? AppColors.primary : null,
        ),
        if (cart.discountAmount > 0) ...[
          const SizedBox(height: 6),
          _sumRow(
            'Giảm giá ưu đãi:',
            '-${CurrencyFormatter.format(cart.discountAmount)}',
            color: const Color(0xFFD97706),
          ),
        ],
        const Divider(height: 20, color: AppColors.divider),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TỔNG THANH TOÁN:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: cart.items.isEmpty ? null : _handlePlaceOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _selectedPayment == PaymentMethod.vietqr
                  ? 'Mở mã VietQR (${CurrencyFormatter.format(cart.totalAmount)})'
                  : 'Đặt hàng COD (${CurrencyFormatter.format(cart.totalAmount)})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.softBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(icon, title),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _sumRow(String label, String value, {Color? color}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.textPrimary,
        ),
      ),
    ],
  );

  Widget _buildCardHeader(IconData icon, String title) => Row(
    children: [
      Icon(icon, size: 19, color: AppColors.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    ],
  );
}
