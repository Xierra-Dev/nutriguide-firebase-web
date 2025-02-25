import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';

class CacheService {
  static const String RECOMMENDED_CACHE_KEY = 'recommended_recipes';
  static const String POPULAR_CACHE_KEY = 'popular_recipes';
  static const String FEED_CACHE_KEY = 'feed_recipes';
  static const String POPULAR_INGREDIENTS_KEY = 'popular_ingredients';
  static const Duration CACHE_DURATION = Duration(hours: 24);

  Future<void> cacheRecipes(String key, List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = recipes.map((recipe) => recipe.toJson()).toList();
    await prefs.setString(key, jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'data': recipesJson,
    }));
  }

  Future<List<Recipe>?> getCachedRecipes(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(key);
    
    if (cachedData != null) {
      print('Cached data found for key: $key');
      final decoded = jsonDecode(cachedData);
      final timestamp = DateTime.parse(decoded['timestamp']);
      
      // Check if cache is still valid
      if (DateTime.now().difference(timestamp) < CACHE_DURATION) {
        print('Cache is still valid (age: ${DateTime.now().difference(timestamp).inHours} hours)');
        final List<dynamic> recipesJson = decoded['data'];
        return recipesJson.map((json) => Recipe.fromJson(json)).toList();
      } else {
        print('Cache is expired (age: ${DateTime.now().difference(timestamp).inHours} hours)');
      }
    } else {
      print('No cached data found for key: $key');
    }
    return null;
  }

  Future<void> cacheIngredients(List<Map<String, String>> ingredients) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(POPULAR_INGREDIENTS_KEY, jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'data': ingredients,
    }));
  }

  Future<List<Map<String, String>>?> getCachedIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(POPULAR_INGREDIENTS_KEY);
    
    if (cachedData != null) {
      final decoded = jsonDecode(cachedData);
      final timestamp = DateTime.parse(decoded['timestamp']);
      
      if (DateTime.now().difference(timestamp) < CACHE_DURATION) {
        final List<dynamic> data = decoded['data'];
        return data.map((item) => Map<String, String>.from(item)).toList();
      }
    }
    return null;
  }
} 