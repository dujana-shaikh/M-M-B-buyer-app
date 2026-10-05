import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants/enums.dart';
import '../models/app_user.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';

class ApiAuthRepository {
  ApiAuthRepository(this._client);
  final MmbApiClient _client;

  final _userController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  String? _savedToken;

  AppUser? get currentUser => _currentUser;
  String? get currentToken => _savedToken;

  Stream<AppUser?> authStateChanges() => _userController.stream;
  Stream<AppUser?> authChanges() => _userController.stream;

  Stream<AppUser?> userStream(String uid) {
    if (_currentUser != null && _currentUser!.uid == uid) {
      return Stream.value(_currentUser);
    }
    return _userController.stream.where((u) => u == null || u.uid == uid);
  }

  /// Register user with role (buyer or seller)
  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? shopName,
    String? city,
    String? area,
    String? whatsapp,
  }) async {
    final body = {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'role': role.name,
      if (shopName != null && shopName.trim().isNotEmpty) 'shopName': shopName.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (area != null && area.trim().isNotEmpty) 'area': area.trim(),
    };

    final res = await _client.post(MmbApiConfig.register, body: body);
    final token = res['token'] as String?;
    if (token != null) {
      _savedToken = token;
      _client.setAuthToken(token);
    }

    final userMap = res['user'] is Map ? Map<String, dynamic>.from(res['user'] as Map) : <String, dynamic>{};
    final user = AppUser.fromMap(userMap);
    _currentUser = user;
    _userController.add(user);
    return user;
  }

  /// Login with emailOrPhone and password
  Future<AppUser> signIn(String emailOrPhone, String password) async {
    final body = {
      'emailOrPhone': emailOrPhone.trim(),
      'password': password,
    };

    final res = await _client.post(MmbApiConfig.login, body: body);
    final token = res['token'] as String?;
    if (token != null) {
      _savedToken = token;
      _client.setAuthToken(token);
    }

    // After login, fetch complete profile if needed
    AppUser user;
    if (token != null) {
      try {
        user = await getMe();
      } catch (_) {
        final userMap = res['user'] is Map ? Map<String, dynamic>.from(res['user'] as Map) : <String, dynamic>{};
        user = AppUser.fromMap(userMap);
      }
    } else {
      final userMap = res['user'] is Map ? Map<String, dynamic>.from(res['user'] as Map) : <String, dynamic>{};
      user = AppUser.fromMap(userMap);
    }

    _currentUser = user;
    _userController.add(user);
    return user;
  }

  /// Get current user profile (GET /api/auth/me)
  Future<AppUser> getMe() async {
    final res = await _client.get(MmbApiConfig.me);
    final userMap = res is Map ? Map<String, dynamic>.from(res) : <String, dynamic>{};
    final user = AppUser.fromMap(userMap);
    _currentUser = user;
    _userController.add(user);
    return user;
  }

  Future<void> sendPasswordReset(String email) async {
    // API endpoint or fallback message
    debugPrint('[ApiAuth] Password reset requested for $email');
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    if (_currentUser != null) {
      final updatedMap = _currentUser!.toMap()..addAll(data);
      _currentUser = AppUser.fromMap(updatedMap);
      _userController.add(_currentUser);
    }
  }

  Future<void> signOut() async {
    _savedToken = null;
    _client.clearAuthToken();
    _currentUser = null;
    _userController.add(null);
  }

  static String message(Object e) {
    if (e is ApiException) {
      if (e.message.isNotEmpty) return e.message;
    }
    final s = e.toString().toLowerCase();
    if (s.contains('network') || s.contains('connection refused') || s.contains('socketexception')) {
      return 'Cannot reach backend server. Please verify the API is running at ${MmbApiConfig.baseUrl}.';
    }
    return e.toString();
  }
}
