import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'product_grid.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAF5),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: Color(0xFFFFE9D5),
              child: Icon(
                Icons.bakery_dining_outlined,
                color: Color(0xFFB9682D),
                size: 22,
              ),
            ),
            SizedBox(width: 10),
            Text(
              "Becky's Kitchen",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) => IconButton(
              tooltip: 'Shopping cart',
              onPressed: () {
                final userId = authService.currentUserId;
                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in to use the cart.'),
                    ),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CartScreen(
                      orderService: OrderService(),
                      userId: userId,
                    ),
                  ),
                );
              },
              icon: Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Hello, ${authService.currentUserName}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: Colors.brown.shade500),
                ),
                const SizedBox(height: 4),
                Text(
                  'What are you craving today?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF39251B),
                  ),
                ),
                const SizedBox(height: 18),
                const _KitchenBanner(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Fresh from our kitchen',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF39251B),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Colors.brown.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Made with love',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: Colors.brown.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Expanded(child: ProductGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await authService.logout();
    } on FirebaseAuthException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to sign out.')),
        );
      }
    } on GoogleSignInException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.description ?? 'Unable to sign out of Google.'),
          ),
        );
      }
    }
  }
}

class _KitchenBanner extends StatelessWidget {
  const _KitchenBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 184,
        width: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF39251B), Color(0xFF684126)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 92,
              top: -86,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
            ),
            Positioned(
              right: -56,
              bottom: -132,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD98B4B).withValues(alpha: 0.2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 22, 18, 22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'MADE FRESH, MADE WITH LOVE',
                            style: TextStyle(
                              color: Color(0xFFFFDDBB),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'A little taste\nof home.',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Homemade favorites, prepared fresh for you.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 116,
                    height: 132,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE9D5),
                      borderRadius: BorderRadius.circular(58),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bakery_dining,
                      size: 62,
                      color: Color(0xFFB9682D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
