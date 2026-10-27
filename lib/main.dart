import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp(authService: AuthService()));
}

class MyApp extends StatelessWidget {
  const MyApp({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: "Becky's Kitchen",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
        home: StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return snapshot.hasData
                ? HomeScreen(authService: authService)
                : LoginScreen(authService: authService);
          },
        ),
      ),
    );
  }
}