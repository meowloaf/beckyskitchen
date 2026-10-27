import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    required this.orderService,
    required this.userId,
    super.key,
  });

  final OrderService orderService;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64),
                  SizedBox(height: 12),
                  Text('Your cart is empty'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return _CartProductTile(item: item);
            },
          );
        },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) return const SizedBox.shrink();
          return SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₱${cart.total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CheckoutScreen(
                          orderService: orderService,
                          userId: userId,
                        ),
                      ),
                    ),
                    child: const Text('Continue to checkout'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CartProductTile extends StatelessWidget {
  const _CartProductTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: item.product.imageUrl.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFFFFF3E8),
                        child: Icon(Icons.fastfood),
                      )
                    : Image.network(
                        item.product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(
                              color: Color(0xFFFFF3E8),
                              child: Icon(Icons.broken_image),
                            ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('₱${item.product.price.toStringAsFixed(2)} each'),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Decrease quantity',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => cart.decrease(item.product.id),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        tooltip: 'Increase quantity',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => cart.add(item.product),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove item',
              onPressed: () => cart.remove(item.product.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
