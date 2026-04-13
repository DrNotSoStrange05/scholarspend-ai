import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  int? _userId;
  String? _userName;
  bool _isLoading = false;
  String? _error;

  int? get userId => _userId;
  String? get userName => _userName;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _userId != null;

  Future<bool> register(String name, double initialBalance) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createUser(name, initialBalance);
      _userId = response['id'] as int;
      _userName = response['name'] as String;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Verify user exists by fetching user data
      final user = await _apiService.getUser(userId);
      _userId = user['id'] as int;
      _userName = user['name'] as String;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _userId = null;
    _userName = null;
    _error = null;
    notifyListeners();
  }
}
