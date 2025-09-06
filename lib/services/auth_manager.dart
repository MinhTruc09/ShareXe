import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class AuthManager {
  // Singleton pattern
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  // SharedPreferences keys
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';
  static const String _roleKey = 'user_role';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _emailKey = 'user_email';
  static const String _tokenExpiryKey = 'token_expiry';

  // In-memory cache
  String? _cachedToken;
  Map<String, dynamic>? _cachedClaims;
  DateTime? _cachedTokenExpiry;
  String? _cachedRole;
  String? _cachedEmail;
  String? _cachedUsername;
  bool? _cachedIsLoggedIn;

  // Token refresh lock
  final _refreshLock = Lock();

  // Save auth data after successful login
  Future<void> saveAuthData(
    String token,
    String username,
    String role, {
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_roleKey, role);
    await prefs.setBool(_isLoggedInKey, true);

    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }

    // Extract claims from token
    final claims = parseJwt(token);
    if (claims != null) {
      // Save user email
      if (claims['sub'] != null) {
        await prefs.setString(_emailKey, claims['sub']);
      }

      // Save token expiry
      if (claims['exp'] != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(
          claims['exp'] * 1000,
        );
        await prefs.setString(_tokenExpiryKey, expiry.toIso8601String());
      }
    }

    // Update in-memory cache
    _cachedToken = token;
    _cachedClaims = claims;
    _cachedRole = role;
    _cachedIsLoggedIn = true;

    if (claims != null && claims['sub'] != null) {
      _cachedEmail = claims['sub'];
    }

    if (claims != null && claims['exp'] != null) {
      _cachedTokenExpiry = DateTime.fromMillisecondsSinceEpoch(
        claims['exp'] * 1000,
      );
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    // Use cached value if available
    if (_cachedIsLoggedIn != null) {
      return _cachedIsLoggedIn!;
    }

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    // Cache the result
    _cachedIsLoggedIn = isLoggedIn;

    return isLoggedIn;
  }

  // Get stored token
  Future<String?> getToken() async {
    // Use cached token if available
    if (_cachedToken != null) {
      return _cachedToken;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    // Cache the token
    if (token != null) {
      _cachedToken = token;

      // Also cache the claims
      _cachedClaims = parseJwt(token);

      // Parse expiry
      if (_cachedClaims != null && _cachedClaims!['exp'] != null) {
        _cachedTokenExpiry = DateTime.fromMillisecondsSinceEpoch(
          _cachedClaims!['exp'] * 1000,
        );
      }
    }

    return token;
  }

  // Added alias for getToken to maintain compatibility with NotificationService
  Future<String?> getAccessToken() async {
    return getToken();
  }

  // Get refresh token if available
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Get stored username
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Get stored user email (optimized)
  Future<String?> getUserEmail() async {
    // Use cached email if available
    if (_cachedEmail != null) {
      return _cachedEmail;
    }

    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString(_emailKey);

    // If email not found in preferences, try to extract it from token
    if (email == null) {
      // Get cached claims or parse from token
      Map<String, dynamic>? claims = _cachedClaims;
      if (claims == null) {
        final token = await getToken();
        if (token != null) {
          claims = parseJwt(token);
          _cachedClaims = claims;
        }
      }

      if (claims != null && claims['sub'] != null) {
        email = claims['sub'] as String;
        // Save for future use
        await prefs.setString(_emailKey, email);
        _cachedEmail = email;
      }
    } else {
      _cachedEmail = email;
    }

    return email;
  }

  // Get stored user role (optimized)
  Future<String?> getUserName() async {
    // Use cached username if available
    if (_cachedUsername != null) {
      return _cachedUsername;
    }

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);

    if (username != null) {
      _cachedUsername = username;
    }

    return username;
  }

  Future<String?> getUserRole() async {
    // Use cached role if available
    if (_cachedRole != null) {
      return _cachedRole;
    }

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_roleKey);

    // Cache the role
    _cachedRole = role;

    return role;
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
      'tokenExpiry': prefs.getString(_tokenExpiryKey),
    };
  }

  // Clear auth data on logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.setBool(_isLoggedInKey, false);

    // Clear cache
    _cachedToken = null;
    _cachedClaims = null;
    _cachedTokenExpiry = null;
    _cachedRole = null;
    _cachedEmail = null;
    _cachedIsLoggedIn = false;
  }

  // Extract token claims (optimized)
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

  // Check if token is expired (optimized)
  bool isTokenExpired(String token) {
    // Use cached expiry if available for this token
    if (_cachedToken == token && _cachedTokenExpiry != null) {
      return DateTime.now().isAfter(_cachedTokenExpiry!);
    }

    final claims = parseJwt(token);
    if (claims == null) return true;

    final expiry = claims['exp'];
    if (expiry == null) return true;

    // JWT exp is in seconds since epoch, DateTime.now() is in milliseconds
    final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(expiry * 1000);
    return DateTime.now().isAfter(expiryDateTime);
  }

  // Get token expiration time
  Future<DateTime?> getTokenExpiry() async {
    // Use cached expiry if available
    if (_cachedTokenExpiry != null) {
      return _cachedTokenExpiry;
    }

    final token = await getToken();
    if (token == null) return null;

    final claims = _cachedClaims ?? parseJwt(token);
    if (claims == null) return null;

    final expiry = claims['exp'];
    if (expiry == null) return null;

    final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(expiry * 1000);
    _cachedTokenExpiry = expiryDateTime;

    return expiryDateTime;
  }

  // Time until token expires (returns duration in seconds, negative if expired)
  Future<int> getTimeUntilExpiry() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return 0;

    final now = DateTime.now();
    return expiry.difference(now).inSeconds;
  }

  // Validate current session (optimized)
  Future<bool> validateSession() async {
    if (!await isLoggedIn()) {
      return false;
    }

    final token = await getToken();
    if (token == null) {
      return false;
    }

    // Check expiration from memory or parse token
    bool valid;
    if (_cachedTokenExpiry != null) {
      valid = DateTime.now().isBefore(_cachedTokenExpiry!);
    } else {
      valid = !isTokenExpired(token);
    }

    return valid;
  }

  // Check and print if token is valid, with verbose flag
  Future<bool> checkAndPrintTokenValidity({bool verbose = true}) async {
    final token = await getToken();

    if (token == null) {
      if (verbose) debugPrint('No token stored in SharedPreferences');
      return false;
    }

    if (verbose) {
      debugPrint(
        'Token found: ${token.length > 30 ? token.substring(0, 30) + '...' : token}',
      );
    }

    try {
      // Use cached claims if available
      Map<String, dynamic>? claims = _cachedClaims ?? parseJwt(token);
      if (claims == null) {
        if (verbose) debugPrint('Could not parse token - invalid format');
        return false;
      }

      if (verbose) {
        debugPrint('Token subject: ${claims['sub']}');
        debugPrint('Token role: ${claims['role']}');
      }

      final exp = claims['exp'];
      if (exp != null) {
        final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final now = DateTime.now();
        final isExpired = now.isAfter(expiryDateTime);

        if (verbose) {
          debugPrint('Token expires: $expiryDateTime');
          debugPrint('Current time: $now');
          debugPrint(isExpired ? 'Token is EXPIRED' : 'Token is VALID');

          // Calculate time difference
          final difference = expiryDateTime.difference(now);
          if (!isExpired) {
            debugPrint(
              'Token expires in: ${difference.inHours}h ${difference.inMinutes % 60}m ${difference.inSeconds % 60}s',
            );
          } else {
            debugPrint(
              'Token expired: ${-difference.inHours}h ${-difference.inMinutes % 60}m ${-difference.inSeconds % 60}s ago',
            );
          }
        }

        return !isExpired;
      } else {
        if (verbose) debugPrint('Token has no expiration claim');
        return false;
      }
    } catch (e) {
      if (verbose) debugPrint('Error checking token: $e');
      return false;
    }
  }
}

// Simple lock class for token refresh
class Lock {
  Completer<void>? _completer;

  bool get isLocked => _completer != null;

  Future<T> synchronized<T>(Future<T> Function() function) async {
    if (_completer != null) {
      await _completer!.future;
      return synchronized(function);
    }

    _completer = Completer<void>();
    try {
      final result = await function();
      _completer!.complete();
      _completer = null;
      return result;
    } catch (e) {
      _completer!.complete();
      _completer = null;
      rethrow;
    }
  }
}
