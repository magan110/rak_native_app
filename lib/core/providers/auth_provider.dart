import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';

/// Centralized auth state holder using ChangeNotifier.
///
/// This class replaces the static ValueNotifier<int> hack in AuthManager
/// with a proper reactive state pattern. Currently used via AuthManager
/// as a bridge (AuthManager delegates to this). Once `provider` is added
/// to pubspec.yaml, wrap the app with ChangeNotifierProvider<AuthProvider>
/// and migrate screens from AuthManager.xxx to context.watch<AuthProvider>().xxx.
///
/// Migration path:
/// 1. [DONE] Create AuthProvider with same API as AuthManager
/// 2. [DONE] Make AuthManager delegate to AuthProvider
/// 3. [TODO] Add provider: ^6.1.0 to pubspec.yaml
/// 4. [TODO] Wrap App with ChangeNotifierProvider<AuthProvider>
/// 5. [TODO] Gradually replace AuthManager.currentUser with context.watch<AuthProvider>().currentUser
/// 6. [TODO] Remove AuthManager once all consumers migrated
class AuthProvider extends ChangeNotifier {
  UserData? _currentUser;
  String? _authToken;

  // --- Getters ---
  UserData? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isLoggedIn => _currentUser != null;

  // --- Setters ---
  void setUser(UserData userData, {String? token}) {
    _currentUser = userData;
    _authToken = token;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    _authToken = null;
    notifyListeners();
  }

  // --- Role / Page checks ---
  bool hasRole(String role) => _currentUser?.hasRole(role) ?? false;
  bool hasPage(String page) => _currentUser?.hasPage(page) ?? false;
  bool hasAnyRole(List<String> roles) => _currentUser?.hasAnyRole(roles) ?? false;
  bool hasAnyPage(List<String> pages) => _currentUser?.hasAnyPage(pages) ?? false;

  // --- Convenience getters ---
  List<String> get userRoles => _currentUser?.roles ?? [];
  List<String> get userPages => _currentUser?.pages ?? [];
  String get userName => _currentUser?.emplName ?? '';
  String get userAreaCode => _currentUser?.areaCode ?? '';
  String get userDeptCode => _currentUser?.deptCode ?? '';
  String get userId => _currentUser?.userID ?? '';
}
