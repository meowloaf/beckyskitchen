import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class XenditService {
  XenditService({String? supabaseUrl, String? supabasePublishableKey})
    : supabaseUrl =
          supabaseUrl ??
          const String.fromEnvironment(
            'SUPABASE_URL',
            defaultValue: 'https://ezrldnyhbszwivufxdut.supabase.co',
          ),
      supabasePublishableKey =
          supabasePublishableKey ??
          const String.fromEnvironment(
            'SUPABASE_PUBLISHABLE_KEY',
            defaultValue: 'sb_publishable_OGZ7JQy8BMrPgSxlhMY16w_AYTLj0K8',
          );

  final String supabaseUrl;
  final String supabasePublishableKey;

  Future<String> createInvoice({required String orderId}) async {
    final user = FirebaseAuth.instance.currentUser;
    final firebaseToken = await user?.getIdToken();
    if (firebaseToken == null) {
      throw StateError('Sign in before making an online payment.');
    }

    final response = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/create-xendit-invoice'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabasePublishableKey,
        'Authorization': 'Bearer $firebaseToken',
      },
      body: jsonEncode({'orderId': orderId}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        body['error'] as String? ?? 'Unable to create Xendit invoice.',
      );
    }

    final invoiceUrl = body['invoiceUrl'] as String?;
    if (invoiceUrl == null || invoiceUrl.isEmpty) {
      throw StateError('Xendit did not return a checkout URL.');
    }
    return invoiceUrl;
  }
}
