import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'home_tab.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

const _accent = Color(0xFF8B1A1A);

/// The signed-in shell: five tabs behind a bottom navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _orderService = OrderService();
  int _index = 0;

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final userId = widget.authService.currentUserId ?? '';

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(onOpenTab: _go),
          const CategoriesScreen(),
          CartScreen(orderService: _orderService, userId: userId),
          OrdersScreen(orderService: _orderService, userId: userId),
          ProfileScreen(
            authService: widget.authService,
            orderService: _orderService,
          ),
        ],
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, _) => NavigationBar(
          backgroundColor: const Color(0xFFFDE9E6),
          indicatorColor: const Color(0xFFFFD9CF),
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: _accent),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded, color: _accent),
              label: 'Categories',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: const Icon(Icons.shopping_bag, color: _accent),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long, color: _accent),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: _accent),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
