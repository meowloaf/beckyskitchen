import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/shop_order.dart';
import '../services/order_service.dart';
import '../widgets/status_chip.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({required this.orderService, super.key});

  final OrderService orderService;

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late final Stream<List<ShopOrder>> _orders = widget.orderService
      .watchAllOrders();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Manage orders'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'New'),
              Tab(text: 'In progress'),
              Tab(text: 'History'),
            ],
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
            List<ShopOrder> only(Set<String> statuses) =>
                orders.where((o) => statuses.contains(o.status)).toList();

            return TabBarView(
              children: [
                _OrderList(
                  orders: only({OrderStatus.pending}),
                  orderService: widget.orderService,
                  emptyText: 'No new orders',
                ),
                _OrderList(
                  orders: only({OrderStatus.accepted, OrderStatus.ready}),
                  orderService: widget.orderService,
                  emptyText: 'Nothing in progress',
                ),
                _OrderList(
                  orders: only({OrderStatus.completed, OrderStatus.declined}),
                  orderService: widget.orderService,
                  emptyText: 'No finished orders yet',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.orderService,
    required this.emptyText,
  });

  final List<ShopOrder> orders;
  final OrderService orderService;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return Center(child: Text(emptyText));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _AdminOrderCard(order: orders[index], orderService: orderService),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order, required this.orderService});

  final ShopOrder order;
  final OrderService orderService;

  Future<void> _setStatus(BuildContext context, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await orderService.updateStatus(order.id, status);
    } on FirebaseException catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to update order.')),
        );
    }
  }

  Future<void> _decline(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Decline this order?'),
        content: Text('Order #${order.shortId} will be marked as declined.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _setStatus(context, OrderStatus.declined);
    }
  }

  List<Widget> _actions(BuildContext context) {
    switch (order.status) {
      case OrderStatus.pending:
        return [
          OutlinedButton(
            onPressed: () => _decline(context),
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: () => _setStatus(context, OrderStatus.accepted),
            child: const Text('Accept order'),
          ),
        ];
      case OrderStatus.accepted:
        return [
          FilledButton.icon(
            onPressed: () => _setStatus(context, OrderStatus.ready),
            icon: Icon(
              order.isDelivery ? Icons.delivery_dining : Icons.storefront,
            ),
            label: Text(
              order.isDelivery ? 'Ready for delivery' : 'Ready for pickup',
            ),
          ),
        ];
      case OrderStatus.ready:
        return [
          FilledButton(
            onPressed: () => _setStatus(context, OrderStatus.completed),
            child: Text(order.isDelivery ? 'Mark delivered' : 'Mark picked up'),
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF625454)),
          const SizedBox(width: 6),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE9D9D9)),
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
            Text(
              order.createdLabel,
              style: const TextStyle(fontSize: 12, color: Color(0xFF625454)),
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.person_outline, order.customerName),
            if (order.phone.isNotEmpty)
              _infoRow(Icons.phone_outlined, order.phone),
            _infoRow(
              order.isDelivery
                  ? Icons.delivery_dining_outlined
                  : Icons.storefront_outlined,
              order.isDelivery ? 'Delivery' : 'Pickup',
            ),
            if (order.isDelivery && order.address.isNotEmpty)
              _infoRow(Icons.location_on_outlined, order.address),
            const Divider(height: 24),
            for (final line in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text('${line.quantity} × ${line.name}')),
                    Text('₱${(line.price * line.quantity).toStringAsFixed(2)}'),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '₱${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(spacing: 8, runSpacing: 8, children: actions),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
