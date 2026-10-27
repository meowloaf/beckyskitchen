import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;

  int get itemCount =>
      _items.values.fold<int>(0, (sum, item) => sum + item.quantity);

  double get total => _items.values
      .fold<double>(0, (sum, item) => sum + item.product.price * item.quantity);

  void add(Product product) {
    final existing = _items[product.id];
    _items[product.id] = existing == null
        ? CartItem(product: product)
        : existing.copyWith(quantity: existing.quantity + 1);
    notifyListeners();
  }

  void decrease(String productId) {
    final existing = _items[productId];
    if (existing == null) return;
    if (existing.quantity <= 1) {
      _items.remove(productId);
    } else {
      _items[productId] = existing.copyWith(quantity: existing.quantity - 1);
    }
    notifyListeners();
  }

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }

    final existing = _items[productId];
    if (existing == null || existing.quantity == quantity) return;
    _items[productId] = existing.copyWith(quantity: quantity);
    notifyListeners();
  }

  void remove(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}