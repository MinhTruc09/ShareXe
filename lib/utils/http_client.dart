import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_manager.dart';
import 'package:flutter/material.dart';
import 'app_config.dart';
import 'dart:async';

class ApiClient {
  final AuthManager _authManager = AuthManager();
  final AppConfig _appConfig = AppConfig();
  static final ApiClient _instance = ApiClient._internal();
  
  // Create a persistent HTTP client for connection pooling
  final http.Client _httpClient = http.Client();
  
  // Default timeout duration
  final Duration _defaultTimeout = const Duration(seconds: 10);

  factory ApiClient({String? baseUrl}) {
    if (baseUrl != null) {
      _instance._appConfig.updateBaseUrl(baseUrl);
    }
    return _instance;
  }

  ApiClient._internal();

  String get currentBaseUrl => _appConfig.fullApiUrl;

  // Method to properly close the HTTP client when app is disposed
  void dispose() {
    _httpClient.close();
  }

  // Helper to add auth headers to requests with mandatory token validation
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (!requireAuth) {
      return headers;
    }

    final token = await _authManager.getToken();

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      
      // Validate token expiration
      if (_authManager.isTokenExpired(token)) {
        print('⚠️ WARNING: Token is expired!');
        // TODO: Handle token refresh or re-login
      }
    } else if (requireAuth) {
      throw Exception('Authentication token required but not found');
    }

    return headers;
  }

  // Normalize endpoint to ensure consistent formatting
  String _normalizeEndpoint(String endpoint) {
    return endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
  }

  // Create full URL from endpoint
  Uri _buildUrl(String endpoint) {
    final path = _normalizeEndpoint(endpoint);
    return Uri.parse('${_appConfig.fullApiUrl}/$path');
  }

  // GET request with auth and timeout
  Future<http.Response> get(String endpoint, {
    bool requireAuth = true,
    Duration? timeout,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final url = _buildUrl(endpoint);
      final duration = timeout ?? _defaultTimeout;

      final response = await _httpClient
          .get(url, headers: headers)
          .timeout(duration, onTimeout: () {
            throw TimeoutException('GET request timed out after ${duration.inSeconds}s: $url');
          });

      _logResponse(response);
      return response;
    } catch (e) {
      print('❌ GET Error: $e');
      rethrow;
    }
  }

  // POST request with auth and timeout
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
    Duration? timeout,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final url = _buildUrl(endpoint);
      final duration = timeout ?? _defaultTimeout;

      final response = await _httpClient
          .post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(duration, onTimeout: () {
            throw TimeoutException('POST request timed out after ${duration.inSeconds}s: $url');
          });

      _logResponse(response);
      return response;
    } catch (e) {
      print('❌ POST Error: $e');
      rethrow;
    }
  }

  // PUT request with auth and timeout
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
    Duration? timeout,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final url = _buildUrl(endpoint);
      final duration = timeout ?? _defaultTimeout;

      final response = await _httpClient
          .put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(duration, onTimeout: () {
            throw TimeoutException('PUT request timed out after ${duration.inSeconds}s: $url');
          });

      _logResponse(response);
      return response;
    } catch (e) {
      print('❌ PUT Error: $e');
      rethrow;
    }
  }

  // PATCH request with auth and timeout
  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
    Duration? timeout,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final url = _buildUrl(endpoint);
      final duration = timeout ?? _defaultTimeout;

      final response = await _httpClient
          .patch(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(duration, onTimeout: () {
            throw TimeoutException('PATCH request timed out after ${duration.inSeconds}s: $url');
          });

      _logResponse(response);
      return response;
    } catch (e) {
      print('❌ PATCH Error: $e');
      rethrow;
    }
  }

  // DELETE request with auth and timeout
  Future<http.Response> delete(
    String endpoint, {
    bool requireAuth = true,
    Duration? timeout,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final url = _buildUrl(endpoint);
      final duration = timeout ?? _defaultTimeout;

      final response = await _httpClient
          .delete(url, headers: headers)
          .timeout(duration, onTimeout: () {
            throw TimeoutException('DELETE request timed out after ${duration.inSeconds}s: $url');
          });

      _logResponse(response);
      return response;
    } catch (e) {
      print('❌ DELETE Error: $e');
      rethrow;
    }
  }

  // Log response for debugging
  void _logResponse(http.Response response) {
    final isSuccessful = response.statusCode >= 200 && response.statusCode < 300;
    final responseLength = response.body.length;
    
    // Limit response body logging to avoid memory issues with large responses
    final maxLogLength = 500;
    
    if (isSuccessful) {
      try {
        // Check if the response is HTML (common when receiving error pages)
        if (response.headers['content-type']?.contains('text/html') == true ||
            response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          print('⚠️ Received HTML response instead of JSON');
          print('📄 Response length: $responseLength bytes');
          return;
        }

        // Only try to parse and log if response is not too large
        if (responseLength < 10000) {
          final jsonResponse = jsonDecode(response.body);
          final logStr = jsonEncode(jsonResponse);
          if (logStr.length <= maxLogLength) {
            print('✅ Response: $logStr');
          } else {
            print('✅ Response (truncated): ${logStr.substring(0, maxLogLength)}...');
          }
        } else {
          print('✅ Response is too large to log ($responseLength bytes)');
        }
      } catch (e) {
        print('⚠️ Response is not JSON: $e');
        if (responseLength < maxLogLength) {
          print('📄 Raw response: ${response.body}');
        } else {
          print('📄 Raw response (truncated): ${response.body.substring(0, maxLogLength)}...');
        }
      }
    } else {
      print('❌ Error Response (${response.statusCode}): ${response.body.length > maxLogLength ? response.body.substring(0, maxLogLength) + "..." : response.body}');

      // Check for auth errors
      if (response.statusCode == 401) {
        print('🔒 Authentication error - token might be invalid or expired');
      }
    }
  }

  // Handle auth errors globally
  Future<void> handleAuthError(BuildContext context) async {
    // Clear tokens and redirect to login
    await _authManager.logout();

    // Navigate to login screen
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/login_passenger', (route) => false);
  }

  // Multipart request for file uploads with auth
  Future<http.StreamedResponse> multipartRequest(
    String method,
    String endpoint, {
    Map<String, String>? fields,
    Map<String, dynamic>? files,
    bool requireAuth = true,
    Duration? timeout,
  }) async {
    try {
      final path = _normalizeEndpoint(endpoint);
      final url = Uri.parse('${_appConfig.fullApiUrl}/$path');
      final duration = timeout ?? _defaultTimeout;
      
      final request = http.MultipartRequest(method, url);

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
          final file = entry.value;
          if (file is http.MultipartFile) {
            request.files.add(file);
          }
        }
      }

      // Send request with timeout
      final response = await request.send().timeout(
        duration,
        onTimeout: () {
          throw TimeoutException(
            'Multipart request timed out after ${duration.inSeconds}s: $url',
          );
        },
      );

      print('📡 Multipart Response Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ Multipart Request Error: $e');
      rethrow;
    }
  }
}
