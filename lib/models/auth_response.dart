class AuthResponse {
  final String token;
  final Map<String, dynamic> user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  /// The backend wraps both login and register responses under a 'data' key:
  ///
  ///   { "success": true, "data": { "token": "eyJ...", "user": { ... } } }
  ///
  /// We unwrap 'data' first, then read 'token' and 'user' from it.
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Support both wrapped { "data": { "token": ... } }
    // and flat          { "token": ... } shapes defensively.
    final payload = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    return AuthResponse(
      token: payload['token']?.toString() ?? '',
      user: payload['user'] is Map
          ? Map<String, dynamic>.from(payload['user'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user,
    };
  }
}
