import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    required this.orderService,
    required this.userId,
    super.key,
  });

  final OrderService orderService;
  final String userId;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _selectedIds = {};
  final Set<String> _knownIds = {};
  bool _selectionInitialized = false;

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

          if (!_selectionInitialized) {
            _selectedIds.addAll(cart.items.map((item) => item.product.id));
            _knownIds.addAll(_selectedIds);
            _selectionInitialized = true;
          } else {
            _selectedIds.removeWhere(
              (id) => !cart.items.any((item) => item.product.id == id),
            );
            for (final item in cart.items) {
              if (!_knownIds.contains(item.product.id)) {
                _selectedIds.add(item.product.id);
              }
            }
            _knownIds
              ..clear()
              ..addAll(cart.items.map((item) => item.product.id));
          }

          final selectedItems = cart.items
              .where((item) => _selectedIds.contains(item.product.id))
              .toList();
          final allSelected = selectedItems.length == cart.items.length;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: allSelected,
                  onChanged: (value) {
                    setState(() {
                      _selectedIds
                        ..clear()
                        ..addAll(
                          value == true
                              ? cart.items.map((item) => item.product.id)
                              : const <String>[],
                        );
                    });
                  },
                  title: Text(
                    allSelected ? 'Deselect all' : 'Select all',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }

              final item = cart.items[index - 1];
              return _CartProductTile(
                item: item,
                selected: _selectedIds.contains(item.product.id),
                onSelected: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedIds.add(item.product.id);
                    } else {
                      _selectedIds.remove(item.product.id);
                    }
                  });
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) return const SizedBox.shrink();
          final selectedItems = cart.items
              .where((item) => _selectedIds.contains(item.product.id))
              .toList();
          final selectedTotal = selectedItems.fold<double>(
            0,
            (sum, item) => sum + item.product.price * item.quantity,
          );
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
                      '₱${selectedTotal.toStringAsFixed(2)}',
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
                    onPressed: selectedItems.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CheckoutScreen(
                                orderService: widget.orderService,
                                userId: widget.userId,
                                initialItems: selectedItems,
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
  const _CartProductTile({
    required this.item,
    required this.selected,
    required this.onSelected,
  });

  final CartItem item;
  final bool selected;
  final ValueChanged<bool?> onSelected;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(value: selected, onChanged: onSelected),
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
