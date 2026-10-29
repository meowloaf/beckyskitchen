import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../widgets/kitchen_logo.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'home_tab.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

const _crimson = Color(0xFF8B0000);
const _sunshine = Color(0xFFFFD700);

const _navigationItems = [
  (label: 'Home', icon: Icons.home_outlined),
  (label: 'Categories', icon: Icons.grid_view_outlined),
  (label: 'Cart', icon: Icons.shopping_bag_outlined),
  (label: 'Orders', icon: Icons.receipt_long_outlined),
  (label: 'Profile', icon: Icons.person_outline),
];

/// The signed-in shell adapts between a desktop sidebar and mobile navigation.
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 700;
          final tabs = [
            HomeTab(onOpenTab: _go, showAppBar: !wide),
            const CategoriesScreen(),
            CartScreen(orderService: _orderService, userId: userId),
            OrdersScreen(orderService: _orderService, userId: userId),
            ProfileScreen(
              authService: widget.authService,
              orderService: _orderService,
            ),
          ];
          if (wide) {
            return Row(
              children: [
                SizedBox(
                  width: constraints.maxWidth < 840 ? 208 : 252,
                  child: _KitchenSidebar(
                    selectedIndex: _index,
                    onSelected: _go,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _DesktopHeader(selectedIndex: _index, onOpenTab: _go),
                      Expanded(
                        child: IndexedStack(index: _index, children: tabs),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return IndexedStack(index: _index, children: tabs);
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 700) return const SizedBox.shrink();
          return Consumer<CartProvider>(
            builder: (context, cart, _) => IconTheme(
              data: const IconThemeData(color: Colors.white70),
              child: NavigationBar(
                backgroundColor: _crimson,
                indicatorColor: _sunshine,
                selectedIndex: _index,
                onDestinationSelected: _go,
                labelTextStyle: WidgetStateProperty.resolveWith(
                  (states) => TextStyle(
                    color: states.contains(WidgetState.selected)
                        ? _sunshine
                        : Colors.white70,
                    fontWeight: states.contains(WidgetState.selected)
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                destinations: [
                  for (var index = 0; index < _navigationItems.length; index++)
                    NavigationDestination(
                      icon: index == 2
                          ? Badge(
                              isLabelVisible: cart.itemCount > 0,
                              label: Text('${cart.itemCount}'),
                              child: Icon(_navigationItems[index].icon),
                            )
                          : Icon(_navigationItems[index].icon),
                      selectedIcon: Icon(_selectedIcon(index), color: _crimson),
                      label: _navigationItems[index].label,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

IconData _selectedIcon(int index) => switch (index) {
  0 => Icons.home,
  1 => Icons.grid_view_rounded,
  2 => Icons.shopping_bag,
  3 => Icons.receipt_long,
  _ => Icons.person,
};

class _KitchenSidebar extends StatelessWidget {
  const _KitchenSidebar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _crimson,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const KitchenLogo(size: 50),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Becky's\nKitchen",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'cursive',
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(height: 2, width: 44, color: _sunshine),
              const SizedBox(height: 14),
              const Text(
                'YOUR KITCHEN',
                style: TextStyle(
                  color: _sunshine,
                  fontSize: 10,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < _navigationItems.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _SidebarItem(
                    label: _navigationItems[index].label,
                    icon: _navigationItems[index].icon,
                    selected: index == selectedIndex,
                    onTap: () => onSelected(index),
                  ),
                ),
              const Spacer(),
              const Divider(color: Color(0x66FFD700)),
              const SizedBox(height: 12),
              const Text(
                'Made fresh,\nmade with love.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _sunshine : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: selected ? _crimson : Colors.white70),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? _crimson : Colors.white,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.selectedIndex, required this.onOpenTab});

  final int selectedIndex;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) => Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE9D9D9))),
        ),
        child: Row(
          children: [
            const KitchenLogo(size: 42),
            const SizedBox(width: 12),
            Text(
              "Becky's Kitchen",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _crimson,
                fontFamily: 'cursive',
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 18),
            Container(width: 42, height: 3, color: _sunshine),
            const Spacer(),
            Text(
              _navigationItems[selectedIndex].label,
              style: const TextStyle(
                color: _crimson,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 18),
            IconButton(
              tooltip: 'Cart',
              onPressed: () => onOpenTab(2),
              icon: Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_bag_outlined, color: _crimson),
              ),
            ),
            IconButton(
              tooltip: 'Profile',
              onPressed: () => onOpenTab(4),
              icon: const Icon(Icons.account_circle_outlined, color: _crimson),
            ),
          ],
        ),
      ),
    );
  }
}
