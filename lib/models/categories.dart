import 'package:flutter/material.dart';

class ProductCategory {
  const ProductCategory(this.name, this.icon);

  final String name;
  final IconData icon;
}

const productCategories = <ProductCategory>[
  ProductCategory('Cakes', Icons.cake_outlined),
  ProductCategory('Cupcakes', Icons.icecream_outlined),
  ProductCategory('Cookies', Icons.cookie_outlined),
  ProductCategory('Bread', Icons.breakfast_dining_outlined),
];
