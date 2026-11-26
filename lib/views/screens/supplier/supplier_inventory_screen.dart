import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../widgets/role_selector_bar.dart';
import '../../widgets/status_badge.dart';

class SupplierInventoryScreen extends StatefulWidget {
  const SupplierInventoryScreen({super.key});

  @override
  State<SupplierInventoryScreen> createState() => _SupplierInventoryScreenState();
}

class _SupplierInventoryScreenState extends State<SupplierInventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _inventorySearchQuery = '';
  OrderStatus? _selectedOrderStatusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prodProv = Provider.of<ProductProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);

    final activeOrders = orderProv.orders
        .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho Hàng & Phân Phối (NCC)'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              text: 'Tồn kho (${prodProv.products.length})',
            ),
            Tab(
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              text: 'Điều phối xuất kho (${activeOrders.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Role selector bar
          const RoleSelectorBar(),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: INVENTORY MANAGEMENT & RESTOCKING
                _buildInventoryTab(prodProv),

                // TAB 2: DISPATCH ORDERS WITH LOGISTICS & COLD STORAGE
                _buildDispatchTab(orderProv),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: INVENTORY MANAGEMENT
  // ==========================================
  Widget _buildInventoryTab(ProductProvider prodProv) {
    final filtered = prodProv.products.where((p) {
      if (_inventorySearchQuery.isEmpty) return true;
      final q = _inventorySearchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.batchId.toLowerCase().contains(q) ||
          p.farmName.toLowerCase().contains(q);
    }).toList();

    final lowStockCount = prodProv.products.where((p) => p.stockQuantity < 45).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storage Facility Status Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.ac_unit, color: Color(0xFF0288D1), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Kho lạnh Trung tâm Đà Nẵng (VKU Logistics)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F5FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Chuẩn 18°C',
                        style: TextStyle(color: Color(0xFF0288D1), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _statItem('Tổng loại hàng', '${prodProv.products.length}', AppColors.primary),
                    ),
                    Expanded(
                      child: _statItem('Cảnh báo tồn kho ít', '$lowStockCount mặt hàng',
                          lowStockCount > 0 ? AppColors.warning : AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Search Box
          TextField(
            onChanged: (val) => setState(() => _inventorySearchQuery = val),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên nông sản, mã lô hàng, nông trại...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),

          const SizedBox(height: 12),

          // Inventory List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final p = filtered[index];
              final isLowStock = p.stockQuantity < 45;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isLowStock ? AppColors.warning : AppColors.border,
                    width: isLowStock ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          p.imageUrl,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 55,
                            height: 55,
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.eco, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Lô: ${p.batchId} • ${p.farmName}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Tồn kho: ',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                Text(
                                  '${p.stockQuantity} ${p.unit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isLowStock ? AppColors.warning : AppColors.success,
                                  ),
                                ),
                                if (isLowStock) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Sắp hết',
                                      style: TextStyle(fontSize: 9.5, color: AppColors.warning, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Quick Restock Button
                      IconButton(
                        tooltip: 'Nhập thêm hàng',
                        icon: const Icon(Icons.add_box_outlined, color: AppColors.primary),
                        onPressed: () => _showRestockDialog(context, prodProv, p),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: DISPATCH ORDERS
  // ==========================================
  Widget _buildDispatchTab(OrderProvider orderProv) {
    final filteredOrders = orderProv.orders.where((o) {
      if (_selectedOrderStatusFilter == null) return true;
      return o.status == _selectedOrderStatusFilter;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips for Orders
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _selectedOrderStatusFilter == null,
                  onSelected: (_) => setState(() => _selectedOrderStatusFilter = null),
                ),
                const SizedBox(width: 6),
                ...OrderStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(status.displayName),
                      selected: _selectedOrderStatusFilter == status,
                      onSelected: (sel) => setState(() => _selectedOrderStatusFilter = sel ? status : null),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              final nextState = order.status.nextState;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.id,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13),
                          ),
                          StatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Khách: ${order.userName} (${order.userPhone})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Đ/C: ${order.shippingAddress}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${order.items.length} món • Tổng: ${CurrencyFormatter.format(order.finalAmount)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 16, color: AppColors.divider),
                      // State Machine Advancement Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đối tác: ${order.deliveryPartner}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                Text(
                                  'Mã vận đơn: ${order.deliveryTrackingCode}',
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF0288D1), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          if (nextState != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                orderProv.advanceOrderStatus(order.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đơn ${order.id} chuyển sang: ${nextState.displayName}'),
                                    backgroundColor: AppColors.primary,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward, size: 14),
                              label: Text(
                                'Duyệt: ${nextState.displayName}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            )
                          else
                            const Text(
                              'Đơn đã hoàn tất',
                              style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showRestockDialog(BuildContext context, ProductProvider prodProv, ProductModel product) {
    final qtyCtrl = TextEditingController(text: '50');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nhập kho thêm ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số lượng tồn hiện tại: ${product.stockQuantity} ${product.unit}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số lượng nhập thêm (${product.unit})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final added = int.tryParse(qtyCtrl.text) ?? 0;
              if (added > 0) {
                final updated = product.copyWith(stockQuantity: product.stockQuantity + added);
                prodProv.updateProduct(updated);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã nhập thêm $added ${product.unit} cho ${product.name}!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Xác nhận nhập kho'),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
