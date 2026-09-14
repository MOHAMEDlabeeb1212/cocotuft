// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - AUTHENTICATION PROVIDER
// ==============================================================================
// Section Purpose: Provider managing state for user authentication, token storage,
// role verification, and login/logout workflows.
// ==============================================================================

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;

  UserModel? _currentUser;
  String? _token;
  List<String> _permissions = [];
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._apiService);

  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser;
  String? get token => _token;
  List<String> get permissions => _permissions;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool hasPermission(String permissionCode) {
    if (_currentUser?.roleName.toUpperCase() == 'ADMIN') return true;
    return _permissions.contains(permissionCode);
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/login', {
        'username': username,
        'password': password,
      });

      _token = response['access_token'];
      _currentUser = UserModel(
        userId: response['user_id'],
        username: response['username'],
        fullName: response['full_name'],
        roleName: response['role_name'],
      );

      if (response['permissions'] != null) {
        _permissions = List<String>.from(response['permissions']);
      } else {
        _permissions = [];
      }

      _apiService.setAuthToken(_token);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _token = null;
    _permissions = [];
    _apiService.setAuthToken(null);
    notifyListeners();
  }
}
