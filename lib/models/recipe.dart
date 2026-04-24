class Recipe {
  final String id;
  final String title;
  final String category;
  final String difficulty;
  final String cookTime;
  final String image;
  final List<String> ingredients;
  final List<String> steps;

  Recipe({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.cookTime,
    required this.image,
    required this.ingredients,
    required this.steps,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      return [];
    }

    return Recipe(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      cookTime: json['cookTime']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      ingredients: parseStringList(json['ingredients']),
      steps: parseStringList(json['steps']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'difficulty': difficulty,
      'cookTime': cookTime,
      'image': image,
      'ingredients': ingredients,
      'steps': steps,
    };
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? category,
    String? difficulty,
    String? cookTime,
    String? image,
    List<String>? ingredients,
    List<String>? steps,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      cookTime: cookTime ?? this.cookTime,
      image: image ?? this.image,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
    );
  }
}
