import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import 'package:nutriguide/services/firestore_service.dart';
import 'dart:math';

class TheMealDBService {
  final String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  final FirestoreService _firestoreService = FirestoreService();
  final Random _random = Random();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> getRandomMealImage() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/random.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['meals'][0]['strMealThumb'] ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<List<String>> getUserAllergies() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot doc =
        await _firestore.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          return List<String>.from(data['allergies'] ?? []);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Recipe>> getRandomRecipes(int number) async {
    try {
      List<Recipe> recipes = [];
      List<String> userAllergies = [];

      try {
        final allergies = await _firestoreService.getUserAllergies();
        if (allergies.isNotEmpty) {
          userAllergies = allergies;
        }
      } catch (e) {
        // Continue without allergies
      }

      int attempts = 0;
      int maxAttempts = number * 3; // Try up to 3 times per requested recipe

      while (recipes.length < number && attempts < maxAttempts) {
        attempts++;
        final response = await http.get(Uri.parse('$_baseUrl/random.php'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['meals'] != null && data['meals'].isNotEmpty) {
            final mealData = data['meals'][0];
            Recipe recipe = await _parseRecipeData(mealData);

            // Check if recipe has all required data and doesn't contain allergic ingredients
            if (_isRecipeComplete(recipe) && !_containsAllergicIngredient(recipe, userAllergies)) {
              recipes.add(recipe);
            }
          }
        } else {
          throw Exception('Failed to load random recipe');
        }
      }

      if (recipes.length < number) {
        // Couldn't find enough non-allergic recipes
      }

      return recipes;
    } catch (e) {
      return [];
    }
  }

  bool _containsAllergicIngredient(Recipe recipe, List<String> allergies) {
    if (allergies.isEmpty) return false;

    for (String ingredient in recipe.ingredients) {
      for (String allergy in allergies) {
        if (ingredient.toLowerCase().contains(allergy.toLowerCase())) {
          return true;
        }
      }
    }
    return false;
  }

  Future<List<Recipe>> getRecipesByCategory(String category, {int limit = 10}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/filter.php?c=$category'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null) return [];

        List<Recipe> recipes = [];
        List<dynamic> meals = data['meals'];

        // Shuffle meals to get random selection
        meals.shuffle();

        // Limit to first 'limit' meals or less
        int count = min(limit, meals.length);
        for (int i = 0; i < count; i++) {
          String mealId = meals[i]['idMeal'];
          Recipe? detailedRecipe = await getRecipeDetails(mealId);
          
          if (detailedRecipe != null && _isRecipeComplete(detailedRecipe)) {
            recipes.add(detailedRecipe);
          }
          
          // If we have enough recipes, break early
          if (recipes.length >= limit) break;
        }
        
        return recipes;
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      return [];
    }
  }

  Future<Recipe?> getRecipeDetails(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/lookup.php?i=$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null || data['meals'].isEmpty) return null;

        return await _parseRecipeData(data['meals'][0]);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Recipe> _parseRecipeData(Map<String, dynamic> mealData) async {
    // Extract ingredients and measurements
    List<String> ingredients = [];
    List<String> measurements = [];

    for (int i = 1; i <= 20; i++) {
      String ingredient = mealData['strIngredient$i'] ?? '';
      String measure = mealData['strMeasure$i'] ?? '';

      if (ingredient.isNotEmpty && ingredient != 'null' && ingredient != ' ') {
        ingredients.add(ingredient);
        measurements.add(measure.isNotEmpty ? measure : 'to taste');
      }
    }

    // Generate a random preparation time between 15 and 60 minutes
    int prepTime = _random.nextInt(46) + 15;

    // Create the recipe object
    return Recipe(
      id: mealData['idMeal'] ?? '',
      title: mealData['strMeal'] ?? '',
      image: mealData['strMealThumb'] ?? '',
      category: mealData['strCategory'] ?? '',
      area: mealData['strArea'] ?? '',
      instructions: mealData['strInstructions'] ?? '',
      instructionSteps: (mealData['strInstructions'] ?? '').split('\n'),
      ingredients: ingredients,
      measurements: measurements,
      preparationTime: prepTime,
      healthScore: _calculateHealthScore(ingredients),
      nutritionInfo: NutritionInfo.generateRandom(),
    );
  }

  double _calculateHealthScore(List<String> ingredients) {
    // This is a simplified scoring system
    // In a real app, you would use a more sophisticated algorithm or API
    
    // List of ingredients considered healthy
    List<String> healthyIngredients = [
      'vegetable', 'vegetables', 'fruit', 'fruits', 'grain', 'grains', 
      'bean', 'beans', 'lentil', 'lentils', 'fish', 'olive oil', 
      'nut', 'nuts', 'seed', 'seeds', 'herb', 'herbs', 'spice', 'spices',
      'broccoli', 'spinach', 'kale', 'carrot', 'tomato', 'avocado', 
      'quinoa', 'brown rice', 'oat', 'oats', 'salmon', 'chicken breast',
      'turkey', 'tofu', 'tempeh', 'yogurt', 'egg', 'eggs'
    ];
    
    // List of ingredients considered less healthy
    List<String> lessHealthyIngredients = [
      'sugar', 'butter', 'oil', 'cream', 'cheese', 'bacon', 'sausage',
      'processed', 'fried', 'fry', 'fries', 'chip', 'chips', 'candy',
      'chocolate', 'cake', 'cookie', 'cookies', 'ice cream', 'soda',
      'white bread', 'white flour', 'margarine', 'syrup', 'corn syrup',
      'high fructose', 'shortening'
    ];
    
    int healthyCount = 0;
    int unhealthyCount = 0;
    
    for (String ingredient in ingredients) {
      String lowerIngredient = ingredient.toLowerCase();
      
      for (String healthy in healthyIngredients) {
        if (lowerIngredient.contains(healthy)) {
          healthyCount++;
          break;
        }
      }
      
      for (String unhealthy in lessHealthyIngredients) {
        if (lowerIngredient.contains(unhealthy)) {
          unhealthyCount++;
          break;
        }
      }
    }
    
    // Calculate score (0-100)
    double totalIngredients = ingredients.length.toDouble();
    double healthyRatio = healthyCount / totalIngredients;
    double unhealthyRatio = unhealthyCount / totalIngredients;
    
    // Base score is 50
    double score = 50.0;
    
    // Add up to 40 points for healthy ingredients
    score += healthyRatio * 40.0;
    
    // Subtract up to 30 points for unhealthy ingredients
    score -= unhealthyRatio * 30.0;
    
    // Ensure score is between 0 and 100
    return score.clamp(0.0, 100.0);
  }

  bool _isRecipeComplete(Recipe recipe) {
    return recipe.id.isNotEmpty &&
           recipe.title.isNotEmpty &&
           recipe.image.isNotEmpty &&
           recipe.instructions.isNotEmpty &&
           recipe.ingredients.isNotEmpty;
  }

  Future<List<String>> getPopularIngredients() async {
    try {
      List<String> popularIngredients = [
        'Chicken',
        'Beef',
        'Pork',
        'Fish',
        'Pasta',
        'Rice',
        'Potato',
        'Tomato',
        'Onion',
        'Garlic',
        'Cheese',
        'Egg',
        'Mushroom',
        'Carrot',
        'Broccoli',
        'Spinach',
        'Lemon',
        'Olive Oil',
        'Butter',
        'Flour'
      ];
      
      return popularIngredients;
    } catch (e) {
      return [];
    }
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/search.php?s=$query'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null) return [];

        List<Recipe> recipes = [];
        for (var mealData in data['meals']) {
          Recipe recipe = await _parseRecipeData(mealData);
          recipes.add(recipe);
        }
        
        return recipes;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<Recipe>> getRecipesByIngredient(String ingredient, {int limit = 10}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/filter.php?i=$ingredient'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null) return [];

        List<Recipe> recipes = [];
        List<dynamic> meals = data['meals'];

        // Shuffle meals to get random selection
        meals.shuffle();

        // Limit to first 'limit' meals or less
        int count = min(limit, meals.length);
        for (int i = 0; i < count; i++) {
          String mealId = meals[i]['idMeal'];
          Recipe? detailedRecipe = await getRecipeDetails(mealId);
          
          if (detailedRecipe != null && _isRecipeComplete(detailedRecipe)) {
            recipes.add(detailedRecipe);
          }
          
          // If we have enough recipes, break early
          if (recipes.length >= limit) break;
        }
        
        return recipes;
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<Recipe>> getRecommendedRecipes() async {
    return getRandomRecipes(10);
  }

  Future<List<Recipe>> getPopularRecipes() async {
    return getRandomRecipes(10);
  }

  Future<List<Recipe>> getFeedRecipes() async {
    return getRandomRecipes(20);
  }
}

