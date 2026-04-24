import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _currentUser = {};

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get currentUser => _currentUser;

  // ─── Startup auth check ──────────────────────────────────────────────────
  // Called once from main() BEFORE runApp(), so SharedPreferences is already
  // initialized. Sets _isLoggedIn synchronously from disk without notifying
  // (there are no listeners yet at that point).
  Future<void> checkAuthStatus() async {
    _isLoggedIn = await _authService.hasToken();
    // No notifyListeners() here — this runs before any widget tree exists.
    // If called later (e.g. after a logout/login cycle), we DO notify.
  }

  // ─── Login ───────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await _apiService.login(email, password);

      // Validate that we actually received a token before persisting.
      if (authResponse.token.isEmpty) {
        throw ApiException('Server returned an empty token. Please try again.');
      }

      // 1. Persist the token to SharedPreferences FIRST.
      await _authService.saveToken(authResponse.token);

      // 2. Then update in-memory state.
      _currentUser = authResponse.user;
      _isLoggedIn = true;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      _isLoggedIn = false;
      notifyListeners();
      return false;
    } catch (e, stack) {
      // Show the REAL error so we can diagnose it — not a generic message.
      final type = e.runtimeType.toString();
      final msg = e.toString();
      debugPrint('✗ LOGIN EXCEPTION [$type]: $msg');
      debugPrint('$stack');
      _errorMessage = '[$type] $msg';
      _isLoading = false;
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────────────
  Future<void> logout() async {
    // Clear disk first, then update state.
    await _authService.clearToken();
    _isLoggedIn = false;
    _currentUser = {};
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
