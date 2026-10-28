import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class ProductService {
  const ProductService();

  CollectionReference<Map<String, dynamic>> get _products =>
      FirebaseFirestore.instance.collection('products');

  Stream<List<Product>> watchProducts() {
    return _products.snapshots().map(
      (snapshot) => snapshot.docs.map(Product.fromDoc).toList(),
    );
  }

  Future<void> addProduct({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String category,
  }) {
    return _products.add({
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
    });
  }

  Future<void> deleteProduct(String productId) {
    return _products.doc(productId).delete();
  }
}
