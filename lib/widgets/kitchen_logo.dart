import 'package:flutter/material.dart';

class KitchenLogo extends StatelessWidget {
  const KitchenLogo({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/beckys_kitchen_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: "Becky's Kitchen logo",
    );
  }
}
