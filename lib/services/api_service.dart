import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import '../models/auth_response.dart';
import 'auth_service.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized. Please login again.']);

  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'http://192.168.1.8:3000';

  final AuthService _authService = AuthService();

  // ─── Headers ───────────────────────────────────────────────────────────────

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── Response helpers ──────────────────────────────────────────────────────

  /// Throws [UnauthorizedException] on 401, [ApiException] on any other 4xx/5xx.
  void _handleResponseStatus(http.Response response) {
    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }
    if (response.statusCode >= 400) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        message = body['message']?.toString() ?? message;
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
  }

  /// Decodes the response body and unwraps the backend envelope.
  ///
  /// All recipe endpoints return:
  ///   { "success": true, "data": <payload> }
  ///
  /// This helper returns the value at json['data'], falling back to the full
  /// decoded map if 'data' is absent (defensive).
  dynamic _unwrap(http.Response response) {
    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<AuthResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthResponse.fromJson(json.decode(response.body));
    }

    String message = 'Login failed. Check your credentials.';
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      message = body['message']?.toString() ?? message;
    } catch (_) {}
    throw ApiException(message, response.statusCode);
  }

  // ─── Recipes ───────────────────────────────────────────────────────────────

  /// GET /recipes
  /// Backend returns: { "success": true, "count": n, "data": [ ...recipes ] }
  Future<List<Recipe>> getRecipes({
    String? search,
    String? category,
    String? difficulty,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category;
    }
    if (difficulty != null && difficulty.isNotEmpty && difficulty != 'All') {
      queryParams['difficulty'] = difficulty;
    }

    final uri = Uri.parse('$baseUrl/recipes').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(uri, headers: headers);
    _handleResponseStatus(response);

    // Backend wraps the list under 'data': { "data": [...] }
    final data = _unwrap(response);
    if (data is List) {
      return data.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('Unexpected response format from GET /recipes');
  }

  /// GET /recipes/:id
  /// Backend returns: { "success": true, "data": { ...recipe } }
  Future<Recipe> getRecipe(String id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/recipes/$id'),
      headers: headers,
    );
    _handleResponseStatus(response);
    return Recipe.fromJson(_unwrap(response) as Map<String, dynamic>);
  }

  /// POST /recipes
  /// Backend returns: { "success": true, "data": { ...newRecipe } }
  Future<Recipe> createRecipe(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/recipes'),
      headers: headers,
      body: json.encode(data),
    );
    _handleResponseStatus(response);
    return Recipe.fromJson(_unwrap(response) as Map<String, dynamic>);
  }

  /// PUT /recipes/:id
  /// Backend returns: { "success": true, "data": { ...updatedRecipe } }
  Future<Recipe> updateRecipe(String id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/recipes/$id'),
      headers: headers,
      body: json.encode(data),
    );
    _handleResponseStatus(response);
    return Recipe.fromJson(_unwrap(response) as Map<String, dynamic>);
  }

  /// DELETE /recipes/:id
  /// Backend returns: { "success": true, "message": "..." } — no 'data' key.
  /// _handleResponseStatus() is sufficient; nothing to parse.
  Future<void> deleteRecipe(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/recipes/$id'),
      headers: headers,
    );
    _handleResponseStatus(response);
  }
}
