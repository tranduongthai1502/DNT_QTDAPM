import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../models/evm_metrics_model.dart';
import '../../../models/order_model.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../widgets/role_selector_bar.dart';
import '../../widgets/status_badge.dart';
import '../../../services/firebase_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EvmMetricsModel _evmMetrics = EvmMetricsModel.getDefaultMetrics();

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
    final orderProv = Provider.of<OrderProvider>(context);
    final prodProv = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Quản Trị Hệ Thống (Admin)'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(Icons.analytics_outlined, size: 18),
              text: 'Vận hành TMĐT',
            ),
            Tab(
              icon: Icon(Icons.assessment_outlined, size: 18),
              text: 'Quản trị dự án EVM',
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
                // TAB 1: E-COMMERCE OPERATIONS
                SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI Cards Grid
                      Row(
                        children: [
                          Expanded(
                            child: _kpiCard(
                              'Doanh thu thực tế',
                              CurrencyFormatter.format(orderProv.totalRevenue),
                              Icons.monetization_on,
                              AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _kpiCard(
                              'Đơn hoàn tất',
                              '${orderProv.completedOrderCount} đơn',
                              Icons.task_alt,
                              AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _kpiCard(
                              'Đang chờ xử lý',
                              '${orderProv.pendingOrderCount} đơn',
                              Icons.pending_actions,
                              AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _kpiCard(
                              'Sản phẩm niêm yết',
                              '${prodProv.products.length} mặt hàng',
                              Icons.eco,
                              AppColors.vietGap,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Firebase Cloud Status & Seed Button
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Đồng bộ dữ liệu Cloud Firestore',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: FirebaseService.isInitialized
                                        ? AppColors.surfaceVariant
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    FirebaseService.isInitialized
                                        ? 'Cloud Connected'
                                        : 'Offline Mode',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: FirebaseService.isInitialized
                                          ? AppColors.primaryDark
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Nạp sản phẩm, hình ảnh vào Firebase Storage; đồng thời lưu lô hàng, trang trại và đơn hàng vào Cloud Firestore.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final success =
                                      await FirebaseService.seedAllDataToFirestore();
                                  if (success) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đã nạp dữ liệu và hình ảnh lên Firebase thành công!',
                                        ),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  } else {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Chưa kết nối Firebase! Hãy chạy flutterfire configure để liên kết project.',
                                        ),
                                        backgroundColor: AppColors.warning,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.sync, size: 16),
                                label: const Text(
                                  'Nạp dữ liệu lên Cloud Firestore (Seed Data)',
                                ),
                                style: ElevatedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Chart Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phân bổ trạng thái đơn hàng',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 180,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 10,
                                  barTouchData: const BarTouchData(
                                    enabled: true,
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          switch (val.toInt()) {
                                            case 0:
                                              return const Text(
                                                'Chờ',
                                                style: TextStyle(fontSize: 10),
                                              );
                                            case 1:
                                              return const Text(
                                                'Duyệt',
                                                style: TextStyle(fontSize: 10),
                                              );
                                            case 2:
                                              return const Text(
                                                'Gói',
                                                style: TextStyle(fontSize: 10),
                                              );
                                            case 3:
                                              return const Text(
                                                'Giao',
                                                style: TextStyle(fontSize: 10),
                                              );
                                            case 4:
                                              return const Text(
                                                'Xong',
                                                style: TextStyle(fontSize: 10),
                                              );
                                            default:
                                              return const SizedBox();
                                          }
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: [
                                    _makeBarGroup(
                                      0,
                                      orderProv
                                          .getOrdersByStatus(
                                            OrderStatus.pending,
                                          )
                                          .length
                                          .toDouble(),
                                      Colors.amber,
                                    ),
                                    _makeBarGroup(
                                      1,
                                      orderProv
                                          .getOrdersByStatus(
                                            OrderStatus.confirmed,
                                          )
                                          .length
                                          .toDouble(),
                                      Colors.blue,
                                    ),
                                    _makeBarGroup(
                                      2,
                                      orderProv
                                          .getOrdersByStatus(
                                            OrderStatus.packing,
                                          )
                                          .length
                                          .toDouble(),
                                      Colors.purple,
                                    ),
                                    _makeBarGroup(
                                      3,
                                      orderProv
                                          .getOrdersByStatus(
                                            OrderStatus.shipping,
                                          )
                                          .length
                                          .toDouble(),
                                      Colors.cyan,
                                    ),
                                    _makeBarGroup(
                                      4,
                                      orderProv
                                          .getOrdersByStatus(
                                            OrderStatus.delivered,
                                          )
                                          .length
                                          .toDouble(),
                                      Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Recent Orders Management
                      const Text(
                        'Danh sách đơn hàng toàn hệ thống',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...orderProv.orders.map((order) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  order.id,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                StatusBadge(status: order.status),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('${order.userName} • ${order.userPhone}'),
                                Text(
                                  'Tổng: ${CurrencyFormatter.format(order.finalAmount)} (${order.paymentMethod == PaymentMethod.vietqr ? "VietQR" : "COD"})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // TAB 2: SPM & EVM METRICS (QUẢN TRỊ DỰ ÁN PHẦN MỀM)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Academic EVM Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'BÁO CÁO GIÁ TRỊ THU ĐƯỢC (EVM)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'QTDAPM - CHƯƠNG 4',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Đo lường tiến độ và ngân sách theo chuẩn quốc tế Project Plan 365 / MS Project:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _evmHeaderItem('Baseline (BAC)', '\$4,126.00'),
                                _evmHeaderItem('Hoàn thành', '56% (613.6h)'),
                                _evmHeaderItem('CPI', '1.00 (Tối ưu)'),
                                _evmHeaderItem('SPI', '0.87 → 1.00'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // EVM Indicators Detail Grid
                      const Text(
                        'Các chỉ số EVM trọng yếu (Chương 4 Báo cáo)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _evmRow(
                              'Planned Value (PV / BCWS)',
                              '\$2,650.00 USD',
                              'Giá trị kế hoạch đường cơ sở',
                            ),
                            const Divider(height: 16, color: AppColors.divider),
                            _evmRow(
                              'Earned Value (EV / BCWP)',
                              '\$2,307.20 USD',
                              'Giá trị thực tế hoàn thành',
                            ),
                            const Divider(height: 16, color: AppColors.divider),
                            _evmRow(
                              'Actual Cost (AC / ACWP)',
                              '\$2,307.20 USD',
                              'Chi phí thực tế giải ngân',
                            ),
                            const Divider(height: 16, color: AppColors.divider),
                            _evmRow(
                              'Cost Variance (CV = EV - AC)',
                              '\$0.00 USD',
                              'Không vượt ngân sách',
                            ),
                            const Divider(height: 16, color: AppColors.divider),
                            _evmRow(
                              'Schedule Variance (SV = EV - PV)',
                              '-\$342.80 USD',
                              'Đã bù đắp xong qua Flutter',
                            ),
                            const Divider(height: 16, color: AppColors.divider),
                            _evmRow(
                              'Cost Performance Index (CPI)',
                              '1.00',
                              'Hiệu suất chi phí hoàn hảo',
                            ),
                            const Divider(height: 16, color: AppColors.divider),
                            _evmRow(
                              'Schedule Performance Index (SPI)',
                              '0.87 → 1.00',
                              'Hồi phục về chuẩn sau nén tiến độ',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Human Resources & RACI Contribution
                      const Text(
                        'Tỉ lệ đóng góp của 4 thành viên (Chương 5 Báo cáo)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._evmMetrics.teamMembers.map((member) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${member.name} (${member.studentId})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          member.role,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Đóng góp: ${member.contributionPercent.toInt()}%',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value:
                                        member.completedHours /
                                        member.assignedHours,
                                    backgroundColor: Colors.grey.shade200,
                                    color: AppColors.primary,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Giờ công: ${member.completedHours}h / ${member.assignedHours}h (${member.progressPercent.toStringAsFixed(1)}%)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Định mức: \$${member.hourlyRate.toStringAsFixed(2)}/h',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Tech Decision Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Quyết định kiến trúc & Khắc phục sự cố:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Nhóm đã chuyển đổi thành công từ module native sang nền tảng Flutter đa nền tảng kết hợp Firebase (Firestore NoSQL, Firebase Auth, Firebase Storage, Rules). '
                              'Quyết định này giải quyết dứt điểm lỗi build máy ảnh quét QR, rút ngắn thời gian lập trình, phục hồi chỉ số SPI từ 0.87 về 1.00 và đảm bảo tiến độ bàn giao đúng ngày 27/11/2026.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Container(
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _evmHeaderItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _evmRow(String title, String value, String description) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              description,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
