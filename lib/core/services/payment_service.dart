import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/billplz_config.dart';
import '../config/xendit_config.dart';


import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PaymentService {
  // Initialize payment service
  static Future<void> initialize() async {
    // Load environment variables if needed
  }

  // Create Bill in Billplz
  static Future<Map<String, dynamic>> createBill({
    required String collectionId,
    required String email,
    required String mobile,
    required String name,
    required double amount, // in MYR
    required String callbackUrl,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print("Calling Supabase Edge Function 'create_billplz'...");
      
      // Use Supabase Edge Function to avoid CORS and hide API keys
      final response = await Supabase.instance.client.functions.invoke(
        'create_billplz',
        body: {
          'collectionId': collectionId,
          'email': email,
          'mobile': mobile,
          'name': name,
          'amount': (amount * 100).toInt().toString(), // Convert to cents
          'callbackUrl': callbackUrl,
          'description': description,
          'isSandbox': BillplzConfig.isSandbox, 
        },
      );
      
      print("Edge Function Response Status: ${response.status}");
      print("Edge Function Response Data: ${response.data}");

      if (response.status == 200) {
         return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to create bill via Edge Function: ${response.data}');
      }

    } catch (e) {
      print("PaymentService Edge Function Exception: $e");
      
      // Fallback for direct call (only if Function fails or not deployed yet, mostly for native testing)
      // Note: Direct call will fail on Web due to CORS as established.
      if (!kIsWeb) {
         print("Attempting fallback to direct API call (Native only)...");
         return _createBillDirect(
           collectionId: collectionId,
           email: email,
           mobile: mobile,
           name: name,
           amount: amount,
           callbackUrl: callbackUrl,
           description: description
         );
      }
      
      rethrow;
    }
  }

  // Fallback Direct API call (Original implementation)
  static Future<Map<String, dynamic>> _createBillDirect({
    required String collectionId,
    required String email,
    required String mobile,
    required String name,
    required double amount,
    required String callbackUrl,
    required String description,
  }) async {
      final url = Uri.parse('${BillplzConfig.baseUrl}/bills');
      final auth = base64Encode(utf8.encode('${BillplzConfig.apiKey}:'));
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'collection_id': collectionId,
          'email': email,
          'mobile': mobile,
          'name': name,
          'amount': (amount * 100).toInt().toString(),
          'callback_url': callbackUrl,
          'description': description,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create bill (Direct): ${response.body}');
      }
  }

  // Check Bill Status
  static Future<Map<String, dynamic>> getBill(String billId) async {
    try {
      print("Calling Supabase Edge Function 'create_billplz' with action 'get_status'...");
      
      final response = await Supabase.instance.client.functions.invoke(
        'create_billplz',
        body: {
          'action': 'get_status',
          'billId': billId,
          'isSandbox': BillplzConfig.isSandbox, 
        },
      );
      
      if (response.status == 200) {
         return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to check bill status via Edge Function: ${response.data}');
      }
    } catch (e) {
      print("Edge Function getBill status check failed: $e. Attempting fallback...");
      if (!kIsWeb) {
        final url = Uri.parse('${BillplzConfig.baseUrl}/bills/$billId');
        final auth = base64Encode(utf8.encode('${BillplzConfig.apiKey}:'));
        final response = await http.get(
          url,
          headers: {'Authorization': 'Basic $auth'},
        );
        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
      }
      rethrow;
    }
  }

  // Delete/Cancel Bill (Optional)
  static Future<void> deleteBill(String billId) async {
    try {
      final url = Uri.parse('${BillplzConfig.baseUrl}/bills/$billId');
      final auth = base64Encode(utf8.encode('${BillplzConfig.apiKey}:'));

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Basic $auth',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete bill: ${response.body}');
      }
    } catch (e) {
      throw Exception('Bill deletion error: $e');
    }
  }

  /// Create Payout in Billplz (Automated Transfer)
  /// bankCode examples: MAYB2UM2, CIMB0204, etc.
  static Future<Map<String, dynamic>> createPayout({
    required String bankCode,
    required String bankAccountNumber,
    required String name,
    required double amount, // in MYR
    required String description,
    String? identityNumber,
  }) async {
    try {
      print("Calling Supabase Edge Function 'create_payout_billplz'...");

      // Use Supabase Edge Function to avoid CORS and hide API keys
      final response = await Supabase.instance.client.functions.invoke(
        'create_payout_billplz',
        body: {
          'bankCode': bankCode,
          'bankAccountNumber': bankAccountNumber,
          'name': name,
          'amount': (amount * 100).toInt(), // Convert to cents
          'description': description,
          'identityNumber': identityNumber,
          'isSandbox': BillplzConfig.isSandbox,
        },
      );

      if (response.status == 200) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception(
            'Failed to create payout via Edge Function: ${response.data}');
      }
    } catch (e) {
      print("PaymentService Payout Edge Function Exception: $e");

      // Fallback for direct call (only if Function fails or not deployed yet)
      if (!kIsWeb) {
        print("Attempting fallback to direct Payout API call (Native only)...");
        return _createPayoutDirect(
          bankCode: bankCode,
          bankAccountNumber: bankAccountNumber,
          name: name,
          amount: amount,
          description: description,
          identityNumber: identityNumber,
        );
      }

      rethrow;
    }
  }

  // Fallback Direct Payout API call
  static Future<Map<String, dynamic>> _createPayoutDirect({
    required String bankCode,
    required String bankAccountNumber,
    required String name,
    required double amount,
    required String description,
    String? identityNumber,
  }) async {
    // Billplz Mass Payment Endpoint
    final url =
        Uri.parse('${BillplzConfig.baseUrl}/mass_payment_instructions');
    final auth = base64Encode(utf8.encode('${BillplzConfig.apiKey}:'));

    final Map<String, dynamic> body = {
      'bank_code': bankCode,
      'bank_account_number': bankAccountNumber,
      'name': name,
      'amount': (amount * 100).toInt().toString(),
      'description': description,
    };

    if (identityNumber != null) {
      body['identity_number'] = identityNumber;
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body.map((key, value) => MapEntry(key, value.toString())),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create payout (Direct): ${response.body}');
    }
  }

  // Create Invoice in Xendit
  static Future<Map<String, dynamic>> createXenditInvoice({
    required String email,
    required String name,
    required double amount,
    required String currency,
    required String externalId,
    required String description,
    required String redirectUrl,
    Map<String, dynamic>? metadata,
  }) async {
    // Validate currency - throw error if PHP
    if (currency.toUpperCase() == 'PHP') {
      throw ArgumentError('PHP currency is not supported for payments.');
    }

    try {
      print("Calling Supabase Edge Function 'create-xendit-invoice'...");
      
      // Use Supabase Edge Function to avoid CORS and hide API keys
      final response = await Supabase.instance.client.functions.invoke(
        'create-xendit-invoice',
        body: {
          'email': email,
          'payer_email': email,
          'name': name,
          'amount': amount,
          'currency': currency.toUpperCase(),
          'externalId': externalId,
          'external_id': externalId,
          'description': description,
          'redirectUrl': redirectUrl,
          'redirect_url': redirectUrl,
          'success_redirect_url': redirectUrl,
          'metadata': metadata,
        },
      );
      
      print("Edge Function Response Status: ${response.status}");
      print("Edge Function Response Data: ${response.data}");

      if (response.status == 200) {
         return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to create Xendit invoice via Edge Function: ${response.data}');
      }

    } catch (e) {
      print("PaymentService Xendit Edge Function Exception: $e");
      
      // Fallback for direct call (only if Function fails or not deployed yet)
      if (!kIsWeb) {
         print("Attempting fallback to direct Xendit API call (Native only)...");
         return _createXenditInvoiceDirect(
           email: email,
           name: name,
           amount: amount,
           currency: currency,
           externalId: externalId,
           description: description,
           redirectUrl: redirectUrl,
           metadata: metadata,
         );
      }
      
      rethrow;
    }
  }

  // Fallback Direct Xendit API call
  static Future<Map<String, dynamic>> _createXenditInvoiceDirect({
    required String email,
    required String name,
    required double amount,
    required String currency,
    required String externalId,
    required String description,
    required String redirectUrl,
    Map<String, dynamic>? metadata,
  }) async {
      final url = Uri.parse('${XenditConfig.baseUrl}/v2/invoices');
      final auth = base64Encode(utf8.encode('${XenditConfig.apiKey}:'));
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'external_id': externalId,
          'amount': amount,
          'payer_email': email,
          'description': description,
          'customer': {
            'given_names': name,
            'email': email,
          },
          'currency': currency.toUpperCase(),
          'success_redirect_url': redirectUrl,
          'failure_redirect_url': redirectUrl,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create Xendit invoice (Direct): ${response.body}');
      }
  }

  // Check Xendit Invoice Status
  static Future<Map<String, dynamic>> getXenditInvoice(String invoiceId) async {
    try {
      print("Calling Supabase Edge Function 'create-xendit-invoice' with action 'get_status'...");
      
      final response = await Supabase.instance.client.functions.invoke(
        'create-xendit-invoice',
        body: {
          'action': 'get_status',
          'invoiceId': invoiceId,
          'invoice_id': invoiceId,
          'external_id': invoiceId,
          'amount': 0,
        },
      );
      
      if (response.status == 200 && response.data != null) {
         return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to check Xendit invoice status via Edge Function: ${response.data}');
      }
    } catch (e) {
      print("Edge Function getXenditInvoice status check failed: $e. Attempting fallback...");
      if (!kIsWeb) {
        try {
          final url = Uri.parse('${XenditConfig.baseUrl}/v2/invoices/$invoiceId');
          final auth = base64Encode(utf8.encode('${XenditConfig.apiKey}:'));
          final response = await http.get(
            url,
            headers: {'Authorization': 'Basic $auth'},
          );
          if (response.statusCode == 200) {
            return json.decode(response.body);
          }
        } catch (directError) {
          print("Direct Xendit status fallback failed: $directError");
        }
      }
      rethrow;
    }
  }
}