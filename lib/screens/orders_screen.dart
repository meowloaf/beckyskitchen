import 'package:flutter/material.dart';

import '../models/shop_order.dart';
import '../services/order_service.dart';
import '../widgets/status_chip.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    required this.orderService,
    required this.userId,
    super.key,
  });

  final OrderService orderService;
  final String userId;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final Stream<List<ShopOrder>> _orders =
      widget.orderService.watchUserOrders(widget.userId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F1),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'My orders',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<ShopOrder>>(
        stream: _orders,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64),
                  SizedBox(height: 12),
                  Text('No orders yet'),
                  Text('Orders you place will show up here.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _OrderCard(order: orders[index]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF0E5DA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.shortId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                StatusChip(order: order),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              order.createdLabel,
              style: TextStyle(fontSize: 12, color: Colors.brown.shade400),
            ),
            const Divider(height: 20),
            for (final line in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text('${line.quantity} × ${line.name}')),
                    Text(
                      '₱${(line.price * line.quantity).toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(
                  order.isDelivery
                      ? Icons.delivery_dining_outlined
                      : Icons.storefront_outlined,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(order.isDelivery ? 'Delivery' : 'Pickup'),
                const Spacer(),
                Text(
                  '₱${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
