import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/order_model.dart';

class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  static const _warehouse = LatLng(16.0471, 108.2068);
  static const _hub = LatLng(16.0605, 108.2098);
  static const _destination = LatLng(16.0544, 108.2022);

  @override
  Widget build(BuildContext context) {
    final progress = _progressFor(order.status);
    final driver = _interpolate(_hub, _destination, progress.clamp(.0, 1.0));
    final route = [_warehouse, _hub, driver, _destination];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),
      appBar: AppBar(title: const Text('Theo dõi đơn hàng')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _OrderHeader(order: order, progress: progress),
          const SizedBox(height: 14),
          Container(
            height: 320,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: FlutterMap(
              options: const MapOptions(initialCenter: _hub, initialZoom: 13.2),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.vku.freshfarm',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route,
                      color: AppColors.primary,
                      strokeWidth: 5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    _marker(
                      _warehouse,
                      Icons.inventory_2_rounded,
                      AppColors.primaryDark,
                      'Kho FreshFarm',
                    ),
                    _marker(
                      driver,
                      Icons.local_shipping_rounded,
                      AppColors.accent,
                      order.status == OrderStatus.delivered
                          ? 'Đã đến nơi'
                          : 'Đang giao',
                    ),
                    _marker(
                      _destination,
                      Icons.home_rounded,
                      AppColors.info,
                      'Địa chỉ nhận hàng',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.status.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${order.deliveryPartner} • ${order.deliveryTrackingCode}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (order.status == OrderStatus.shipping)
                  const Text(
                    'Đang di chuyển',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Hành trình đơn hàng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ..._steps.map(
            (step) => _TimelineStep(
              step: step,
              active: _stepIndex(order.status) >= step.index,
              current: _stepIndex(order.status) == step.index,
            ),
          ),
        ],
      ),
    );
  }

  static Marker _marker(
    LatLng point,
    IconData icon,
    Color color,
    String label,
  ) => Marker(
    point: point,
    width: 122,
    height: 70,
    child: Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x40000000), blurRadius: 6),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        Container(
          margin: const EdgeInsets.only(top: 3),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 4),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  static double _progressFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return .05;
      case OrderStatus.confirmed:
        return .22;
      case OrderStatus.packing:
        return .45;
      case OrderStatus.shipping:
        return .72;
      case OrderStatus.delivered:
        return 1;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  static int _stepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.packing:
        return 2;
      case OrderStatus.shipping:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  static LatLng _interpolate(LatLng from, LatLng to, double t) => LatLng(
    from.latitude + (to.latitude - from.latitude) * t,
    from.longitude + (to.longitude - from.longitude) * t,
  );
}

class _OrderHeader extends StatelessWidget {
  final OrderModel order;
  final double progress;
  const _OrderHeader({required this.order, required this.progress});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [AppColors.primaryDark, AppColors.primary],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đơn hàng đang được chăm sóc',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          order.id,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(progress * 100).round()}% hành trình hoàn tất',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

const _steps = <_TrackingStep>[
  _TrackingStep(
    index: 0,
    icon: Icons.receipt_long_rounded,
    title: 'Đã tiếp nhận đơn',
    subtitle: 'FreshFarm đã nhận thông tin đặt hàng.',
  ),
  _TrackingStep(
    index: 1,
    icon: Icons.verified_rounded,
    title: 'Nhà cung cấp xác nhận',
    subtitle: 'Đơn hàng được xác nhận và chuẩn bị hàng.',
  ),
  _TrackingStep(
    index: 2,
    icon: Icons.inventory_2_rounded,
    title: 'Đang đóng gói',
    subtitle: 'Nông sản được kiểm tra và đóng gói giữ tươi.',
  ),
  _TrackingStep(
    index: 3,
    icon: Icons.local_shipping_rounded,
    title: 'Đang giao đến bạn',
    subtitle: 'Đơn hàng đang trên đường đến địa chỉ nhận.',
  ),
  _TrackingStep(
    index: 4,
    icon: Icons.home_rounded,
    title: 'Giao hàng thành công',
    subtitle: 'Cảm ơn bạn đã mua nông sản sạch.',
  ),
];

class _TrackingStep {
  final int index;
  final IconData icon;
  final String title, subtitle;
  const _TrackingStep({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _TimelineStep extends StatelessWidget {
  final _TrackingStep step;
  final bool active, current;
  const _TimelineStep({
    required this.step,
    required this.active,
    required this.current,
  });
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : const Color(0xFFE5E9E3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step.icon,
                  color: active ? Colors.white : AppColors.textMuted,
                  size: 15,
                ),
              ),
              if (step.index < _steps.length - 1)
                Expanded(
                  child: Container(
                    width: 2,
                    color: active ? AppColors.primary : const Color(0xFFE5E9E3),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                    color: active ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
