import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    required this.orderService,
    required this.userId,
    super.key,
  });

  final OrderService orderService;
  final String userId;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _placingOrder = false;

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    if (cart.isEmpty || _placingOrder) return;

    final items = List.of(cart.items);
    final total = cart.total;
    setState(() => _placingOrder = true);
    try {
      await widget.orderService.saveOrder(
        userId: widget.userId,
        items: items,
        total: total,
      );
      if (!mounted) return;

      cart.clear();
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Order saved. Online payment is not available yet.'),
          ),
        );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(error.message ?? 'Unable to save order.')),
          );
      }
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Order summary',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...cart.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.product.name),
                  subtitle: Text(
                    '${item.quantity} × ₱${item.product.price.toStringAsFixed(2)}',
                  ),
                  trailing: Text(
                    '₱${(item.quantity * item.product.price).toStringAsFixed(2)}',
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '₱${cart.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Online payment is a placeholder for now. Placing this order '
                    'will save it as pending in your account.',
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 50,
          child: Consumer<CartProvider>(
            builder: (context, cart, _) => FilledButton(
              onPressed: _placingOrder || cart.isEmpty ? null : _placeOrder,
              child: _placingOrder
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Place order'),
            ),
          ),
        ),
      ),
    );
  }
}
