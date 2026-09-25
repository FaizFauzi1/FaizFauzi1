import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: "landing_page/.env.local");
  await Supabase.initialize(
    url: dotenv.env['NEXT_PUBLIC_SUPABASE_URL']!,
    anonKey: dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY']!,
  );
  
  final supabase = Supabase.instance.client;
  try {
    final data = await supabase.from('subscription_tiers').select('*');
    print('SUBSCRIPTION TIERS:');
    print(data);
  } catch (e) {
    print('Error: $e');
  }
}
