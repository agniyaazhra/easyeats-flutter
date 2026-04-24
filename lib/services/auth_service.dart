import 'package:shared_preferences/shared_preferences.dart';

/// Handles persistence of the JWT auth token using SharedPreferences.
///
/// IMPORTANT: SharedPreferences.getInstance() must only be called after
/// WidgetsFlutterBinding.ensureInitialized() has been called in main().
class AuthService {
  static const String _tokenKey = 'auth_token';

  // ─── Singleton SharedPreferences instance ──────────────────────────────────
  // Caching the instance avoids repeated async lookups and eliminates the
  // subtle race where two concurrent getInstance() calls could return
  // different (stale) platform-channel objects on some Android versions.
  static SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Persists [token] to disk immediately.
  Future<void> saveToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(_tokenKey, token);
  }

  /// Returns the stored token, or null if none is saved.
  Future<String?> getToken() async {
    final prefs = await _getPrefs();
    // Re-read from the cached instance; this is synchronous after first load.
    return prefs.getString(_tokenKey);
  }

  /// Removes the stored token (logout).
  Future<void> clearToken() async {
    final prefs = await _getPrefs();
    await prefs.remove(_tokenKey);
    // Invalidate cache so next getInstance() re-reads from disk.
    _prefs = null;
  }

  /// Returns true if a non-empty token exists on disk.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
