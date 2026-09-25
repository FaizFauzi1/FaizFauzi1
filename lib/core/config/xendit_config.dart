import 'package:flutter_dotenv/flutter_dotenv.dart';

class XenditConfig {
  // Replace with your actual Xendit API keys
  static String get apiKey => dotenv.env['XENDIT_API_KEY'] ?? 'xnd_development_YOUR_SANDBOX_SECRET_KEY';
  static String get webhookToken => dotenv.env['XENDIT_WEBHOOK_VERIFICATION_TOKEN'] ?? 'YOUR_XENDIT_WEBHOOK_VERIFICATION_TOKEN';
  
  // Set to true to use Sandbox (uses development keys), false for Production (uses live keys)
  static bool get isSandbox => (dotenv.env['XENDIT_IS_SANDBOX'] ?? 'true').toLowerCase() == 'true'; 
  
  static const String baseUrl = 'https://api.xendit.co';
}
