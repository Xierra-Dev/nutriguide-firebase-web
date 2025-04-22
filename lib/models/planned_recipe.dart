import 'recipe.dart';

class PlannedMeal {
  final Recipe recipe;
  final String mealType;
  final String dateKey;
  final DateTime date;  // Add this line

  PlannedMeal({
    required this.recipe,
    required this.mealType,
    required this.dateKey,
    required this.date,  // Add this line
  });
}