import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_manager.dart';
import 'package:flutter/material.dart';
import 'app_config.dart';

class ApiClient {
  final AuthManager _authManager = AuthManager();
  final AppConfig _appConfig = AppConfig();
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient({String? baseUrl}) {
    if (baseUrl != null) {
      _instance._appConfig.updateBaseUrl(baseUrl);
    }
    return _instance;
  }

  ApiClient._internal();

  String get currentBaseUrl => _appConfig.fullApiUrl;

  // Helper to add auth headers to requests with mandatory token validation
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _authManager.getToken();

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      print(
        '🔐 Adding auth token: Bearer ${token.length > 20 ? token.substring(0, 20) + '...' : token}',
      );

      // Validate token expiration
      if (_authManager.isTokenExpired(token)) {
        print('⚠️ WARNING: Token is expired!');
        // TODO: Handle token refresh or re-login
      }
    } else if (requireAuth) {
      print('❌ ERROR: Auth token required but not found');
      throw Exception('Authentication token required but not found');
    } else {
      print('⚠️ No auth token available for request');
    }

    print('🔑 Headers: $headers');
    return headers;
  }

  // GET request with auth
  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);

      // Kiểm tra xem endpoint đã bao gồm dấu / ở đầu chưa
      final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
      final url = Uri.parse('${_appConfig.fullApiUrl}/$path');

      print('🔍 GET Request to: $url');
      final response = await http.get(url, headers: headers);

      _logResponse(response);
      return response;
    } catch (e) {
      print('❌ GET Error: $e');
      rethrow;
    }
  }

  // POST request with auth
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);

      // Kiểm tra xem endpoint đã bao gồm dấu / ở đầu chưa
      final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
      final url = Uri.parse('${_appConfig.fullApiUrl}/$path');

      if (body != null) {
        print('📦 Request Body: ${jsonEncode(body)}');
      }

      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      _logResponse(response);
      return response;
    } catch (e) {
      print('❌ POST Error: $e');
      rethrow;
    }
  }

  // PUT request with auth
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);

    // Kiểm tra xem endpoint đã bao gồm dấu / ở đầu chưa
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final url = Uri.parse('${_appConfig.fullApiUrl}/$path');

    print('🌐 API PUT Request: $url');
    print('🔑 Headers: ${headers.toString()}');
    if (body != null) {
      print('📦 Request Body: ${jsonEncode(body)}');
    }

    final response = await http.put(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    _logResponse(response);
    return response;
  }

  // PATCH request with auth
  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);

    // Kiểm tra xem endpoint đã bao gồm dấu / ở đầu chưa
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final url = Uri.parse('${_appConfig.fullApiUrl}/$path');

    print('🌐 API PATCH Request: $url');
    print('🔑 Headers: ${headers.toString()}');
    if (body != null) {
      print('📦 Request Body: ${jsonEncode(body)}');
    }

    final response = await http.patch(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    _logResponse(response);
    return response;
  }

  // DELETE request with auth
  Future<http.Response> delete(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);

    // Kiểm tra xem endpoint đã bao gồm dấu / ở đầu chưa
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final url = Uri.parse('${_appConfig.fullApiUrl}/$path');

    print('🌐 API DELETE Request: $url');
    print('🔑 Headers: ${headers.toString()}');
    final response = await http.delete(url, headers: headers);

    _logResponse(response);
    return response;
  }

  // Log response for debugging
  void _logResponse(http.Response response) {
    print('📡 Response Status: ${response.statusCode}');
    print('📡 Response Headers: ${response.headers}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        // Check if the response is HTML (common when receiving error pages)
        if (response.headers['content-type']?.contains('text/html') == true ||
            response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          print('⚠️ Received HTML response instead of JSON');
          print(
            '📄 Raw response start: ${response.body.substring(0, min(100, response.body.length))}...',
          );
          return;
        }

        final jsonResponse = jsonDecode(response.body);
        print('✅ Response Body: ${jsonEncode(jsonResponse)}');
      } catch (e) {
        print('⚠️ Response is not JSON or is too large to print: $e');
        print(
          '📄 Raw response start: ${response.body.substring(0, min(100, response.body.length))}...',
        );
      }
    } else {
      print('❌ Error Response: ${response.body}');

      // Check for auth errors
      if (response.statusCode == 401) {
        print('🔒 Authentication error - token might be invalid or expired');
      }
    }
  }

  int min(int a, int b) => a < b ? a : b;

  // Handle auth errors globally
  Future<void> handleAuthError(BuildContext context) async {
    // Clear tokens and redirect to login
    await _authManager.logout();

    // Navigate to login screen
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/login_passenger', (route) => false);
  }

  // Multipart request for file uploads with auth
  Future<http.StreamedResponse> multipartRequest(
    String method,
    String endpoint, {
    Map<String, String>? fields,
    Map<String, String>? files,
    bool requireAuth = true,
  }) async {
    // Kiểm tra xem endpoint đã bao gồm dấu / ở đầu chưa
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final request = http.MultipartRequest(
      method,
      Uri.parse('${_appConfig.fullApiUrl}/$path'),
    );

    // Add auth headers
    final headers = await _getHeaders(requireAuth: requireAuth);
    request.headers.addAll(headers);

    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add files
    if (files != null) {
      for (var entry in files.entries) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value),
        );
      }
    }

    print('🌐 API Multipart $method Request: ${_appConfig.fullApiUrl}/$path');
    print('🔑 Headers: ${headers.toString()}');
    return request.send();
  }
}
