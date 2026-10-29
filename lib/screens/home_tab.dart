import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/categories.dart';
import '../providers/cart_provider.dart';
import '../widgets/kitchen_banner.dart';
import '../widgets/kitchen_logo.dart';
import 'product_grid.dart';

const _accent = Color(0xFF8B0000);
const _sunshine = Color(0xFFFFD700);
const _line = Color(0xFFE9D9D9);

final _searchBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(16),
  borderSide: const BorderSide(color: _line),
);

class HomeTab extends StatefulWidget {
  const HomeTab({required this.onOpenTab, this.showAppBar = true, super.key});

  /// Switches the bottom navigation tab (1 = Categories, 2 = Cart, 4 = Profile).
  final ValueChanged<int> onOpenTab;
  final bool showAppBar;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _search = TextEditingController();
  String _query = '';
  String? _category;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 18) return 'Good afternoon!';
    return 'Good evening!';
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KitchenLogo(size: 38),
                  SizedBox(width: 10),
                  Text(
                    "Becky's Kitchen",
                    style: TextStyle(
                      color: _accent,
                      fontFamily: 'cursive',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              actions: [
                Consumer<CartProvider>(
                  builder: (context, cart, _) => IconButton(
                    tooltip: 'Cart',
                    onPressed: () => widget.onOpenTab(2),
                    icon: Badge(
                      isLabelVisible: cart.itemCount > 0,
                      label: Text('${cart.itemCount}'),
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Profile',
                  onPressed: () => widget.onOpenTab(4),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
                const SizedBox(width: 4),
              ],
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text(
                _greeting,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'What are you craving today?',
                style: const TextStyle(color: Color(0xFF625454)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search your favorite pastries...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: _searchBorder,
                  enabledBorder: _searchBorder,
                  focusedBorder: _searchBorder.copyWith(
                    borderSide: const BorderSide(color: _accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const KitchenBanner(),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Browse categories',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onOpenTab(1),
                    child: const Text(
                      'See all',
                      style: TextStyle(color: _accent),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: productCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final category = productCategories[index];
                    return _CategoryTile(
                      category: category,
                      selected: _category == category.name,
                      onTap: () => setState(() {
                        _category = _category == category.name
                            ? null
                            : category.name;
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _category ?? 'Fresh from the oven',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ProductGrid(category: _category, query: _query, shrinkWrap: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ProductCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _sunshine : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: selected ? _accent : _line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 92,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(category.icon, color: _accent, size: 26),
              const SizedBox(height: 8),
              Text(category.name, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
