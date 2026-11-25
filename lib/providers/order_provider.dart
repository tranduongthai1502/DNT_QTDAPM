import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../services/mock_data_service.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  OrderProvider() {
    loadOrders();
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    final cached = await StorageService.getOrders();
    if (cached != null && cached.isNotEmpty) {
      _orders = cached;
    } else {
      _orders = MockDataService.getMockOrders();
      await StorageService.saveOrders(_orders);
    }

    _isLoading = false;
    notifyListeners();
  }

  List<OrderModel> getOrdersByStatus(OrderStatus? status) {
    if (status == null) return _orders;
    return _orders.where((o) => o.status == status).toList();
  }

  List<OrderModel> getOrdersForUser(String userId) {
    return _orders.where((o) => o.userId == userId).toList();
  }

  Future<OrderModel> createOrder({
    required String userId,
    required String userName,
    required String userPhone,
    required String shippingAddress,
    required List<OrderItemModel> items,
    required double totalAmount,
    required double shippingFee,
    required double discountAmount,
    required double finalAmount,
    required PaymentMethod paymentMethod,
    bool isPaid = false,
    String deliveryPartner = 'AhaMove Xe Lạnh Chuẩn 18°C',
  }) async {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomSuffix = const Uuid().v4().substring(0, 4).toUpperCase();
    final orderId = 'FF-$dateStr-$randomSuffix';

    final newOrder = OrderModel(
      id: orderId,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      shippingAddress: shippingAddress,
      items: items,
      totalAmount: totalAmount,
      shippingFee: shippingFee,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
      paymentMethod: paymentMethod,
      isPaid: isPaid || paymentMethod == PaymentMethod.vietqr,
      status: OrderStatus.pending,
      createdAt: now,
      deliveryTrackingCode: 'COLD-FF-$randomSuffix',
      deliveryPartner: deliveryPartner,
    );

    _orders.insert(0, newOrder);
    await StorageService.saveOrders(_orders);
    await FirebaseService.syncOrderToFirestore(newOrder);
    notifyListeners();
    return newOrder;
  }

  Future<void> advanceOrderStatus(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final current = _orders[index];
      final next = current.status.nextState;
      if (next != null) {
        current.status = next;
        if (next == OrderStatus.delivered) {
          current.isPaid = true;
        }
        await StorageService.saveOrders(_orders);
        await FirebaseService.syncOrderToFirestore(current);
        notifyListeners();
      }
    }
  }

  Future<void> cancelOrder(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].status = OrderStatus.cancelled;
      await StorageService.saveOrders(_orders);
      await FirebaseService.syncOrderToFirestore(_orders[index]);
      notifyListeners();
    }
  }

  // Dashboard Aggregations for Admin
  double get totalRevenue => _orders
      .where((o) => o.status != OrderStatus.cancelled && o.isPaid)
      .fold(0.0, (sum, o) => sum + o.finalAmount);

  int get completedOrderCount => _orders.where((o) => o.status == OrderStatus.delivered).length;
  int get pendingOrderCount => _orders.where((o) => o.status == OrderStatus.pending).length;
  int get shippingOrderCount => _orders.where((o) => o.status == OrderStatus.shipping).length;
}

