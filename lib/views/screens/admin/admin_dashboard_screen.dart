import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/evm_metrics_model.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/mock_data_service.dart';
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

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EvmMetricsModel _evmMetrics = EvmMetricsModel.getDefaultMetrics();
  bool _isSeeding = false;
  String _userSearchQuery = '';
  UserRole? _filterUserRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'Vận hành'),
            Tab(icon: Icon(Icons.people_alt_outlined, size: 18), text: 'Người dùng & Phân quyền'),
            Tab(icon: Icon(Icons.assessment_outlined, size: 18), text: 'Quản trị EVM'),
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
                // TAB 1: E-COMMERCE OPERATIONS & CATALOG
                _buildOperationsTab(orderProv, prodProv),

                // TAB 2: USER MANAGEMENT & RBAC
                _buildUserManagementTab(),

                // TAB 3: PROJECT MANAGEMENT & EVM METRICS
                _buildEvmTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: OPERATIONS & CATALOG MANAGEMENT
  // ==========================================
  Widget _buildOperationsTab(OrderProvider orderProv, ProductProvider prodProv) {
    return SingleChildScrollView(
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
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: FirebaseService.isInitialized ? AppColors.success : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      FirebaseService.isInitialized
                          ? 'Cơ sở dữ liệu Cloud Firestore: Kết nối trực tiếp'
                          : 'Cơ sở dữ liệu cục bộ (Offline Mock Fallback)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Đồng bộ toàn bộ danh mục sản phẩm VietGAP, thông tin lô hàng truy xuất, nông trại và đơn hàng mẫu lên Firebase.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSeeding
                        ? null
                        : () async {
                            setState(() => _isSeeding = true);
                            final ok = await FirebaseService.seedAllDataToFirestore();
                            setState(() => _isSeeding = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? 'Đồng bộ dữ liệu lên Cloud Firestore thành công!'
                                        : 'Lỗi đồng bộ hoặc Firebase chưa cấu hình trực tuyến.',
                                  ),
                                  backgroundColor: ok ? AppColors.success : AppColors.error,
                                ),
                              );
                            }
                          },
                    icon: _isSeeding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text(
                      _isSeeding ? 'Đang đồng bộ dữ liệu...' : 'Đồng bộ dữ liệu mẫu lên Firestore',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Product Catalog & Approval Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quản lý & Duyệt sản phẩm',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              TextButton.icon(
                onPressed: () => _showAddProductDialog(context, prodProv),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Thêm sản phẩm', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // List of Products for Admin
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: prodProv.products.length,
            itemBuilder: (context, index) {
              final product = prodProv.products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl,
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
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.farmName} • ${product.category}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.vietGap.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.certification,
                                    style: const TextStyle(fontSize: 10, color: AppColors.vietGap, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.format(product.price),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        onPressed: () => _showEditProductDialog(context, prodProv, product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: () => _confirmDeleteProduct(context, prodProv, product),
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
  // TAB 2: USER MANAGEMENT & RBAC
  // ==========================================
  Widget _buildUserManagementTab() {
    final mockUsers = MockDataService.getMockUsers();
    final filteredUsers = mockUsers.where((u) {
      final matchQuery = _userSearchQuery.isEmpty ||
          u.name.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          u.phone.contains(_userSearchQuery);
      final matchRole = _filterUserRole == null || u.role == _filterUserRole;
      return matchQuery && matchRole;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RBAC Overview Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.security, color: AppColors.accent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Phân quyền tài khoản (RBAC Matrix)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hệ thống quản lý 4 vai trò độc lập: Khách hàng (KH), Nhà sản xuất (NSX), Nhà cung cấp (NCC), và Quản trị viên (Admin) theo đúng tài liệu SRS & Delphi.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _roleBadgeCount('Khách hàng', '1', Icons.shopping_basket_outlined),
                    _roleBadgeCount('Nhà SX', '1', Icons.agriculture),
                    _roleBadgeCount('Kho vận', '1', Icons.warehouse_outlined),
                    _roleBadgeCount('Admin', '1', Icons.admin_panel_settings_outlined),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search & Filter
          TextField(
            onChanged: (val) => setState(() => _userSearchQuery = val),
            decoration: InputDecoration(
              hintText: 'Tìm theo họ tên, email, số điện thoại...',
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
          const SizedBox(height: 10),

          // Role Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _filterUserRole == null,
                  onSelected: (_) => setState(() => _filterUserRole = null),
                ),
                const SizedBox(width: 6),
                ...UserRole.values.map((role) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(role.displayName),
                      selected: _filterUserRole == role,
                      onSelected: (sel) => setState(() => _filterUserRole = sel ? role : null),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // User Cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                        child: user.avatarUrl == null ? Text(user.name[0]) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user.role.shortTag,
                                    style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              user.phone,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            if (user.farmName != null)
                              Text(
                                'Nông trại: ${user.farmName}',
                                style: const TextStyle(fontSize: 10.5, color: AppColors.vietGap, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (val) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã cập nhật trạng thái người dùng: $val'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'Khóa tài khoản', child: Text('Khóa tài khoản')),
                          const PopupMenuItem(value: 'Cấp quyền Quản trị', child: Text('Chuyển thành Quản trị viên')),
                          const PopupMenuItem(value: 'Xem lịch sử thao tác', child: Text('Lịch sử truy cập')),
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

  Widget _roleBadgeCount(String title, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
      ],
    );
  }

  // ==========================================
  // TAB 3: PROJECT MANAGEMENT & EVM METRICS
  // ==========================================
  Widget _buildEvmTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EVM Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BÁO CÁO EVM - DỰ ÁN FRESHFARM',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Chuẩn MS Project 365',
                      style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _evmHeaderItem('Tổng ngân sách (BAC)', '\$${_evmMetrics.bac.toStringAsFixed(2)}'),
                    _evmHeaderItem('Giá trị thực thu (EV)', '\$${_evmMetrics.ev.toStringAsFixed(2)}'),
                    _evmHeaderItem('Chi phí thực (AC)', '\$${_evmMetrics.ac.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _evmHeaderItem('Chi số chi phí (CPI)', _evmMetrics.cpi.toStringAsFixed(2)),
                    _evmHeaderItem('Chỉ số tiến độ (SPI)', '${_evmMetrics.spi.toStringAsFixed(2)} → 1.00'),
                    _evmHeaderItem('Dự toán hoàn tất (EAC)', '\$${_evmMetrics.eac.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // EVM Performance Bar Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'So sánh các chỉ số giá trị (USD)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Planned Value (PV) vs Earned Value (EV) vs Actual Cost (AC)',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 3000,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              switch (val.toInt()) {
                                case 0:
                                  return const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Text('PV (\$2,650)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  );
                                case 1:
                                  return const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Text('EV (\$2,307)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  );
                                case 2:
                                  return const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Text('AC (\$2,307)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  );
                                default:
                                  return const SizedBox.shrink();
                              }
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (val, meta) => Text(
                              '\$${val.toInt()}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        _makeBarGroup(0, _evmMetrics.pv, const Color(0xFF1976D2)),
                        _makeBarGroup(1, _evmMetrics.ev, AppColors.success),
                        _makeBarGroup(2, _evmMetrics.ac, AppColors.accent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Team Member Hours & Budget Breakdown
          const Text(
            'Phân bổ giờ công & Chi phí 4 thành viên (WBS)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),

          ..._evmMetrics.teamMembers.map((member) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${member.name} (${member.studentId})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${member.progressPercent.toStringAsFixed(1)}% hoàn tất',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.role,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: member.completedHours / member.assignedHours,
                        backgroundColor: AppColors.divider,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${member.completedHours}h / ${member.assignedHours}h',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          'Định mức: \$${member.hourlyRate.toStringAsFixed(2)}/h • Chi trả: \$${member.actualSpent.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
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
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Quyết định kiến trúc & Khắc phục sự cố:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Nhóm đã chuyển đổi thành công từ module native sang nền tảng Flutter đa nền tảng kết hợp Firebase (Firestore NoSQL, Firebase Auth, Firebase Storage, Rules). '
                  'Quyết định này giải quyết dứt điểm lỗi build máy ảnh quét QR, rút ngắn thời gian lập trình, phục hồi chỉ số SPI từ 0.87 về 1.00 và đảm bảo tiến độ bàn giao đúng ngày 27/11/2026.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Dialog Add Product
  void _showAddProductDialog(BuildContext context, ProductProvider prodProv) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final farmCtrl = TextEditingController(text: 'Nông trại Hướng Dương Đà Lạt');
    final unitCtrl = TextEditingController(text: 'Hộp 500g');
    String selectedCategory = 'Rau củ hữu cơ';
    String selectedCert = 'VietGAP';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Thêm nông sản mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên sản phẩm')),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Giá niêm yết (VNĐ)'), keyboardType: TextInputType.number),
                TextField(controller: farmCtrl, decoration: const InputDecoration(labelText: 'Tên Nông trại/Hợp tác xã')),
                TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Đơn vị đóng gói')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCert,
                  decoration: const InputDecoration(labelText: 'Chứng nhận tiêu chuẩn'),
                  items: ['VietGAP', 'GlobalGAP', 'Organic USDA', 'OCOP 4 Sao']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setDlgState(() => selectedCert = val ?? 'VietGAP'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                final newProd = ProductModel(
                  id: 'PROD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  name: nameCtrl.text.trim(),
                  category: selectedCategory,
                  price: double.tryParse(priceCtrl.text) ?? 50000,
                  unit: unitCtrl.text.trim(),
                  imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=300',
                  description: 'Nông sản sạch đạt chuẩn an toàn vệ sinh thực phẩm.',
                  rating: 5.0,
                  reviewCount: 1,
                  farmId: 'FARM-DL-01',
                  farmName: farmCtrl.text.trim(),
                  region: 'Đà Lạt, Lâm Đồng',
                  certification: selectedCert,
                  batchId: 'BATCH-2026-NEW',
                  stockQuantity: 100,
                );
                prodProv.addProduct(newProd);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã thêm sản phẩm "${newProd.name}" thành công!'), backgroundColor: AppColors.success),
                );
              },
              child: const Text('Thêm vào hệ thống'),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog Edit Product
  void _showEditProductDialog(BuildContext context, ProductProvider prodProv, ProductModel product) {
    final nameCtrl = TextEditingController(text: product.name);
    final priceCtrl = TextEditingController(text: product.price.toInt().toString());
    final stockCtrl = TextEditingController(text: product.stockQuantity.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chỉnh sửa ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên sản phẩm')),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Giá niêm yết (VNĐ)'), keyboardType: TextInputType.number),
            TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Số lượng tồn kho'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final updated = product.copyWith(
                name: nameCtrl.text.trim(),
                price: double.tryParse(priceCtrl.text) ?? product.price,
                stockQuantity: int.tryParse(stockCtrl.text) ?? product.stockQuantity,
              );
              prodProv.updateProduct(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã cập nhật sản phẩm!'), backgroundColor: AppColors.primary),
              );
            },
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, ProductProvider prodProv, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product.name}" khỏi hệ thống?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              prodProv.deleteProduct(product.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa "${product.name}"'), backgroundColor: AppColors.error),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
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
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
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
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
