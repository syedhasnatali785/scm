import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/supabase_config.dart';

@immutable
class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'owner' or 'operator'

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'owner',
  });
}

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  AuthNotifier() : super(const AsyncValue.data(null)) {
    _init();
  }

  void _init() {
    if (!SupabaseConfig.isMockMode && SupabaseConfig.isInitialized) {
      final session = SupabaseConfig.client.auth.currentSession;
      if (session != null) {
        state = AsyncValue.data(AppUser(
          id: session.user.id,
          email: session.user.email ?? '',
          name: session.user.userMetadata?['full_name'] ?? session.user.email?.split('@').first ?? 'User',
          role: session.user.userMetadata?['role'] ?? 'owner',
        ));
      }

      SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          state = AsyncValue.data(AppUser(
            id: session.user.id,
            email: session.user.email ?? '',
            name: session.user.userMetadata?['full_name'] ?? session.user.email?.split('@').first ?? 'User',
            role: session.user.userMetadata?['role'] ?? 'owner',
          ));
        } else {
          state = const AsyncValue.data(null);
        }
      });
    }
  }

  /// Direct Email/Password Sign-In
  Future<void> signInWithEmailPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      if (SupabaseConfig.isMockMode || !SupabaseConfig.isInitialized) {
        // Fast local auth for demo/offline
        await Future.delayed(const Duration(milliseconds: 400));
        state = AsyncValue.data(AppUser(
          id: 'user_local_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          name: email.split('@').first,
          role: 'owner',
        ));
        return;
      }

      final res = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user != null) {
        state = AsyncValue.data(AppUser(
          id: user.id,
          email: user.email ?? email,
          name: user.userMetadata?['full_name'] ?? email.split('@').first,
          role: user.userMetadata?['role'] ?? 'owner',
        ));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Zero-OTP Direct Sign-Up (Email Confirmation Disabled)
  Future<void> signUpZeroOtp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      if (SupabaseConfig.isMockMode || !SupabaseConfig.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 400));
        state = AsyncValue.data(AppUser(
          id: 'user_local_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          name: name.isNotEmpty ? name : email.split('@').first,
          role: 'owner',
        ));
        return;
      }

      final res = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'role': 'owner'},
      );

      final user = res.user;
      if (user != null) {
        state = AsyncValue.data(AppUser(
          id: user.id,
          email: user.email ?? email,
          name: name,
          role: 'owner',
        ));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Google OAuth 2.0 Sign-In
  Future<void> signInWithGoogle() async {
    try {
      if (SupabaseConfig.isMockMode || !SupabaseConfig.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 400));
        state = const AsyncValue.data(AppUser(
          id: 'user_google_mock',
          email: 'executive@71import.com',
          name: 'Executive Owner',
          role: 'owner',
        ));
        return;
      }

      await SupabaseConfig.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.antigravity://login-callback',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      if (!SupabaseConfig.isMockMode && SupabaseConfig.isInitialized) {
        await SupabaseConfig.client.auth.signOut();
      }
    } finally {
      state = const AsyncValue.data(null);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier();
});

