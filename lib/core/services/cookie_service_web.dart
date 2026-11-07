// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation of CookieService that interacts with browser cookies
class CookieService {
  static void setCookie(
    String name,
    String value, {
    int maxAgeDays = 30,
    String path = '/',
  }) {
    final maxAgeSeconds = maxAgeDays * 24 * 60 * 60;
    final encodedValue = Uri.encodeComponent(value);
    html.document.cookie =
        '$name=$encodedValue; path=$path; max-age=$maxAgeSeconds; SameSite=Lax';
  }

  static String? getCookie(String name) {
    final cookieString = html.document.cookie;
    if (cookieString == null || cookieString.isEmpty) return null;

    final cookies = cookieString.split(';');
    for (final c in cookies) {
      final parts = c.trim().split('=');
      if (parts.isNotEmpty && parts[0] == name) {
        if (parts.length > 1) {
          return Uri.decodeComponent(parts.sublist(1).join('='));
        }
        return '';
      }
    }
    return null;
  }

  static void removeCookie(String name, {String path = '/'}) {
    html.document.cookie = '$name=; path=$path; max-age=0; SameSite=Lax';
  }

  static Map<String, String> getAllCookies() {
    final cookieString = html.document.cookie;
    final map = <String, String>{};
    if (cookieString == null || cookieString.isEmpty) return map;

    final cookies = cookieString.split(';');
    for (final c in cookies) {
      final parts = c.trim().split('=');
      if (parts.length >= 2) {
        final key = parts[0];
        final val = Uri.decodeComponent(parts.sublist(1).join('='));
        map[key] = val;
      }
    }
    return map;
  }
}

