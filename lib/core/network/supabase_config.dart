import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Live Supabase Project Credentials (syedom-bsp)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://eujcwszlhxbaeabxxiiu.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1amN3c3psaHhiYWVhYnh4aWl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQwMzg5ODUsImV4cCI6MjEwOTYxNDk4NX0.htAhHoALwUu1jTcPrSmnHdo-Y6NPLLh42Td-XyyvGGM',
  );

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;
  static bool get isMockMode => supabaseUrl.contains('demo-import-engine');

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      if (isMockMode) {
        debugPrint('Supabase initialized in Mock/Local fallback mode.');
        _isInitialized = true;
        return;
      }
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _isInitialized = true;
      debugPrint('Supabase client successfully initialized with $supabaseUrl');
    } catch (e) {
      debugPrint('Supabase initialization fallback to offline/mock: $e');
      _isInitialized = true; // safe fallback
    }
  }
}
