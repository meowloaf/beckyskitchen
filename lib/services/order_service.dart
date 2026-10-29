import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';
import '../models/shop_order.dart';

class OrderService {
  OrderService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  Future<String> saveOrder({
    required String userId,
    required String customerName,
    required String phone,
    required String fulfillment,
    required String address,
    required List<CartItem> items,
    required double total,
    required String paymentMethod,
  }) async {
    final doc = await _orders.add({
      'userId': userId,
      'customerName': customerName,
      'phone': phone,
      'fulfillment': fulfillment,
      'address': address,
      'items': items
          .map(
            (item) => {
              'productId': item.product.id,
              'name': item.product.name,
              'price': item.product.price,
              'quantity': item.quantity,
            },
          )
          .toList(),
      'total': total,
      'currency': 'PHP',
      'status': OrderStatus.pending,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentMethod == PaymentMethod.online
          ? PaymentStatus.pending
          : PaymentStatus.unpaid,
      'xenditInvoiceId': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// A customer's own orders, newest first.
  Stream<List<ShopOrder>> watchUserOrders(String userId) {
    return _orders
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_toSortedOrders);
  }

  /// Every order (admin only), newest first.
  Stream<List<ShopOrder>> watchAllOrders() {
    return _orders.snapshots().map(_toSortedOrders);
  }

  Future<void> updateStatus(String orderId, String status) {
    return _orders.doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePaymentStatus(String orderId, String paymentStatus) {
    return _orders.doc(orderId).update({
      'paymentStatus': paymentStatus,
      'paymentPaidAt': paymentStatus == PaymentStatus.paid
          ? FieldValue.serverTimestamp()
          : FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  List<ShopOrder> _toSortedOrders(QuerySnapshot<Map<String, dynamic>> snap) {
    final orders = snap.docs.map(ShopOrder.fromDoc).toList();
    final now = DateTime.now();
    orders.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
    return orders;
  }
}
