import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  // SharedPreferences keys
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'username';
  static const String _roleKey = 'user_role';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _emailKey = 'user_email';

  // Save auth data after successful login
  Future<void> saveAuthData(String token, String username, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_roleKey, role);
    await prefs.setBool(_isLoggedInKey, true);

    // Extract and save email from token
    final claims = parseJwt(token);
    if (claims != null && claims['sub'] != null) {
      await prefs.setString(_emailKey, claims['sub']);
      print('Email saved: ${claims['sub']}');
    }

    // Print token details for debugging
    print('Token saved: ${token.substring(0, 20)}...');

    // Test token parsing
    if (claims != null) {
      print(
        'Token parsed successfully: subject=${claims['sub']}, role=${claims['role']}',
      );
    } else {
      print('Warning: Could not parse JWT token');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get access token for authentication
  Future<String?> getAccessToken() async {
    return getToken();
  }

  // Get stored username
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Get stored user email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString(_emailKey);

    // If email not found in preferences, try to extract it from token
    if (email == null) {
      final token = await getToken();
      if (token != null) {
        final claims = parseJwt(token);
        if (claims != null && claims['sub'] != null) {
          email = claims['sub'] as String;
          // Save for future use
          await prefs.setString(_emailKey, email);
        }
      }
    }

    return email;
  }

  // Get stored user role
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  // Get all user data
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_usernameKey),
      'role': prefs.getString(_roleKey),
      'token': prefs.getString(_tokenKey),
      'email': prefs.getString(_emailKey),
      'isLoggedIn': prefs.getBool(_isLoggedInKey) ?? false,
    };
  }

  // Clear auth data on logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_emailKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Extract token claims (similar to the JwtUtil in the Java code)
  Map<String, dynamic>? parseJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Get payload part (2nd part of JWT token)
      final payload = parts[1];

      // Base64 decode and convert to string
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));

      // Parse to JSON
      final payloadMap = json.decode(decoded);
      return payloadMap;
    } catch (e) {
      return null;
    }
  }

  // Check if token is expired
  bool isTokenExpired(String token) {
    final claims = parseJwt(token);
    if (claims == null) return true;

    final expiry = claims['exp'];
    if (expiry == null) return true;

    // JWT exp is in seconds since epoch, DateTime.now() is in milliseconds
    final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(expiry * 1000);
    return DateTime.now().isAfter(expiryDateTime);
  }

  // Validate current session
  Future<bool> validateSession() async {
    if (!await isLoggedIn()) return false;

    final token = await getToken();
    if (token == null) return false;

    return !isTokenExpired(token);
  }

  // Check and print if token is valid
  Future<bool> checkAndPrintTokenValidity() async {
    final token = await getToken();

    if (token == null) {
      print('🚫 No token stored in SharedPreferences');
      return false;
    }

    print(
      '🔑 Token found: ${token.length > 30 ? token.substring(0, 30) + '...' : token}',
    );

    try {
      final claims = parseJwt(token);
      if (claims == null) {
        print('❌ Could not parse token - invalid format');
        return false;
      }

      print('👤 Token subject: ${claims['sub']}');
      print('🛡️ Token role: ${claims['role']}');

      final exp = claims['exp'];
      if (exp != null) {
        final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final now = DateTime.now();
        final isExpired = now.isAfter(expiryDateTime);

        print('⏱️ Token expires: $expiryDateTime');
        print('⏱️ Current time: $now');
        print(isExpired ? '❌ Token is EXPIRED' : '✅ Token is VALID');

        // Calculate time difference
        final difference = expiryDateTime.difference(now);
        if (!isExpired) {
          print(
            '⏳ Token expires in: ${difference.inHours}h ${difference.inMinutes % 60}m ${difference.inSeconds % 60}s',
          );
        } else {
          print(
            '⏳ Token expired: ${-difference.inHours}h ${-difference.inMinutes % 60}m ${-difference.inSeconds % 60}s ago',
          );
        }

        return !isExpired;
      } else {
        print('⚠️ Token has no expiration claim');
        return false;
      }
    } catch (e) {
      print('❌ Error checking token: $e');
      return false;
    }
  }
}
