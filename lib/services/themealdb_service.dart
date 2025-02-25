import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class TheMealDBService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> getRandomMealImage() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/random.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return data['meals'][0]['strMealThumb'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching random meal image: $e');
      return null;
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
      print('Error getting user allergies: $e');
      return [];
    }
  }

  Future<List<Recipe>> getRandomRecipes({int number = 300}) async {
    // Get user's allergies
    List<String> userAllergies = await getUserAllergies();

    List<Recipe> recipes = [];
    int attempts = 0;
    int maxAttempts = number * 3; // Prevent infinite loop

    while (recipes.length < number && attempts < maxAttempts) {
      attempts++;

      try {
        final response = await http.get(Uri.parse('$baseUrl/random.php'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['meals'] != null && data['meals'].isNotEmpty) {
            final recipe = Recipe.fromTheMealDB(data['meals'][0]);

            // Check if recipe is complete and doesn't contain allergic ingredients
            if (_isRecipeComplete(recipe) && !_containsAllergicIngredients(recipe, userAllergies)) {
              recipes.add(recipe);
              print('Added random recipe: ${recipe.title} with health score: ${recipe.healthScore}');
            } else {
              print('Skipped recipe due to incompleteness or allergic ingredients: ${recipe.title}');
            }
          }
        } else {
          print('Failed to load random recipe. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching random recipe: $e');
      }
    }

    // If not enough recipes found, log a warning
    if (recipes.length < number) {
      print('Warning: Could only find ${recipes.length} non-allergic recipes out of $number requested');
    }

    return recipes;
  }

// New method to check for allergic ingredients
  bool _containsAllergicIngredients(Recipe recipe, List<String> allergies) {
    if (allergies.isEmpty) return false;

    // Convert allergies to lowercase for case-insensitive matching
    final lowerCaseAllergies = allergies.map((allergy) => allergy.toLowerCase()).toList();

    // Check each ingredient in the recipe
    for (var ingredient in recipe.ingredients) {
      // Convert ingredient to lowercase for case-insensitive matching
      final lowerCaseIngredient = ingredient.toLowerCase();

      // Check if any allergy matches the ingredient
      if (lowerCaseAllergies.any((allergy) => lowerCaseIngredient.contains(allergy))) {
        print('Recipe contains allergic ingredient: $ingredient');
        return true;
      }
    }

    return false;
  }

  Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/filter.php?c=$category'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          List<Recipe> recipes = [];
          for (var meal in data['meals']) {
            final detailedRecipe = await getRecipeById(meal['idMeal']);
            if (_isRecipeComplete(detailedRecipe)) {
              recipes.add(detailedRecipe);
              print('Added category recipe: ${detailedRecipe.title} with health score: ${detailedRecipe.healthScore}');
            } else {
              print('Skipped incomplete category recipe: ${detailedRecipe.title}');
            }
          }
          return recipes;
        }
      }
      print('Failed to load recipes for category $category. Status code: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error fetching recipes by category: $e');
      return [];
    }
  }

  Future<Recipe> getRecipeById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/lookup.php?i=$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return Recipe.fromTheMealDB(data['meals'][0]);
        }
      }
      throw Exception('Failed to load recipe details');
    } catch (e) {
      print('Error fetching recipe details: $e');
      rethrow;
    }
  }

  bool _isRecipeComplete(Recipe recipe) {
    return recipe.ingredients.isNotEmpty &&
           recipe.instructionSteps.isNotEmpty &&
           recipe.healthScore > 0; // Changed from 4 to 0 to include more recipes
  }


  Future<List<Map<String, String>>> getPopularIngredients() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/list.php?i=list'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          final ingredients = (data['meals'] as List)
              .take(10) // Get the first 10 ingredients
              .map((ingredient) => {
                    'name': ingredient['strIngredient'] as String,
                    'image':
                        'https://www.themealdb.com/images/ingredients/${ingredient['strIngredient']}.png',
                  })
              .toList();
          return ingredients;
        }
      }
      throw Exception('Failed to load popular ingredients');
    } catch (e) {
      print('Error fetching popular ingredients: $e');
      return [];
    }
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/search.php?s=$query'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          return (data['meals'] as List)
              .map((recipeData) => Recipe.fromTheMealDB(recipeData))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching recipes: $e');
      return [];
    }
  }

  Future<List<Recipe>> searchRecipesByIngredient(String ingredient) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/filter.php?i=$ingredient'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          List<Recipe> recipes = [];
          for (var meal in data['meals']) {
            final detailedRecipe = await getRecipeById(meal['idMeal']);
            if (_isRecipeComplete(detailedRecipe)) {
              recipes.add(detailedRecipe);
              print('Added category recipe: ${detailedRecipe.title} with health score: ${detailedRecipe.healthScore}');
            } else {
              print('Skipped incomplete category recipe: ${detailedRecipe.title}');
            }
          }
          return recipes;
        }
      }
      print('Failed to load recipes for category $ingredient. Status code: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error fetching recipes by category: $e');
      return [];
    }
  }

  Future<List<Recipe>> getRecommendedRecipes() async {
    return getRandomRecipes(number: 10);
  }

  Future<List<Recipe>> getPopularRecipes() async {
    return getRandomRecipes(number: 10);
  }

  Future<List<Recipe>> getFeedRecipes() async {
    return getRandomRecipes(number: 20);
  }

}

