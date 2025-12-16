import 'dart:async';

import 'package:flutter/material.dart';
import 'api_service.dart';

/// Authentication Controller using Provider/GetX pattern
/// Manages authentication state throughout the app
class AuthController extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;
  String? get errorMessage => _errorMessage;
  String? get userEmail => _userData?['email'];
  String? get userName => _userData?['full_name'];
  String? get profilePicture {
    final picture = _userData?['profile_picture'];
    if (picture == null || picture.isEmpty) return null;

    // If it's already a full URL, return it as is
    if (picture.startsWith('http://') || picture.startsWith('https://')) {
      return picture;
    }

    // Otherwise, prepend the base URL
    return '${ApiService.baseUrl}$picture';
  }

  String? get phoneNumber => _userData?['phone_number'];
  String? get city => _userData?['city'];
  String? get country => _userData?['country'];
  bool get isCreator =>
      _userData?['is_staff'] == true || _userData?['role'] == 'creator';

  /// Initialize authentication state
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _apiService.init();
    _isAuthenticated = _apiService.isAuthenticated;

    if (_isAuthenticated) {
      _userData = await _apiService.getUserData();

      // Validate token by fetching profile
      final response = await _apiService.getProfile();
      if (response.isSuccess) {
        _userData = response.data?['user'];
        await _apiService.saveUserData(_userData!);
      } else {
        // Token invalid, clear auth
        await logout();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Convert raw API errors into friendly, human-readable messages.
  // String _friendlyErrorMessage(ApiResponse? response, [Object? exception]) {
  //   // Prefer explicit response.error if it's a readable string
  //   try {
  //     if (response != null) {
  //       final raw = response.error;
  //       final data = response.data;
  //      print(data);
  //     if (raw != null && raw.isNotEmpty) {
  //       // Common phrases mapping
  //       final lower = raw.toLowerCase();
  //       if (lower.contains('invalid') && lower.contains('credential')) {
  //         return 'Invalid credentials. Please check your email and password.';
  //       }
  //       //         if (lower.contains('non_field_errors') &&
  //       //     (lower.contains('ErrorDetail') || lower.contains('credential'))) {
  //       //   return 'Your account is blocked due to multiple login attempts. Please contact support.';
  //       // }
  //       if (lower.length >= 5 && lower.substring(0, 5) == "{'non") {
  //         return 'Account is temporarily locked due to multiple failed login attempts. Please try again later.';
  //       }
  //       if (lower.contains('not found')) {
  //         return 'Requested resource was not found.';
  //       }
  //       if (lower.contains('no internet') ||
  //           lower.contains('socketexception')) {
  //         return 'No internet connection. Check your network and try again.';
  //       }
  //       if (lower.contains('timeout') || lower.contains('request timeout')) {
  //         return 'Request timed out. Please check your connection and try again.';
  //       }

  //       // If it's likely already user-friendly, return it
  //       return raw;
  //     }

  //     // If response data has structured errors (e.g., {'email': ['...']})
  //     if (data != null && data is Map) {
  //       // Common key 'detail' or 'message'
  //       if (data['detail'] != null) return _cleanErrorString(data['detail']);
  //       if (data['message'] != null)
  //         return _cleanErrorString(data['message']);

  //       // Field errors: join messages and make keys human-friendly
  //       final buffer = StringBuffer();
  //       data.forEach((key, value) {
  //         if (value == null) return;
  //         final label = _readableKeyLabel(key.toString());

  //         if (value is List) {
  //           final items =
  //               value
  //                   .map((v) => _cleanErrorString(v))
  //                   .where((s) => s.isNotEmpty)
  //                   .toList();

  //           if (label == 'Error') {
  //             buffer.writeln(items.join(' '));
  //           } else {
  //             buffer.writeln('$label: ${items.join(' ')}');
  //           }
  //         } else if (value is Map) {
  //           final inner = <String>[];
  //           value.forEach((k, v) {
  //             if (v is List) {
  //               inner.add(
  //                 '${_readableKeyLabel(k.toString())}: ${v.map((e) => _cleanErrorString(e)).join(' ')}',
  //               );
  //             } else {
  //               inner.add(
  //                 '${_readableKeyLabel(k.toString())}: ${_cleanErrorString(v)}',
  //               );
  //             }
  //           });
  //           buffer.writeln(inner.join(' '));
  //         } else {
  //           if (label == 'Error')
  //             buffer.writeln(_cleanErrorString(value));
  //           else
  //             buffer.writeln('$label: ${_cleanErrorString(value)}');
  //         }
  //       });

  //       final out = buffer.toString().trim();
  //       if (out.isNotEmpty) return out;
  //     }
  //   }
  //   } catch (_) {
  //     // fallthrough to generic messages
  //   }

  //   // if (exception != null) {
  //   //   // Avoid exposing raw exception details to users
  //   //   return 'An unexpected error occurred. Please try again.';
  //   // }

  //   return 'Operation failed. Please try again.';
  // }

  /// Register new user
  Future<bool> register({
    required String email,
    required String fullName,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required String country,
    required String city,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        password: password,
        confirmPassword: confirmPassword,
        country: country,
        city: city,
      );

      if (response.isSuccess) {
        _isAuthenticated = true;
        _userData = response.data?['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _errorMessage
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('.', ' ')
          .replaceAll('{', ' ')
          .replaceAll('}', ' ');
      ;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  int _failedAttempts = 0;
  bool _isLocked = false;

  /// Login user
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response.isSuccess) {
        _isAuthenticated = true;
        _userData = response.data?['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        if (!_isLocked) {
          _failedAttempts += 1;

          String errorMessage;

          if (_failedAttempts >= 5) {
            errorMessage =
                "Your account is temporarily locked due to multiple failed login attempts. Please wait 3 minutes.";
            _isLocked = true;

            // Start a timer to reset after 3 minutes
            Timer(Duration(minutes: 2), () {
              _failedAttempts = 0;
              _isLocked = false;
            });
          } else {
            errorMessage = "Please check your email and password";
          }

          _errorMessage = errorMessage;
          _isLoading = false;
          notifyListeners();
        } else {
          // If user tries during lock
          _errorMessage =
              "Your account is temporarily locked due to multiple failed login attempts. Please wait 3 minutes.";
          _isLoading = false;
          notifyListeners();
        }

        return false;
      }
    } catch (e) {
      _errorMessage = "faild to login";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _apiService.logout();

    _isAuthenticated = false;
    _userData = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Get user profile
  Future<bool> fetchProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getProfile();

      if (response.isSuccess) {
        _userData = response.data?['user'];
        await _apiService.saveUserData(_userData!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error ?? 'Failed to fetch profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = errorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    String? city,
    String? country,
    String? profilePicture,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        city: city,
        country: country,
        profile_picture: profilePicture,
      );

      if (response.isSuccess) {
        _userData = response.data?['user'];
        await _apiService.saveUserData(_userData!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error ?? 'Failed to update profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = errorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _extractBackendError(dynamic data) {
    if (data is Map && data['errors'] is Map && data['errors'].isNotEmpty) {
      final firstErrorList = data['errors'].values.first;
      if (firstErrorList is List && firstErrorList.isNotEmpty) {
        return firstErrorList.first.toString();
      }
    }
    return 'Failed to change password. Please try again.';
  }

  /// Change password
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response.isSuccess) {
        _isLoading = false;
        notifyListeners();

        // Force re-login after password change
        await logout();
        return true;
      } else {
        _errorMessage = response.error ?? 'Failed to change password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = errorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Request password reset
  Future<bool> requestPasswordReset({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.requestPasswordReset(email: email);

      _isLoading = false;
      if (!response.isSuccess) {
        _errorMessage = response.error ?? 'Failed to request password reset';
      }
      notifyListeners();

      return response.isSuccess;
    } catch (e) {
      _errorMessage = 'Password reset request error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Confirm password reset
  Future<bool> confirmPasswordReset({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.confirmPasswordReset(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      _isLoading = false;
      if (!response.isSuccess) {
        _errorMessage = response.error ?? 'Failed to reset password';
      }
      notifyListeners();

      return response.isSuccess;
    } catch (e) {
      _errorMessage = 'Password reset error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
