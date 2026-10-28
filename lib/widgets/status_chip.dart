import 'package:flutter/material.dart';

import '../models/shop_order.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.order, super.key});

  final ShopOrder order;

  Color get _color {
    switch (order.status) {
      case OrderStatus.accepted:
        return Colors.blue.shade700;
      case OrderStatus.ready:
        return Colors.green.shade700;
      case OrderStatus.completed:
        return Colors.grey.shade700;
      case OrderStatus.declined:
        return Colors.red.shade700;
      default:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        order.statusLabel,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
