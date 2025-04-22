import 'dart:math';

class Recipe {
  final String id;
  final String title;
  final String image;
  final String? category;
  final String? area;
  final List<String>? tags;
  final List<String> ingredients;
  final List<String> measurements;
  final String instructions;
  final List<String> instructionSteps;
  final int preparationTime;
  final double healthScore;
  final NutritionInfo nutritionInfo;
  final int popularity;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.title,
    required this.image,
    this.category,
    this.area,
    this.tags,
    required this.ingredients,
    required this.measurements,
    required this.instructions,
    required this.instructionSteps,
    required this.preparationTime,
    required this.healthScore,
    required this.nutritionInfo,
    DateTime? createdAt,
    this.popularity = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Recipe.fromTheMealDB(Map<String, dynamic> json) {
    List<String> ingredients = [];
    List<String> measurements = [];

    for (int i = 1; i <= 20; i++) {
      String? ingredient = json['strIngredient$i'];
      String? measure = json['strMeasure$i'];

      if (ingredient != null && ingredient.trim().isNotEmpty) {
        ingredients.add(ingredient.trim());
        measurements.add(measure?.trim() ?? '');
      }
    }

    List<String> parseInstructions(String instructions) {
      return instructions
          .split('\r\n')
          .where((step) => step.trim().isNotEmpty)
          .map((step) => step.trim())
          .toList();
    }

    final nutritionInfo = NutritionInfo.generateRandom();
    final healthScore = _calculateHealthScore(nutritionInfo, ingredients);

    return Recipe(
      id: json['idMeal'] ?? '',
      title: json['strMeal'] ?? '',
      image: json['strMealThumb'] ?? '',
      category: json['strCategory'],
      area: json['strArea'],
      tags: json['strTags'] != null ? json['strTags'].split(',') : [],
      ingredients: ingredients,
      measurements: measurements,
      instructions: json['strInstructions'] ?? '',
      instructionSteps: parseInstructions(json['strInstructions'] ?? ''),
      preparationTime: Random().nextInt(30) + 15,
      healthScore: healthScore,
      nutritionInfo: nutritionInfo,
    );
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      title: map['title'],
      image: map['image'],
      category: map['category'],
      area: map['area'],
      instructions: map['instructions'],
      ingredients: List<String>.from(map['ingredients']),
      measurements: List<String>.from(map['measurements']),
      preparationTime: map['preparationTime'],
      healthScore: map['healthScore'].toDouble(),
      instructionSteps: map['instructions'].split('\n'),
      nutritionInfo: NutritionInfo.generateRandom(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'category': category,
      'area': area,
      'instructions': instructions,
      'ingredients': ingredients,
      'measurements': measurements,
      'preparationTime': preparationTime,
      'healthScore': healthScore,
    };
  }

  static double _calculateHealthScore(
      NutritionInfo nutritionInfo, List<String> ingredients) {
    double score = 5.0; // Start with a base score of 5

    // Adjust score based on nutrition info
    score += (nutritionInfo.protein / nutritionInfo.calories) * 10;
    score += (nutritionInfo.fiber / nutritionInfo.calories) * 15;
    score -= (nutritionInfo.saturatedFat / nutritionInfo.calories) * 10;
    score -= (nutritionInfo.sugars / nutritionInfo.calories) * 5;

    // Bonus for vegetables and fruits
    final healthyIngredients = [
      'vegetable',
      'fruit',
      'leafy',
      'berry',
      'nuts',
      'seed',
      'grain',
      'legume'
    ];
    for (var ingredient in ingredients) {
      if (healthyIngredients
          .any((healthy) => ingredient.toLowerCase().contains(healthy))) {
        score += 0.5;
      }
    }

    // Ensure the score is between 0 and 10
    return max(0, min(10, score));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'category': category,
      'area': area,
      'instructions': instructions,
      'ingredients': ingredients,
      'measurements': measurements,
      'preparationTime': preparationTime,
      'healthScore': healthScore,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      category: json['category'],
      area: json['area'],
      instructions: json['instructions'],
      ingredients: List<String>.from(json['ingredients']),
      measurements: List<String>.from(json['measurements']),
      preparationTime: json['preparationTime'],
      healthScore: json['healthScore'].toDouble(),
      instructionSteps: json['instructions'].split('\n'),
      nutritionInfo: NutritionInfo.generateRandom(),
    );
  }
}

class NutritionInfo {
  final int calories;
  final double totalFat;
  final double saturatedFat;
  final double carbs;
  final double sugars;
  final double protein;
  final int sodium;
  final double fiber;
  final double fat;

  NutritionInfo({
    required this.calories,
    required this.totalFat,
    required this.saturatedFat,
    required this.carbs,
    required this.sugars,
    required this.protein,
    required this.sodium,
    required this.fiber,
    required this.fat,
  });

  factory NutritionInfo.generateRandom() {
    final random = Random();
    return NutritionInfo(
      calories: random.nextInt(400) + 200,
      totalFat: random.nextDouble() * 20,
      saturatedFat: random.nextDouble() * 5,
      carbs: random.nextDouble() * 50,
      sugars: random.nextDouble() * 20,
      protein: random.nextDouble() * 30,
      sodium: random.nextInt(500) + 50,
      fiber: random.nextDouble() * 10,
      fat: random.nextDouble() * 20,
    );
  }
}
