/// Non-web fallback stub for CookieService
class CookieService {
  static final Map<String, String> _memoryCookies = {};

  static void setCookie(
    String name,
    String value, {
    int maxAgeDays = 30,
    String path = '/',
  }) {
    _memoryCookies[name] = value;
  }

  static String? getCookie(String name) {
    return _memoryCookies[name];
  }

  static void removeCookie(String name, {String path = '/'}) {
    _memoryCookies.remove(name);
  }

  static Map<String, String> getAllCookies() {
    return Map.unmodifiable(_memoryCookies);
  }
}

