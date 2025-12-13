import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// API Service with interceptor for Kaluu Express Cargo
/// Handles all API requests with automatic token management
class ApiService {
  // Base URL - Change this to your production URL
  static const String baseUrl = 'http://157.245.227.236'; // Production Server
  // static const String baseUrl = 'http://192.168.1.154:8000'; // For Android Emulator
  // static const String baseUrl = 'http://localhost:8000'; // For iOS Simulator

  static const String apiPrefix = '/api/auth';

  // Secure storage for tokens
  final _storage = const FlutterSecureStorage();

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  // Token management
  String? _accessToken;
  String? _refreshToken;

  // Request timeout
  static const Duration timeout = Duration(seconds: 30);

  /// Initialize API service - Load tokens from storage
  Future<void> init() async {
    _accessToken = await _storage.read(key: _accessTokenKey);
    _refreshToken = await _storage.read(key: _refreshTokenKey);

    if (kDebugMode) {
      print('API Service initialized');
      print('Access Token: ${_accessToken != null ? "Present" : "None"}');
    }
  }

  /// Save authentication tokens
  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);

    if (kDebugMode) {
      print('Tokens saved successfully');
    }
  }

  /// Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _userDataKey, value: jsonEncode(userData));
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final userData = await _storage.read(key: _userDataKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  /// Clear all tokens and user data
  Future<void> clearAuth() async {
    _accessToken = null;
    _refreshToken = null;

    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);

    if (kDebugMode) {
      print('Auth data cleared');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _accessToken != null;

  /// Get access token
  String? get accessToken => _accessToken;

  /// Build headers with authentication
  Map<String, String> _buildHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  /// Refresh access token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) {
      if (kDebugMode) {
        print('No refresh token available');
      }
      return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$apiPrefix/token/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': _refreshToken}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        await _storage.write(key: _accessTokenKey, value: _accessToken!);

        if (kDebugMode) {
          print('Token refreshed successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Token refresh failed: ${response.statusCode}');
        }
        await clearAuth();
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Token refresh error: $e');
      }
      return false;
    }
  }

  /// Handle API response
  /// Handle API response
  ApiResponse _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
    }

    try {
      final data = jsonDecode(response.body);

      // Success case
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(data);
      }

      // Error case - extract error message from various possible formats
      String? errorMessage;

      // Format 1: Direct error field
      if (data['error'] != null) {
        errorMessage = data['error'].toString();
      }
      // Format 2: Message field
      else if (data['message'] != null) {
        errorMessage = data['message'].toString();
      }
      // Format 3: Detail field (common in Django REST Framework)
      else if (data['detail'] != null) {
        errorMessage = data['detail'].toString();
      }
      // Format 4: Email field errors (common for registration)
      else if (data['email'] != null && data['email'] is List) {
        errorMessage = data['email'].first?.toString();
      }
      // Format 5: Phone number field errors
      else if (data['phone_number'] != null && data['phone_number'] is List) {
        errorMessage = data['phone_number'].first?.toString();
      }
      // Format 6: Password field errors
      else if (data['password'] != null && data['password'] is List) {
        errorMessage = data['password'].first?.toString();
      }
      // Format 7: Non-field errors
      else if (data['non_field_errors'] != null &&
          data['non_field_errors'] is List) {
        errorMessage = data['non_field_errors'].first?.toString();
      }
      // Format 8: Generic error message
      else {
        errorMessage = 'Request failed with status ${response.statusCode}';
      }

      return ApiResponse.error(
        errorMessage ?? 'Unknown error',
        statusCode: response.statusCode,
        data: data,
      );
    } catch (e) {
      // If response is not JSON or empty
      return ApiResponse.error(
        response.body.isNotEmpty ? response.body : 'Failed to parse response',
        statusCode: response.statusCode,
      );
    }
  }

  /// Generic GET request
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      if (kDebugMode) {
        print('GET Request: $uri');
      }

      var response = await http
          .get(uri, headers: _buildHeaders(includeAuth: requiresAuth))
          .timeout(timeout);

      // If unauthorized, try to refresh token
      if (response.statusCode == 401 && requiresAuth) {
        if (kDebugMode) {
          print('Unauthorized, attempting token refresh...');
        }

        if (await _refreshAccessToken()) {
          response = await http
              .get(uri, headers: _buildHeaders(includeAuth: requiresAuth))
              .timeout(timeout);
        }
      }

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on TimeoutException {
      return ApiResponse.error('Request timeout');
    } catch (e) {
      if (kDebugMode) {
        print('GET Error: $e');
      }
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Generic POST request
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      if (kDebugMode) {
        print('POST Request: $uri');
        print('Body: $body');
      }

      var response = await http
          .post(
            uri,
            headers: _buildHeaders(includeAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      // If unauthorized, try to refresh token
      if (response.statusCode == 401 && requiresAuth) {
        if (kDebugMode) {
          print('Unauthorized, attempting token refresh...');
        }

        if (await _refreshAccessToken()) {
          response = await http
              .post(
                uri,
                headers: _buildHeaders(includeAuth: requiresAuth),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeout);
        }
      }

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on TimeoutException {
      return ApiResponse.error('Request timeout');
    } catch (e) {
      if (kDebugMode) {
        print('POST Error: $e');
      }
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Generic PUT request
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      if (kDebugMode) {
        print('PUT Request: $uri');
        print('Body: $body');
      }

      var response = await http
          .put(
            uri,
            headers: _buildHeaders(includeAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      // If unauthorized, try to refresh token
      if (response.statusCode == 401 && requiresAuth) {
        if (kDebugMode) {
          print('Unauthorized, attempting token refresh...');
        }

        if (await _refreshAccessToken()) {
          response = await http
              .put(
                uri,
                headers: _buildHeaders(includeAuth: requiresAuth),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeout);
        }
      }

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on TimeoutException {
      return ApiResponse.error('Request timeout');
    } catch (e) {
      if (kDebugMode) {
        print('PUT Error: $e');
      }
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Generic PATCH request
  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      if (kDebugMode) {
        print('PATCH Request: $uri');
        print('Body: $body');
      }

      var response = await http
          .patch(
            uri,
            headers: _buildHeaders(includeAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      // If unauthorized, try to refresh token
      if (response.statusCode == 401 && requiresAuth) {
        if (kDebugMode) {
          print('Unauthorized, attempting token refresh...');
        }

        if (await _refreshAccessToken()) {
          response = await http
              .patch(
                uri,
                headers: _buildHeaders(includeAuth: requiresAuth),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeout);
        }
      }

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on TimeoutException {
      return ApiResponse.error('Request timeout');
    } catch (e) {
      if (kDebugMode) {
        print('PATCH Error: $e');
      }
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Generic DELETE request
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      if (kDebugMode) {
        print('DELETE Request: $uri');
      }

      var response = await http
          .delete(
            uri,
            headers: _buildHeaders(includeAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      // If unauthorized, try to refresh token
      if (response.statusCode == 401 && requiresAuth) {
        if (kDebugMode) {
          print('Unauthorized, attempting token refresh...');
        }

        if (await _refreshAccessToken()) {
          response = await http
              .delete(
                uri,
                headers: _buildHeaders(includeAuth: requiresAuth),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeout);
        }
      }

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on TimeoutException {
      return ApiResponse.error('Request timeout');
    } catch (e) {
      if (kDebugMode) {
        print('DELETE Error: $e');
      }
      return ApiResponse.error('Network error: $e');
    }
  }

  // ==================== Authentication APIs ====================

  /// Register new user
  Future<ApiResponse> register({
    required String email,
    required String fullName,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required String country,
    required String city,
  }) async {
    final response = await post(
      '$apiPrefix/register/',
      body: {
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'password': password,
        'confirm_password': confirmPassword,
        'country': country,
        'city': city,
      },
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final tokens = response.data!['tokens'];
      await _saveTokens(
        accessToken: tokens['access'],
        refreshToken: tokens['refresh'],
      );
      await saveUserData(response.data!['user']);
    }

    return response;
  }

  /// Login user
  Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await post(
      '$apiPrefix/login/',
      body: {'email': email, 'password': password},
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final tokens = response.data!['tokens'];
      await _saveTokens(
        accessToken: tokens['access'],
        refreshToken: tokens['refresh'],
      );
      await saveUserData(response.data!['user']);
    }

    return response;
  }

  /// Logout user
  Future<ApiResponse> logout() async {
    final response = await post(
      '$apiPrefix/logout/',
      body: {'refresh_token': _refreshToken},
    );

    await clearAuth();
    return response;
  }

  /// Get user profile
  Future<ApiResponse> getProfile() async {
    return await get('$apiPrefix/profile/');
  }

  /// Update user profile
  Future<ApiResponse> updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    String? city,
    String? country,
    String? profile_picture,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (address != null) body['address'] = address;
    if (city != null) body['city'] = city;
    if (country != null) body['country'] = country;

    // If no profile picture or profile_picture is not a valid file path, send JSON PATCH
    if (profile_picture == null || profile_picture.isEmpty) {
      return await patch('$apiPrefix/profile/', body: body);
    }

    // If profile_picture looks like a local file path, send multipart/form-data PATCH
    try {
      final file = File(profile_picture);
      if (!file.existsSync()) {
        // If the provided path is not a file, fall back to JSON PATCH including the string value
        body['profile_picture'] = profile_picture;
        return await patch('$apiPrefix/profile/', body: body);
      }

      final uri = Uri.parse('$baseUrl$apiPrefix/profile/');

      if (kDebugMode) {
        print('PATCH Multipart Request: $uri');
        print('Fields: $body');
        print('File: ${file.path}');
      }

      // Build multipart request with PATCH method
      final request = http.MultipartRequest('PATCH', uri);

      // Add auth header only (do not set Content-Type - MultipartRequest will set it)
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }
      request.headers['Accept'] = 'application/json';

      // Add fields
      body.forEach((k, v) => request.fields[k] = v.toString());

      // Add file
      final multipartFile = await http.MultipartFile.fromPath(
        'profile_picture',
        file.path,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      // If unauthorized, try refresh and retry once
      if (response.statusCode == 401 && await _refreshAccessToken()) {
        // retry with refreshed token
        if (_accessToken != null)
          request.headers['Authorization'] = 'Bearer $_accessToken';
        final retryStream = await request.send().timeout(timeout);
        final retryResp = await http.Response.fromStream(retryStream);
        return _handleResponse(retryResp);
      }

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on TimeoutException {
      return ApiResponse.error('Request timeout');
    } catch (e) {
      if (kDebugMode) print('Multipart PATCH error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Change password
  Future<ApiResponse> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await post(
      '$apiPrefix/change-password/',
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
  }

  /// Request password reset
  Future<ApiResponse> requestPasswordReset({required String email}) async {
    return await post(
      '$apiPrefix/password-reset/',
      body: {'email': email},
      requiresAuth: false,
    );
  }

  /// Confirm password reset
  Future<ApiResponse> confirmPasswordReset({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await post(
      '$apiPrefix/password-reset-confirm/',
      body: {
        'token': token,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
      requiresAuth: false,
    );
  }

  /// Verify email
  Future<ApiResponse> verifyEmail({required String token}) async {
    return await post(
      '$apiPrefix/verify-email/',
      body: {'token': token},
      requiresAuth: false,
    );
  }

  /// Resend verification email
  Future<ApiResponse> resendVerificationEmail({required String email}) async {
    return await post(
      '$apiPrefix/resend-verification/',
      body: {'email': email},
      requiresAuth: false,
    );
  }

  /// Get login history
  Future<ApiResponse> getLoginHistory() async {
    return await get('$apiPrefix/login-history/');
  }

  /// Terminate all other sessions (for security)
  Future<ApiResponse> terminateOtherDevices() async {
    return await delete('$apiPrefix/devices/');
  }

  // ==================== Shipping APIs ====================

  /// Get shipping configuration (Service Tiers & Weight Handling)
  Future<ApiResponse> getShippingConfig() async {
    return await get('/api/shipping/config/');
  }

  /// Get user invoices
  Future<ApiResponse> getInvoices() async {
    return await get('/api/shipping/invoices/');
  }

  /// Get all shipments
  Future<ApiResponse> getShipments({Map<String, String>? queryParams}) async {
    return await get('/api/shipping/shipments/', queryParams: queryParams);
  }

  /// Get shipment by tracking code
  Future<ApiResponse> getShipmentByTrackingCode(String trackingCode) async {
    return await get('/api/shipping/shipments/$trackingCode/');
  }
}

/// API Response wrapper class
class ApiResponse {
  final bool isSuccess;
  final String? message;
  final dynamic
  data; // Changed from Map<String, dynamic>? to dynamic to support Lists
  final String? error;
  final int? statusCode;

  ApiResponse.success(this.data, {this.message})
    : isSuccess = true,
      error = null,
      statusCode = 200;

  ApiResponse.error(this.error, {this.statusCode, this.data})
    : isSuccess = false,
      message = null;

  bool get isError => !isSuccess;
}
