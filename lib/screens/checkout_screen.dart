import 'package:firebase_auth/firebase_auth.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String _fulfillment = 'pickup';
  bool _placingOrder = false;

  bool get _isDelivery => _fulfillment == 'delivery';

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    if (cart.isEmpty || _placingOrder) return;
    if (!_formKey.currentState!.validate()) return;

    final items = List.of(cart.items);
    final total = cart.total;
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName ?? '').trim();

    setState(() => _placingOrder = true);
    try {
      await widget.orderService.saveOrder(
        userId: widget.userId,
        customerName: name.isNotEmpty ? name : (user?.email ?? 'Customer'),
        phone: _phone.text.trim(),
        fulfillment: _fulfillment,
        address: _isDelivery ? _address.text.trim() : '',
        items: items,
        total: total,
      );
      if (!mounted) return;

      cart.clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Order placed! Track it in the Orders tab.'),
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
  void dispose() {
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: Consumer<CartProvider>(
          builder: (context, cart, _) {
            if (cart.isEmpty) {
              return const Center(child: Text('Your cart is empty'));
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Order summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'How would you like to get it?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'pickup',
                      icon: Icon(Icons.storefront_outlined),
                      label: Text('Pickup'),
                    ),
                    ButtonSegment(
                      value: 'delivery',
                      icon: Icon(Icons.delivery_dining_outlined),
                      label: Text('Delivery'),
                    ),
                  ],
                  selected: {_fulfillment},
                  onSelectionChanged: (selection) =>
                      setState(() => _fulfillment = selection.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value ?? '').trim().length < 7
                      ? 'Enter a phone number we can reach you on'
                      : null,
                ),
                if (_isDelivery) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Delivery address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Enter your delivery address'
                        : null,
                  ),
                ],
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Pay with cash when you '
                      '${_isDelivery ? 'receive' : 'pick up'} your order. '
                      'Online payment is coming soon.',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
