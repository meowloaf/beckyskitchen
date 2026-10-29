import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../models/shop_order.dart';
import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import 'admin_orders_screen.dart';
import 'admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.authService,
    required this.orderService,
    super.key,
  });

  final AuthService authService;
  final OrderService orderService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Stream<bool> _isAdmin = widget.authService.watchIsAdmin();

  Future<void> _signOut() async {
    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.authService.logout();
      cart.clear();
    } on FirebaseAuthException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to sign out.')),
      );
    } on GoogleSignInException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.description ?? 'Unable to sign out of Google.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName ?? '').trim();
    final title = displayName.isNotEmpty
        ? displayName
        : (user?.email ?? 'Guest');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFFFD700),
              child: Text(
                title.characters.first.toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  color: Color(0xFF8B0000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (user?.email != null)
            Text(
              user!.email!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF625454)),
            ),
          const SizedBox(height: 24),
          StreamBuilder<bool>(
            stream: _isAdmin,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Admin check error: ${snapshot.error}');
              }
              if (snapshot.data != true) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ManageOrdersTile(orderService: widget.orderService),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('Manage products'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AdminScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: _signOut,
            ),
          ),
        ],
      ),
    );
  }
}

/// Only built for admins, so the all-orders listener never runs for customers.
class _ManageOrdersTile extends StatefulWidget {
  const _ManageOrdersTile({required this.orderService});

  final OrderService orderService;

  @override
  State<_ManageOrdersTile> createState() => _ManageOrdersTileState();
}

class _ManageOrdersTileState extends State<_ManageOrdersTile> {
  late final Stream<List<ShopOrder>> _orders = widget.orderService
      .watchAllOrders();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShopOrder>>(
      stream: _orders,
      builder: (context, snapshot) {
        final pending = (snapshot.data ?? const <ShopOrder>[])
            .where((order) => order.status == OrderStatus.pending)
            .length;
        return ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('Manage orders'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pending > 0) Badge(label: Text('$pending new')),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  AdminOrdersScreen(orderService: widget.orderService),
            ),
          ),
        );
      },
    );
  }
}
