import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class RecipeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<Recipe> _recipes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';

  Timer? _debounceTimer;

  List<Recipe> get recipes => _recipes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedDifficulty => _selectedDifficulty;

  // ─── Core fetch ────────────────────────────────────────────────────────────

  Future<void> fetchRecipes({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _recipes = await _apiService.getRecipes(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        difficulty: _selectedDifficulty == 'All' ? null : _selectedDifficulty,
      );
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } on UnauthorizedException {
      await _authService.clearToken();
      _isLoading = false;
      _errorMessage = '__unauthorized__';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // ─── Search (debounced) ────────────────────────────────────────────────────

  void searchRecipes(String query) {
    _searchQuery = query;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      fetchRecipes();
    });
  }

  // ─── Filter ────────────────────────────────────────────────────────────────

  void filterRecipes({String? category, String? difficulty}) {
    if (category != null) _selectedCategory = category;
    if (difficulty != null) _selectedDifficulty = difficulty;
    fetchRecipes();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _selectedDifficulty = 'All';
    fetchRecipes();
  }

  // ─── CRUD ──────────────────────────────────────────────────────────────────

  Future<bool> addRecipe(Map<String, dynamic> data) async {
    try {
      final newRecipe = await _apiService.createRecipe(data);
      _recipes.insert(0, newRecipe);
      notifyListeners();
      return true;
    } on UnauthorizedException {
      await _authService.clearToken();
      _errorMessage = '__unauthorized__';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRecipe(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _apiService.updateRecipe(id, data);
      final index = _recipes.indexWhere((r) => r.id == id);
      if (index != -1) {
        _recipes[index] = updated;
        notifyListeners();
      }
      return true;
    } on UnauthorizedException {
      await _authService.clearToken();
      _errorMessage = '__unauthorized__';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecipe(String id) async {
    try {
      await _apiService.deleteRecipe(id);
      _recipes.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } on UnauthorizedException {
      await _authService.clearToken();
      _errorMessage = '__unauthorized__';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
