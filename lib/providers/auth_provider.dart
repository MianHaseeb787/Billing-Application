import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _user;
  bool _isLoading = true; // Start as true for initial auth check
  String? _error;
  bool _isInitialized = false;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null && _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _initAuth();
  }

  // Initialize auth state listener
  void _initAuth() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _user = await _authService.getUserData(firebaseUser.uid);
      } else {
        _user = null;
      }
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(email, password);

      if (_user == null) {
        _error = "Invalid email or password";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!_user!.isActive) {
        await _authService.signOut();
        _user = null;
        _error = "This account has been deactivated";
        _isLoading = false;
        notifyListeners();
        return false;
      }

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

  // Sign up new user
  Future<bool> signUp(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signUp(email, password, name, role);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  // Check if user has specific permission
  bool hasPermission(String permission) {
    return _user?.hasPermission(permission) ?? false;
  }

  // Get all users (admin only)
  Stream<List<AppUser>> getAllUsers() {
    return _authService.getAllUsers();
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _authService.updateUserData(uid, data);
    if (_user?.uid == uid) {
      _user = await _authService.getUserData(uid);
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
