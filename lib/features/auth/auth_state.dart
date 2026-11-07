import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/organization.dart';
import '../../core/network/supabase_config.dart';
import '../../core/services/cookie_service.dart';

@immutable
class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'owner' or 'operator'
  final List<Organization> organizations;
  final Organization? activeOrganization;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'owner',
    this.organizations = const [],
    this.activeOrganization,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    List<Organization>? organizations,
    Organization? activeOrganization,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      organizations: organizations ?? this.organizations,
      activeOrganization: activeOrganization ?? this.activeOrganization,
    );
  }
}

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    if (!SupabaseConfig.isMockMode && SupabaseConfig.isInitialized) {
      final session = SupabaseConfig.client.auth.currentSession;
      if (session != null) {
        final appUser = await _buildAppUser(session.user);
        state = AsyncValue.data(appUser);
      } else {
        // Fallback: check if we have cookies indicating an offline or saved session
        final cookieUserId = CookieService.getCookie('sb-user-id');
        if (cookieUserId != null && cookieUserId.isNotEmpty) {
          final cookieEmail = CookieService.getCookie('sb-user-email') ?? 'owner@71international.com';
          final fallbackUser = _buildFallbackUser(
            id: cookieUserId,
            email: cookieEmail,
            name: cookieEmail.split('@').first,
            hasInitialOrg: true,
          );
          state = AsyncValue.data(fallbackUser);
        } else {
          state = const AsyncValue.data(null);
        }
      }

      // Listen to real-time auth changes across tabs and OAuth redirects
      SupabaseConfig.client.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null) {
          final appUser = await _buildAppUser(session.user);
          if (mounted) {
            state = AsyncValue.data(appUser);
          }
        } else {
          if (mounted) {
            state = const AsyncValue.data(null);
          }
        }
      });
    } else {
      // Mock / Offline mode fallback
      state = const AsyncValue.data(null);
    }
  }

  /// Builds the full multi-tenant [AppUser] by fetching organizations and memberships
  Future<AppUser> _buildAppUser(User user) async {
    final name = user.userMetadata?['full_name'] as String? ??
        user.email?.split('@').first ??
        'User';
    String role = (user.userMetadata?['role'] as String?) ?? 'owner';
    final List<Organization> orgs = [];

    // Save persistent user cookies
    CookieService.setCookie('sb-user-id', user.id, maxAgeDays: 30);
    CookieService.setCookie('sb-user-email', user.email ?? '', maxAgeDays: 30);

    try {
      // 1. Fetch user's organization memberships
      final memberships = await SupabaseConfig.client
          .from('org_memberships')
          .select('role, organizations(*)')
          .eq('user_id', user.id);

      if (memberships.isNotEmpty) {
        for (final m in memberships) {
          final orgData = m['organizations'];
          if (orgData != null && orgData is Map) {
            orgs.add(Organization.fromMap(Map<String, dynamic>.from(orgData)));
          }
          if (m['role'] != null) {
            role = m['role'] as String;
          }
        }
      }

      // 2. If user has no memberships yet, check all organizations
      if (orgs.isEmpty) {
        final allOrgsRes = await SupabaseConfig.client
            .from('organizations')
            .select()
            .order('created_at', ascending: true);

        if (allOrgsRes.isNotEmpty) {
          final firstOrg = Organization.fromMap(
            Map<String, dynamic>.from(allOrgsRes.first as Map),
          );
          orgs.add(firstOrg);

          // Associate user with this organization in org_memberships
          try {
            await SupabaseConfig.client.from('org_memberships').upsert({
              'org_id': firstOrg.id,
              'user_id': user.id,
              'role': role,
            });
          } catch (e) {
            debugPrint('Failed to link initial org_membership: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user organizations: $e');
    }

    // 3. Fallback to cached default org if table query is blocked or offline
    if (orgs.isEmpty) {
      orgs.add(const Organization(
        id: '02337732-6c78-496b-bd95-f10feef8e135',
        name: '71 International Trading',
        slug: '71-international',
        baseCurrency: 'PKR',
        defaultOriginCurrency: 'RMB',
        workflowPreset: 'SKD Assembly',
      ));
    }

    // 4. Resolve active organization from cookie or default to first
    Organization? activeOrg;
    final savedOrgId = CookieService.getCookie('active_org_id');
    if (savedOrgId != null && orgs.any((o) => o.id == savedOrgId)) {
      activeOrg = orgs.firstWhere((o) => o.id == savedOrgId);
    } else if (orgs.isNotEmpty) {
      activeOrg = orgs.first;
      CookieService.setCookie('active_org_id', activeOrg.id, maxAgeDays: 30);
    }

    return AppUser(
      id: user.id,
      email: user.email ?? '',
      name: name,
      role: role,
      organizations: orgs,
      activeOrganization: activeOrg,
    );
  }

  AppUser _buildFallbackUser({
    required String id,
    required String email,
    required String name,
    String role = 'owner',
    bool hasInitialOrg = false,
  }) {
    final List<Organization> orgs = [];
    Organization? activeOrg;
    if (hasInitialOrg) {
      const defaultOrg = Organization(
        id: '02337732-6c78-496b-bd95-f10feef8e135',
        name: '71 International Trading',
        slug: '71-international',
        baseCurrency: 'PKR',
        defaultOriginCurrency: 'RMB',
        workflowPreset: 'SKD Assembly',
      );
      orgs.add(defaultOrg);
      activeOrg = defaultOrg;
      CookieService.setCookie('active_org_id', defaultOrg.id, maxAgeDays: 30);
    }
    return AppUser(
      id: id,
      email: email,
      name: name,
      role: role,
      organizations: orgs,
      activeOrganization: activeOrg,
    );
  }

  /// Switch active tenant organization
  void switchOrganization(String orgId) {
    if (state.value == null) return;
    final user = state.value!;
    final match = user.organizations.where((o) => o.id == orgId);
    if (match.isNotEmpty) {
      final newActive = match.first;
      CookieService.setCookie('active_org_id', newActive.id, maxAgeDays: 30);
      state = AsyncValue.data(user.copyWith(activeOrganization: newActive));
    }
  }

  /// Add new tenant organization to user's portfolio
  void addOrganization(Organization newOrg) {
    if (state.value == null) return;
    final user = state.value!;
    final updatedList = [...user.organizations, newOrg];
    CookieService.setCookie('active_org_id', newOrg.id, maxAgeDays: 30);
    state = AsyncValue.data(user.copyWith(
      organizations: updatedList,
      activeOrganization: newOrg,
    ));
  }

  /// Direct Email/Password Sign-In
  Future<void> signInWithEmailPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      if (SupabaseConfig.isMockMode || !SupabaseConfig.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 300));
        state = AsyncValue.data(_buildFallbackUser(
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
        final appUser = await _buildAppUser(user);
        state = AsyncValue.data(appUser);
      } else {
        throw Exception('User authentication failed: No user returned');
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
        await Future.delayed(const Duration(milliseconds: 300));
        state = AsyncValue.data(_buildFallbackUser(
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
        final appUser = await _buildAppUser(user);
        state = AsyncValue.data(appUser);
      } else {
        throw Exception('Account creation failed: No user returned');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Google OAuth 2.0 Sign-In
  Future<void> signInWithGoogle() async {
    try {
      if (SupabaseConfig.isMockMode || !SupabaseConfig.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 300));
        state = AsyncValue.data(_buildFallbackUser(
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

  /// Sign Out and purge all auth cookies
  Future<void> signOut() async {
    try {
      CookieService.removeCookie('sb-user-id');
      CookieService.removeCookie('sb-user-email');
      CookieService.removeCookie('active_org_id');
      CookieService.removeCookie('sb-session');

      if (!SupabaseConfig.isMockMode && SupabaseConfig.isInitialized) {
        await SupabaseConfig.client.auth.signOut();
      }
    } finally {
      state = const AsyncValue.data(null);
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier();
});

/// Reactive Active Organization Provider derived from authenticated user
final activeOrganizationProvider = Provider<Organization?>((ref) {
  final auth = ref.watch(authProvider).value;
  return auth?.activeOrganization;
});
