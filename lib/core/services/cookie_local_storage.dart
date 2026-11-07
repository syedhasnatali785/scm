import 'package:supabase_flutter/supabase_flutter.dart';
import 'cookie_service.dart';

/// Hybrid storage implementing [LocalStorage] that persists the Supabase auth session
/// in both browser cookies (with 30-day lifetime) and Web LocalStorage/SharedPreferences.
///
/// This ensures 100% persistent login state across page reloads, tab navigation,
/// and web deployments.
class CookieLocalStorage extends LocalStorage {
  final SharedPreferencesLocalStorage _prefsStorage;
  final String persistSessionKey;

  CookieLocalStorage({
    required this.persistSessionKey,
  }) : _prefsStorage =
            SharedPreferencesLocalStorage(persistSessionKey: persistSessionKey);

  @override
  Future<void> initialize() async {
    await _prefsStorage.initialize();
  }

  @override
  Future<bool> hasAccessToken() async {
    final cookie = CookieService.getCookie(persistSessionKey);
    if (cookie != null && cookie.isNotEmpty) {
      return true;
    }
    return await _prefsStorage.hasAccessToken();
  }

  @override
  Future<String?> accessToken() async {
    // 1. Check browser cookie first for instant restore
    final cookieVal = CookieService.getCookie(persistSessionKey);
    if (cookieVal != null && cookieVal.isNotEmpty) {
      return cookieVal;
    }

    // 2. Fallback to localStorage / SharedPreferences
    final localVal = await _prefsStorage.accessToken();
    if (localVal != null && localVal.isNotEmpty) {
      // Re-synchronize cookie
      CookieService.setCookie(persistSessionKey, localVal, maxAgeDays: 30);
      return localVal;
    }
    return null;
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    CookieService.setCookie(persistSessionKey, persistSessionString, maxAgeDays: 30);
    await _prefsStorage.persistSession(persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    CookieService.removeCookie(persistSessionKey);
    await _prefsStorage.removePersistedSession();
  }
}

