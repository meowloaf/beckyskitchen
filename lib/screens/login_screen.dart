import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.authService.login(
        email: _email.text.trim(),
        password: _password.text,
      );
      _returnToAuthGate();
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? 'Unable to sign in.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      await widget.authService.signInWithGoogle();
      _returnToAuthGate();
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? 'Unable to sign in with Google.');
    } on GoogleSignInException catch (error) {
      _showError(error.description ?? 'Google sign-in was cancelled.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    final validationError = _validateEmail(email);
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.authService.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent. Check your inbox.'),
            ),
          );
      }
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? 'Unable to send password reset email.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _returnToAuthGate() {
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.brown.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE9D5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.bakery_dining_outlined,
                                size: 76,
                                color: Color(0xFFB9682D),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Becky's Kitchen",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Welcome back! Sign in to continue.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.brown.shade400),
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                'Email',
                                Icons.email_outlined,
                              ),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!_loading) _login();
                              },
                              decoration:
                                  _inputDecoration(
                                    'Password',
                                    Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Please enter your password'
                                  : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading ? null : _resetPassword,
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: _loading ? null : _login,
                                style: _primaryButtonStyle,
                                child: _loading
                                    ? _loadingIndicator
                                    : const Text('Sign in'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : _loginWithGoogle,
                                icon: const Icon(Icons.g_mobiledata, size: 30),
                                label: const Text('Continue with Google'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => RegisterScreen(
                                          authService: widget.authService,
                                        ),
                                      ),
                                    ),
                              child: const Text(
                                "Don't have an account? Register",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFFFFAF5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

String? _validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter your email';
  }
  if (!value.trim().contains('@')) return 'Enter a valid email address';
  return null;
}

const ButtonStyle _primaryButtonStyle = ButtonStyle(
  backgroundColor: WidgetStatePropertyAll(Color(0xFFB9682D)),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
  ),
);

const Widget _loadingIndicator = SizedBox(
  width: 22,
  height: 22,
  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
);
