import 'package:flutter_dotenv/flutter_dotenv.dart';

class BillplzConfig {
  static String get apiKey => dotenv.env['BILLPLZ_API_KEY'] ?? '05af9a09-4b21-4e88-a372-2aeec344d6ed';
  static String get xSignatureKey => dotenv.env['BILLPLZ_X_SIGNATURE_KEY'] ?? '0ce818a1fe2492e63bd096cc83bf1a23a46788f03070c69eed625c5c5bf69c8bde35eea6b0de507dda33eae220c54178b4b02e94445b6c93c23b1b497e98b4a9';
  static String get collectionId => dotenv.env['BILLPLZ_COLLECTION_ID'] ?? 'oflve58n';
  static const String apiUrl = 'https://www.billplz.com/api/v3';
  static const String sandboxApiUrl = 'https://www.billplz-sandbox.com/api/v3';
  
  // Set to true to use Sandbox, false for Production
  static bool get isSandbox => (dotenv.env['BILLPLZ_IS_SANDBOX'] ?? 'true').toLowerCase() == 'true'; 
  
  static String get baseUrl => isSandbox ? sandboxApiUrl : apiUrl;
}
