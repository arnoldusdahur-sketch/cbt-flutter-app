import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AuthService {
  static const _cookieKey = 'session_cookie';
  static const _userKey = 'cached_user';
  static const _csrfKey = 'csrf_token';

  static String _userAgent() {
    return 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
        'Chrome/124.0 Mobile Safari/537.36 ${AppConfig.userAgentSuffix}';
  }

  /// Get CSRF token and session cookie from login page
  static Future<String?> _fetchCsrfToken() async {
    try {
      final resp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/login'),
        headers: {'User-Agent': _userAgent()},
      );

      // Extract CSRF token from HTML
      final html = resp.body;
      final tokenMatch = RegExp(r'name="_token"\s+value="([^"]+)"').firstMatch(html);
      final csrfToken = tokenMatch?.group(1);

      // Extract cookies
      final cookies = resp.headers['set-cookie'] ?? '';

      final prefs = await SharedPreferences.getInstance();
      if (csrfToken != null) {
        await prefs.setString(_csrfKey, csrfToken);
      }
      if (cookies.isNotEmpty) {
        await prefs.setString(_cookieKey, _parseCookies(cookies));
      }

      return csrfToken;
    } catch (e) {
      return null;
    }
  }

  /// Login with email and password
  static Future<LoginResult> login(String email, String password) async {
    try {
      // Step 1: Get CSRF token
      final csrfToken = await _fetchCsrfToken();
      if (csrfToken == null) {
        return LoginResult(success: false, error: 'Gagal menghubungi server. Periksa koneksi internet Anda.');
      }

      final prefs = await SharedPreferences.getInstance();
      final existingCookie = prefs.getString(_cookieKey) ?? '';

      // Step 2: POST login (disabling followRedirects to capture set-cookie on 302 response)
      final client = http.Client();
      final request = http.Request('POST', Uri.parse('${AppConfig.baseUrl}/login'))
        ..followRedirects = false
        ..headers.addAll({
          'User-Agent': _userAgent(),
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': existingCookie,
          'Accept': 'text/html,application/xhtml+xml',
        })
        ..bodyFields = {
          '_token': csrfToken,
          'email': email,
          'password': password,
        };

      final streamedResponse = await client.send(request);
      final resp = await http.Response.fromStream(streamedResponse);

      // Capture new cookies from response
      final newCookies = resp.headers['set-cookie'] ?? '';
      if (newCookies.isNotEmpty) {
        final merged = _mergeCookies(existingCookie, newCookies);
        await prefs.setString(_cookieKey, merged);
      }

      // Check if login was successful (redirect to dashboard = 302)
      if (resp.statusCode == 302) {
        final location = resp.headers['location'] ?? '';
        if (location.contains('dashboard') || location.endsWith('/') || location.contains('home')) {
          // Login success — fetch user data
          await _fetchAndCacheUser();
          return LoginResult(success: true);
        }
      }

      // If we got 200 back, it means login page re-rendered with errors
      if (resp.statusCode == 200 && resp.body.contains('credentials')) {
        return LoginResult(success: false, error: 'Email atau password salah.');
      }

      // Check if it's actually a successful redirect chain
      if (resp.statusCode == 302) {
        await _fetchAndCacheUser();
        return LoginResult(success: true);
      }

      return LoginResult(success: false, error: 'Login gagal. Silakan coba lagi.');
    } catch (e) {
      return LoginResult(success: false, error: 'Kesalahan jaringan: $e');
    }
  }

  /// Fetch dashboard data from API
  static Future<Map<String, dynamic>?> fetchDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString(_cookieKey) ?? '';

      final resp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/dashboard'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        // Cache user data
        if (data.containsKey('user')) {
          await prefs.setString(_userKey, jsonEncode(data['user']));
        }
        return data;
      }

      // Session expired
      if (resp.statusCode == 302 || resp.statusCode == 401) {
        return null;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch E-Books data from API
  static Future<Map<String, dynamic>?> fetchEbooks({String? search, String? category}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString(_cookieKey) ?? '';

      String url = '${AppConfig.baseUrl}/api/mobile/ebooks';
      final params = <String>[];
      if (search != null && search.isNotEmpty) params.add('search=${Uri.encodeComponent(search)}');
      if (category != null && category.isNotEmpty) params.add('category=${Uri.encodeComponent(category)}');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final resp = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch Capaian/Achievements data from API
  static Future<Map<String, dynamic>?> fetchCapaian() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString(_cookieKey) ?? '';

      final resp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/capaian'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch Live Class data from API
  static Future<Map<String, dynamic>?> fetchLiveClass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString(_cookieKey) ?? '';

      final resp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/live-class'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch Kisi-Kisi data from API
  static Future<Map<String, dynamic>?> fetchKisiKisi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString(_cookieKey) ?? '';

      final resp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/kisi-kisi'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch Upgrade Info data from API
  static Future<Map<String, dynamic>?> fetchUpgradeInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString(_cookieKey) ?? '';

      final resp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/upgrade'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch Informations data from API
  static Future<Map<String, dynamic>?> fetchInformations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString(_cookieKey) ?? '';

      final resp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/informations'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Update User Profile via API
  static Future<Map<String, dynamic>?> updateProfile(
    String name,
    String email, {
    String? phone,
    String? address,
    String? password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString(_cookieKey) ?? '';

      final body = {
        'name': name,
        'email': email,
      };
      if (phone != null) body['phone'] = phone;
      if (address != null) body['address'] = address;
      if (password != null && password.isNotEmpty) body['password'] = password;

      final resp = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/profile/update'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['success'] == true && data.containsKey('user')) {
          await prefs.setString(_userKey, jsonEncode(data['user']));
        }
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Check if user is logged in (has valid session)
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString(_cookieKey);
    if (cookie == null || cookie.isEmpty) return false;

    // Verify session by hitting dashboard API
    try {
      final resp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/dashboard'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      return resp.statusCode == 200;
    } catch (e) {
      // Network error — check cached user
      return prefs.getString(_userKey) != null;
    }
  }

  /// Get cached user data
  static Future<Map<String, dynamic>?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Get session cookie for WebView injection
  static Future<String> getSessionCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookieKey) ?? '';
  }

  /// Get ONLY the session cookie value (excluding key name and other cookies like XSRF-TOKEN)
  static Future<String> getSessionCookieValue() async {
    final raw = await getSessionCookie();
    if (raw.isEmpty) return '';
    final pairs = raw.split('; ');
    for (final pair in pairs) {
      final eq = pair.indexOf('=');
      if (eq > 0) {
        final name = pair.substring(0, eq).trim();
        final value = pair.substring(eq + 1).trim();
        if (name.endsWith('-session')) {
          return value;
        }
      }
    }
    return '';
  }

  /// Logout
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString(_cookieKey) ?? '';

      // Try to call logout endpoint
      final csrfToken = prefs.getString(_csrfKey) ?? '';
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/logout'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'_token': csrfToken},
      );
    } catch (_) {}

    // Clear local data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieKey);
    await prefs.remove(_userKey);
    await prefs.remove(_csrfKey);
  }

  static Future<void> _fetchAndCacheUser() async {
    await fetchDashboard(); // This caches user data
  }

  static String _parseCookies(String rawCookies) {
    // Parse Set-Cookie header into a single cookie string
    final parts = rawCookies.split(',');
    final cookies = <String, String>{};
    for (final part in parts) {
      final trimmed = part.trim();
      final nameValue = trimmed.split(';').first.trim();
      final eq = nameValue.indexOf('=');
      if (eq > 0) {
        final name = nameValue.substring(0, eq);
        final value = nameValue.substring(eq + 1);
        cookies[name] = value;
      }
    }
    return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  static String _mergeCookies(String existing, String newRaw) {
    final cookies = <String, String>{};
    // Parse existing
    for (final part in existing.split('; ')) {
      final eq = part.indexOf('=');
      if (eq > 0) {
        cookies[part.substring(0, eq)] = part.substring(eq + 1);
      }
    }
    // Parse new (from Set-Cookie headers)
    final parsed = _parseCookies(newRaw);
    for (final part in parsed.split('; ')) {
      final eq = part.indexOf('=');
      if (eq > 0) {
        cookies[part.substring(0, eq)] = part.substring(eq + 1);
      }
    }
    return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }
}

class LoginResult {
  final bool success;
  final String? error;
  LoginResult({required this.success, this.error});
}
