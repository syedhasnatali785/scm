import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Live Supabase Project Credentials (syedom-bsp)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://chldqdflwmhsmvscbxzx.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNobGRxZGZsd21oc212c2NieHp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxODc2ODAsImV4cCI6MjA5NDc2MzY4MH0.FRiWYmJANqV5Shs3XbA3xyR8SQjO7j7VgRKXsKqQDrM',
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

