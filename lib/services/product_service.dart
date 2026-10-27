import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class ProductService {
  const ProductService();

  Stream<List<Product>> watchProducts() {
    return FirebaseFirestore.instance.collection('products').snapshots().map(
      (snapshot) => snapshot.docs.map(Product.fromDoc).toList(),
    );
  }
}
