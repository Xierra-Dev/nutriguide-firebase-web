class NutritionGoals {
  final double calories;
  final double carbs;
  final double fiber;
  final double protein;
  final double fat;

  NutritionGoals({
    required this.calories,
    required this.carbs,
    required this.fiber,
    required this.protein,
    required this.fat,
  });

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'carbs': carbs,
      'fiber': fiber,
      'protein': protein,
      'fat': fat,
    };
  }

  factory NutritionGoals.fromMap(Map<String, dynamic> map) {
    return NutritionGoals(
      calories: map['calories']?.toDouble() ?? 0.0,
      carbs: map['carbs']?.toDouble() ?? 0.0,
      fiber: map['fiber']?.toDouble() ?? 0.0,
      protein: map['protein']?.toDouble() ?? 0.0,
      fat: map['fat']?.toDouble() ?? 0.0,
    );
  }

  // Default recommended values
  factory NutritionGoals.recommended() {
    return NutritionGoals(
      calories: 1766,
      carbs: 274,
      fiber: 30,
      protein: 79,
      fat: 39,
    );
  }
}