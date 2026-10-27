import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';

class OrderService {
  OrderService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> saveOrder({
    required String userId,
    required List<CartItem> items,
    required double total,
  }) async {
    await _firestore.collection('orders').add({
      'userId': userId,
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
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
