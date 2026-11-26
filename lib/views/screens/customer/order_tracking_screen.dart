// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// Web-only imports — this screen targets Flutter Web
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import '../../../core/constants/app_colors.dart';
import '../../../models/order_model.dart';

class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  static const _warehouse   = LatLng(16.0471, 108.2068);
  static const _hub         = LatLng(16.0605, 108.2098);
  static const _destination = LatLng(16.0544, 108.2022);

  @override
  Widget build(BuildContext context) {
    final progress = _progressFor(order.status);
    final driver   = _interpolate(_hub, _destination, progress.clamp(.0, 1.0));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),
      appBar: AppBar(title: const Text('Theo dõi đơn hàng')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _OrderHeader(order: order, progress: progress),
          const SizedBox(height: 14),

          // ── Map card ──────────────────────────────────────────────────────
          Container(
            height: 340,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAE6),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: _LeafletMap(
              warehouse:   _warehouse,
              driver:      driver,
              destination: _destination,
              orderId:     order.id,
              status:      order.status,
            ),
          ),

          const SizedBox(height: 12),

          // ── Shipper info card ─────────────────────────────────────────────
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

  static double _progressFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:   return .05;
      case OrderStatus.confirmed: return .22;
      case OrderStatus.packing:   return .45;
      case OrderStatus.shipping:  return .72;
      case OrderStatus.delivered: return 1;
      case OrderStatus.cancelled: return 0;
    }
  }

  static int _stepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:   return 0;
      case OrderStatus.confirmed: return 1;
      case OrderStatus.packing:   return 2;
      case OrderStatus.shipping:  return 3;
      case OrderStatus.delivered: return 4;
      case OrderStatus.cancelled: return 0;
    }
  }

  static LatLng _interpolate(LatLng from, LatLng to, double t) => LatLng(
    from.latitude  + (to.latitude  - from.latitude)  * t,
    from.longitude + (to.longitude - from.longitude) * t,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Leaflet.js map — runs in an iframe so OSM tiles load natively in browser
// ═══════════════════════════════════════════════════════════════════════════

class _LeafletMap extends StatefulWidget {
  final LatLng warehouse;
  final LatLng driver;
  final LatLng destination;
  final String orderId;
  final OrderStatus status;

  const _LeafletMap({
    required this.warehouse,
    required this.driver,
    required this.destination,
    required this.orderId,
    required this.status,
  });

  @override
  State<_LeafletMap> createState() => _LeafletMapState();
}

class _LeafletMapState extends State<_LeafletMap> {
  // Track registered view factories to avoid duplicate registration errors
  static final _registered = <String>{};

  late final String _viewId;

  @override
  void initState() {
    super.initState();
    // Use orderId + hashCode to get a truly unique viewId per widget instance
    _viewId = 'leaflet-${widget.orderId}-${identityHashCode(this)}';

    if (kIsWeb && !_registered.contains(_viewId)) {
      _registered.add(_viewId);
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int _) {
          final iframe = html.IFrameElement()
            ..srcdoc = _buildLeafletHtml()
            ..style.border = 'none'
            ..style.width  = '100%'
            ..style.height = '100%'
            ..setAttribute('sandbox',
                'allow-scripts allow-same-origin allow-popups');
          return iframe;
        },
      );
    }
  }

  String _buildLeafletHtml() {
    final wLat  = widget.warehouse.latitude;
    final wLng  = widget.warehouse.longitude;
    final dLat  = widget.driver.latitude;
    final dLng  = widget.driver.longitude;
    final dstLat = widget.destination.latitude;
    final dstLng = widget.destination.longitude;
    // Center map between driver and destination
    final cLat  = (dLat + dstLat) / 2;
    final cLng  = (dLng + dstLng) / 2;

    final driverLabel = widget.status == OrderStatus.delivered
        ? 'Đã giao thành công'
        : 'Đang giao hàng';

    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link rel="stylesheet"
        href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
        crossorigin=""/>
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
          crossorigin=""></script>
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    html, body, #map { width:100%; height:100%; font-family:sans-serif; }
    .lf-icon {
      display:flex; align-items:center; justify-content:center;
      border-radius:50%; border:3px solid #fff;
      box-shadow:0 2px 8px rgba(0,0,0,.35);
      font-size:16px; color:#fff;
    }
    .lf-label {
      background:#fff; border-radius:6px; padding:3px 7px;
      font-size:11px; font-weight:700; white-space:nowrap;
      box-shadow:0 1px 4px rgba(0,0,0,.2);
      margin-top:3px; text-align:center;
    }
  </style>
</head>
<body>
<div id="map"></div>
<script>
  var map = L.map('map', {
    zoomControl: true,
    attributionControl: true
  }).setView([$cLat, $cLng], 14);

  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    maxZoom: 19,
    crossOrigin: true
  }).addTo(map);

  // ── Helper: custom div icon ──────────────────────────────────────────
  function mkIcon(emoji, bg, size) {
    size = size || 36;
    return L.divIcon({
      className: '',
      iconSize:   [size, size],
      iconAnchor: [size/2, size/2],
      html: '<div class="lf-icon" style="width:'+size+'px;height:'+size+'px;background:'+bg+'">'+emoji+'</div>'
    });
  }

  function mkLabel(text, color) {
    return L.divIcon({
      className: '',
      iconSize:   [120, 50],
      iconAnchor: [60, -4],
      html: '<div class="lf-label" style="color:'+color+'">'+text+'</div>'
    });
  }

  // ── Warehouse ────────────────────────────────────────────────────────
  L.marker([$wLat, $wLng], { icon: mkIcon('📦','#1B5E20') })
   .addTo(map).bindPopup('<b>Kho FreshFarm</b><br>Điểm xuất phát');
  L.marker([$wLat, $wLng], { icon: mkLabel('Kho FreshFarm','#1B5E20'), zIndexOffset:-100 })
   .addTo(map);

  // ── Driver ───────────────────────────────────────────────────────────
  L.marker([$dLat, $dLng], { icon: mkIcon('🚚','#F57F17'), zIndexOffset:1000 })
   .addTo(map).bindPopup('<b>$driverLabel</b>');
  L.marker([$dLat, $dLng], { icon: mkLabel('$driverLabel','#E65100'), zIndexOffset:900 })
   .addTo(map);

  // ── Destination ──────────────────────────────────────────────────────
  L.marker([$dstLat, $dstLng], { icon: mkIcon('🏠','#1565C0') })
   .addTo(map).bindPopup('<b>Địa chỉ nhận hàng</b>');
  L.marker([$dstLat, $dstLng], { icon: mkLabel('Địa chỉ nhận hàng','#1565C0'), zIndexOffset:-100 })
   .addTo(map);

  // ── Route polyline ───────────────────────────────────────────────────
  L.polyline(
    [[$wLat,$wLng], [$dLat,$dLng], [$dstLat,$dstLng]],
    { color:'#2E7D32', weight:5, opacity:.9,
      dashArray: null, lineCap:'round', lineJoin:'round' }
  ).addTo(map);

  // Fit all markers in view with padding
  var bounds = L.latLngBounds(
    [[$wLat,$wLng], [$dLat,$dLng], [$dstLat,$dstLng]]
  );
  map.fitBounds(bounds, { padding:[40,40] });
</script>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(
        child: Text('Bản đồ chỉ hỗ trợ trên nền tảng web.'),
      );
    }
    return HtmlElementView(viewType: _viewId);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Order header widget
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// Timeline steps
// ═══════════════════════════════════════════════════════════════════════════

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
                  color: active
                      ? AppColors.primary
                      : const Color(0xFFE5E9E3),
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
                    color: active
                        ? AppColors.primary
                        : const Color(0xFFE5E9E3),
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
                    fontWeight:
                        current ? FontWeight.w800 : FontWeight.w600,
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
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
