import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import 'dart:io' show File;
import 'storage_service.dart';
import 'package:intl/intl.dart';
import '../models/planned_recipe.dart';
import '../models/nutrition_goals.dart';
import 'package:dash_chat_2/dash_chat_2.dart' as dash;
import '../models/notification.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();
  final dash.ChatUser currentUser = dash.ChatUser(
    id: FirebaseAuth.instance.currentUser?.uid ?? 'user',
    firstName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
  );

  final dash.ChatUser geminiUser = dash.ChatUser(
    id: 'gemini',
    firstName: 'Gemini',
  );
  // Existing methods...

  Future<void> saveUserPersonalization(Map<String, dynamic> data) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .set(data, SetOptions(merge: true));
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserPersonalization() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(userId)
            .get();

        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        } else {
          // Return null if no data exists
          return null;
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveUserGoals(List<String> goals) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'goals': goals});
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveUserAllergies(List<String> allergies) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'allergies': allergies});
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      rethrow;
    }
  }

  // New methods for recipe saving functionality
  Future<void> saveRecipe(Recipe recipe) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_recipes')
            .doc(recipe.id)
            .set({
          'id': recipe.id,
          'title': recipe.title,
          'image': recipe.image,
          'category': recipe.category,
          'area': recipe.area,
          'instructions': recipe.instructions,
          'ingredients': recipe.ingredients,
          'measurements': recipe.measurements,
          'preparationTime': recipe.preparationTime,
          'healthScore': recipe.healthScore,
          'savedAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unsaveRecipe(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_recipes')
            .doc(recipeId)
            .delete();
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isRecipeSaved(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_recipes')
            .doc(recipeId)
            .get();
        return doc.exists;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<Recipe>> getSavedRecipes() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_recipes')
            .orderBy('savedAt', descending: true)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Recipe(
            id: data['id'],
            title: data['title'],
            image: data['image'],
            category: data['category'],
            area: data['area'],
            ingredients: List<String>.from(data['ingredients']),
            measurements: List<String>.from(data['measurements']),
            instructions: data['instructions'],
            instructionSteps: data['instructions'].split('\n'),
            preparationTime: data['preparationTime'],
            healthScore: data['healthScore'].toDouble(),
            nutritionInfo: NutritionInfo.generateRandom(), // We'll regenerate this since it's not stored
          );
        }).toList();
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> removeFromSavedRecipes(Recipe recipe) async {
    try {
      // Assuming you're using Firebase Authentication and have the current user
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Reference to the Firestore collection of saved recipes for this user
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('saved_recipes')
          .doc(recipe.id) // Assuming the recipe has a unique ID
          .delete();
    } catch (e) {
      rethrow;
    }
  }


  Future<bool> isRecipePlanned(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .doc(recipeId)
            .get();
        return doc.exists;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<Recipe>> getPlannedRecipes() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .orderBy('plannedAt', descending: true)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Recipe(
            id: data['id'],
            title: data['title'],
            image: data['image'],
            category: data['category'],
            area: data['area'],
            ingredients: List<String>.from(data['ingredients']),
            measurements: List<String>.from(data['measurements']),
            instructions: data['instructions'],
            instructionSteps: data['instructions'].split('\n'),
            preparationTime: data['preparationTime'],
            healthScore: data['healthScore'].toDouble(),
            nutritionInfo: NutritionInfo.generateRandom(), // We'll regenerate this since it's not stored
          );
        }).toList();
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> removePlannedRecipe(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Menghapus dokumen dengan ID tertentu dari koleksi planned_recipes
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .doc(recipeId)
            .delete();
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addPlannedRecipe(Recipe recipe, String mealType, DateTime date) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No authenticated user found');

      final normalizedDate = DateTime(date.year, date.month, date.day);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('planned_recipes')
          .add({
        'id': recipe.id,
        'title': recipe.title,
        'image': recipe.image,
        'category': recipe.category,
        'area': recipe.area,
        'instructions': recipe.instructions,
        'ingredients': recipe.ingredients,
        'measurements': recipe.measurements,
        'preparationTime': recipe.preparationTime,
        'healthScore': recipe.healthScore,
        'plannedAt': FieldValue.serverTimestamp(),
        'plannedDate': Timestamp.fromDate(normalizedDate),
        'mealType': mealType,
        'nutritionInfo': {
          'calories': recipe.nutritionInfo.calories,
          'carbs': recipe.nutritionInfo.carbs,
          'fiber': recipe.nutritionInfo.fiber,
          'protein': recipe.nutritionInfo.protein,
          'fat': recipe.nutritionInfo.fat,
          'saturatedFat': recipe.nutritionInfo.saturatedFat,
          'sugars': recipe.nutritionInfo.sugars,
          'sodium': recipe.nutritionInfo.sodium,
          'totalFat': recipe.nutritionInfo.totalFat,
        },
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkIfPlanExists(String recipeId, String mealType, DateTime selectedDate) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Normalisasi tanggal ke midnight untuk konsistensi
        final normalizedDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );

        final querySnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .where('id', isEqualTo: recipeId)
            .where('mealType', isEqualTo: mealType)
            .where('plannedDate', isEqualTo: Timestamp.fromDate(normalizedDate))
            .get();

        return querySnapshot.docs.isNotEmpty; // Jika ada dokumen, berarti duplikat
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }


  Future<void> addToRecentlyViewed(Recipe recipe) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('recently_viewed')
            .doc(recipe.id)
            .set({
          'id': recipe.id,
          'title': recipe.title,
          'category': recipe.category,
          'area': recipe.area,
          'image': recipe.image,
          'preparationTime': recipe.preparationTime,
          'healthScore': recipe.healthScore,
          'viewedAt': FieldValue.serverTimestamp(),
          // Add these fields
          'ingredients': recipe.ingredients,
          'measurements': recipe.measurements,
          'instructions': recipe.instructions,
        });
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Recipe>> getRecentlyViewedRecipes({int limit = 10}) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('recently_viewed')
            .orderBy('viewedAt', descending: true)
            .limit(limit)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Recipe(
            id: data['id'],
            title: data['title'],
            image: data['image'],
            category: data['category'],
            area: data['area'],
            preparationTime: data['preparationTime'],
            healthScore: data['healthScore'].toDouble(),
            // Update these fields to use stored data
            ingredients: List<String>.from(data['ingredients'] ?? []),
            measurements: List<String>.from(data['measurements'] ?? []),
            instructions: data['instructions'] ?? '',
            instructionSteps: (data['instructions'] ?? '').split('\n'),
            nutritionInfo: NutritionInfo.generateRandom(),
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  // Tambahkan metode ini di dalam kelas FirestoreService

  Future<String?> getCurrentUserUsername() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userId).get();

        // Periksa apakah dokumen ada dan memiliki field username
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('username')) {
          return userData['username'];
        }

        return null;
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      final imageUrl =
          await _storageService.uploadProfilePicture(imageFile, userId);
      await _firestore.collection('users').doc(userId).update({
        'profilePictureUrl': imageUrl,
      });
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update(data);
    }
  }

  Future<List<String>> getUserGoals() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          return List<String>.from(data['goals'] ?? []);
        }
      }
      return [];
    } catch (e) {
      return [];
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

  Future<Map<String, List<PlannedMeal>>> getPlannedMeals() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('planned_recipes')
          .orderBy('plannedDate')
          .get();

      Map<String, List<PlannedMeal>> meals = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final recipe = Recipe(
          id: data['id'] ?? '',
          title: data['title'] ?? '',
          image: data['image'] ?? '',
          category: data['category'] ?? '',
          area: data['area'] ?? '',
          instructions: data['instructions'] ?? '',
          ingredients: List<String>.from(data['ingredients'] ?? []),
          measurements: List<String>.from(data['measurements'] ?? []),
          preparationTime: data['preparationTime'] ?? 0,
          healthScore: (data['healthScore'] ?? 0).toDouble(),
          instructionSteps: (data['instructions'] ?? '').split('\n'),
          nutritionInfo: NutritionInfo.generateRandom(),
        );

        final date = (data['plannedDate'] as Timestamp).toDate();
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        final plannedMeal = PlannedMeal(
          recipe: recipe,
          mealType: data['mealType'] ?? '',
          dateKey: dateKey,
          date: date,
        );

        if (!meals.containsKey(dateKey)) {
          meals[dateKey] = [];
        }
        meals[dateKey]!.add(plannedMeal);
      }

      return meals;
    } catch (e) {
      throw Exception('Failed to load planned meals: $e');
    }
  }

  Future<void> deletePlannedMeal(PlannedMeal meal) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Query untuk mencari dokumen yang akan dihapus
        final querySnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .where('id', isEqualTo: meal.recipe.id)
            .where('mealType', isEqualTo: meal.mealType)
            .where('plannedDate', isEqualTo: Timestamp.fromDate(meal.date))
            .get();

        // Hapus semua dokumen yang cocok
        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Recipe>> getUserCreatedRecipes() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('created_recipes')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Recipe(
          id: doc.id,
          title: data['title'],
          image: data['image'],
          category: data['category'],
          area: data['area'],
          instructions: data['instructions'],
          ingredients: List<String>.from(data['ingredients']),
          measurements: List<String>.from(data['measurements']),
          preparationTime: data['preparationTime'],
          healthScore: data['healthScore'].toDouble(),
          instructionSteps: data['instructions'].split('\n'),
          nutritionInfo: NutritionInfo.generateRandom(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteUserRecipe(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('created_recipes')
          .doc(recipeId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserRecipe(Recipe recipe) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final recipeData = {
        'title': recipe.title,
        'image': recipe.image,
        'category': recipe.category,
        'area': recipe.area,
        'instructions': recipe.instructions,
        'ingredients': recipe.ingredients,
        'measurements': recipe.measurements,
        'preparationTime': recipe.preparationTime,
        'healthScore': recipe.healthScore,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('created_recipes')
          .doc(recipe.id)
          .update(recipeData);
    } catch (e) {
      rethrow;
    }
  }

    Future<List<Recipe>> getRandomRecipes({int number = 10}) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('created_recipes')
          .limit(number)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Recipe(
          id: doc.id,
          title: data['title'],
          image: data['image'],
          ingredients: List<String>.from(data['ingredients']),
          measurements: List<String>.from(data['measurements']),
          instructions: data['instructions'],
          instructionSteps: data['instructions'].split('\n'),
          preparationTime: data['preparationTime'],
          healthScore: data['healthScore'].toDouble(),
          nutritionInfo: NutritionInfo.generateRandom(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          popularity: data['popularity'] ?? 0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> madeRecipe(Recipe recipe, {required String mealKey, String? mealType, DateTime? plannedDate}) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('made_recipes')
            .doc(mealKey)  // Gunakan mealKey sebagai document ID
            .set({
          'id': recipe.id,
          'title': recipe.title,
          'image': recipe.image,
          'category': recipe.category,
          'area': recipe.area,
          'ingredients': recipe.ingredients,
          'measurements': recipe.measurements,
          'instructions': recipe.instructions,
          'preparationTime': recipe.preparationTime,
          'healthScore': recipe.healthScore,
          'mealType': mealType,
          'plannedDate': plannedDate,
          'madeAt': FieldValue.serverTimestamp(),
          'nutrition': {
            'calories': recipe.nutritionInfo.calories,
            'protein': recipe.nutritionInfo.protein,
            'carbs': recipe.nutritionInfo.carbs,
            'fat': recipe.nutritionInfo.fat,
            'fiber': recipe.nutritionInfo.fiber,
            'saturatedFat': recipe.nutritionInfo.saturatedFat,
            'sugars': recipe.nutritionInfo.sugars,
            'sodium': recipe.nutritionInfo.sodium,
            'totalFat': recipe.nutritionInfo.totalFat,
          },
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Recipe>> getMadeRecipes() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('made_recipes')
            .orderBy('madeAt', descending: true)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Recipe(
            id: data['id'],
            title: data['title'],
            image: data['image'],
            category: data['category'] ?? 'Unknown',
            area: data['area'] ?? 'Unknown',
            ingredients: List<String>.from(data['ingredients'] ?? []),
            measurements: List<String>.from(data['measurements'] ?? []),
            instructions: data['instructions'] ?? '',
            instructionSteps: (data['instructions'] ?? '').split('\n'),
            preparationTime: data['preparationTime'] ?? 0,
            healthScore: (data['healthScore'] ?? 0).toDouble(),
            nutritionInfo: NutritionInfo(
              calories: data['nutrition']?['calories'] ?? 0,
              protein: data['nutrition']?['protein']?.toDouble() ?? 0,
              carbs: data['nutrition']?['carbs']?.toDouble() ?? 0,
              fat: data['nutrition']?['fat']?.toDouble() ?? 0,
              fiber: data['nutrition']?['fiber']?.toDouble() ?? 0,
              saturatedFat: data['nutrition']?['saturatedFat']?.toDouble() ?? 0,
              sugars: data['nutrition']?['sugars']?.toDouble() ?? 0,
              sodium: data['nutrition']?['sodium'] ?? 0,
              totalFat: data['nutrition']?['totalFat']?.toDouble() ?? 0,
            ),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> removeMadeRecipe(String mealKey) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('made_recipes')
            .doc(mealKey)  // Gunakan mealKey sebagai document ID
            .delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isRecipeMade(String mealKey) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('made_recipes')
          .doc(mealKey)  // Gunakan mealKey sebagai document ID
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, bool>> getMadeRecipesStatus(List<String> recipeIds) async {
    try {
      String? userId = _auth.currentUser?.uid;
      Map<String, bool> status = {};

      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('made_recipes')
            .get();

        final madeIds = snapshot.docs.map((doc) => doc.id).toSet();

        for (var id in recipeIds) {
          status[id] = madeIds.contains(id);
        }
      }
      return status;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, double>> getDailyNutritionTotals() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);

        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('made_recipes')
            .where('madeAt', isGreaterThanOrEqualTo: startOfDay)
            .get();

        int totalCalories = 0;
        int totalProtein = 0;
        int totalCarbs = 0;
        int totalFat = 0;

        for (var doc in snapshot.docs) {
          final nutrition = doc.data()['nutrition'] as Map<String, dynamic>;
          totalCalories += (nutrition['calories'] as num).toInt();
          totalProtein += (nutrition['protein'] as num).toInt();
          totalCarbs += (nutrition['carbs'] as num).toInt();
          totalFat += (nutrition['fat'] as num).toInt();
        }

        return {
          'calories': totalCalories.toDouble(),
          'protein': totalProtein.toDouble(),
          'carbs': totalCarbs.toDouble(),
          'fat': totalFat.toDouble(),
        };
      }
      return {
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fat': 0,
      };
    } catch (e) {
      return {
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fat': 0,
      };
    }
  }

  Future<Map<String, List<double>>> getWeeklyNutrition(int weekNumber) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      // Calculate start and end dates for the selected week
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1 + (7 * (weekNumber - 1))));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('made_recipes')
          .where('madeAt', isGreaterThanOrEqualTo: startOfWeek)
          .where('madeAt', isLessThanOrEqualTo: endOfWeek)
          .get();

      // Initialize daily totals
      Map<String, List<double>> weeklyNutrition = {
        'calories': List.filled(7, 0),
        'carbs': List.filled(7, 0),
        'fiber': List.filled(7, 0),
        'protein': List.filled(7, 0),
        'fat': List.filled(7, 0),
      };

      // Calculate daily totals
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final madeAt = (data['madeAt'] as Timestamp).toDate();
        final dayIndex = madeAt.difference(startOfWeek).inDays;

        if (dayIndex >= 0 && dayIndex < 7) {
          final nutrition = data['nutrition'] as Map<String, dynamic>;
          weeklyNutrition['calories']![dayIndex] += (nutrition['calories'] ?? 0).toDouble();
          weeklyNutrition['carbs']![dayIndex] += (nutrition['carbs'] ?? 0).toDouble();
          weeklyNutrition['fiber']![dayIndex] += (nutrition['fiber'] ?? 0).toDouble();
          weeklyNutrition['protein']![dayIndex] += (nutrition['protein'] ?? 0).toDouble();
          weeklyNutrition['fat']![dayIndex] += (nutrition['fat'] ?? 0).toDouble();
        }
      }

      return weeklyNutrition;
    } catch (e) {
      return {};
    }
  }

  Future<void> saveNutritionGoals(NutritionGoals goals) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutrition')
          .doc('goals')
          .set(goals.toMap());
    }
  }

  // Di FirestoreService
  Future<NutritionGoals> getNutritionGoals() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No authenticated user found');

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists || !doc.data()!.containsKey('nutritionGoals')) {
        // Set default goals if not exists
        final defaultGoals = NutritionGoals(
          calories: 1766,
          carbs: 274,
          fiber: 30,
          protein: 79,
          fat: 39,
        );

        await _firestore
            .collection('users')
            .doc(userId)
            .set({
              'nutritionGoals': {
                'calories': defaultGoals.calories,
                'carbs': defaultGoals.carbs,
                'fiber': defaultGoals.fiber,
                'protein': defaultGoals.protein,
                'fat': defaultGoals.fat,
              }
            }, SetOptions(merge: true));

        return defaultGoals;
      }

      final goals = doc.data()!['nutritionGoals'] as Map<String, dynamic>;

      return NutritionGoals(
        calories: (goals['calories'] ?? 1766).toDouble(),
        carbs: (goals['carbs'] ?? 274).toDouble(),
        fiber: (goals['fiber'] ?? 30).toDouble(),
        protein: (goals['protein'] ?? 79).toDouble(),
        fat: (goals['fat'] ?? 39).toDouble(),
      );
    } catch (e) {
      // Return default goals if error
      return NutritionGoals(
        calories: 1766,
        carbs: 274,
        fiber: 30,
        protein: 79,
        fat: 39,
      );
    }
  }

  Future<Map<String, double>> getTodayNutrition() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No authenticated user found');

      // Get today's date at midnight for consistent querying
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final tomorrow = today.add(const Duration(days: 1));

      // Query made recipes for today
      final madeRecipesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('made_recipes')
          .where('madeAt', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('madeAt', isLessThan: Timestamp.fromDate(tomorrow))
          .get();

      // Initialize nutrition totals
      Map<String, double> totals = {
        'calories': 0,
        'carbs': 0,
        'fiber': 0,
        'protein': 0,
        'fat': 0,
      };

      // Sum up nutrition from all made recipes
      for (var doc in madeRecipesSnapshot.docs) {
        final data = doc.data();
        if (data['nutrition'] != null) {
          final nutrition = data['nutrition'] as Map<String, dynamic>;
          totals['calories'] = (totals['calories'] ?? 0) +
              (nutrition['calories']?.toDouble() ?? 0);
          totals['carbs'] = (totals['carbs'] ?? 0) +
              (nutrition['carbs']?.toDouble() ?? 0);
          totals['fiber'] = (totals['fiber'] ?? 0) +
              (nutrition['fiber']?.toDouble() ?? 0);
          totals['protein'] = (totals['protein'] ?? 0) +
              (nutrition['protein']?.toDouble() ?? 0);
          totals['fat'] = (totals['fat'] ?? 0) +
              (nutrition['fat']?.toDouble() ?? 0);
        }
      }

      return totals;
    } catch (e) {
      return {
        'calories': 0,
        'carbs': 0,
        'fiber': 0,
        'protein': 0,
        'fat': 0,
      };
    }
  }

  Future<Map<String, double>> checkNutritionWarnings(Recipe recipe) async {
    try {
      // Get current nutrition totals
      final currentTotals = await getTodayNutrition();

      // Get user's nutrition goals
      final goals = await getNutritionGoals();

      // Calculate current percentages
      final currentPercentages = {
        'calories': ((currentTotals['calories'] ?? 0) / goals.calories) * 100,
        'carbs': ((currentTotals['carbs'] ?? 0) / goals.carbs) * 100,
        'fiber': ((currentTotals['fiber'] ?? 0) / goals.fiber) * 100,
        'protein': ((currentTotals['protein'] ?? 0) / goals.protein) * 100,
        'fat': ((currentTotals['fat'] ?? 0) / goals.fat) * 100,
      };

      // Calculate additional percentages from the recipe
      final recipePercentages = {
        'calories': (recipe.nutritionInfo.calories / goals.calories) * 100,
        'carbs': (recipe.nutritionInfo.carbs / goals.carbs) * 100,
        'fiber': (recipe.nutritionInfo.fiber / goals.fiber) * 100,
        'protein': (recipe.nutritionInfo.protein / goals.protein) * 100,
        'fat': (recipe.nutritionInfo.fat / goals.fat) * 100,
      };

      // Calculate total percentages after adding the recipe
      final totalPercentages = {
        'calories': currentPercentages['calories']! + recipePercentages['calories']!,
        'carbs': currentPercentages['carbs']! + recipePercentages['carbs']!,
        'fiber': currentPercentages['fiber']! + recipePercentages['fiber']!,
        'protein': currentPercentages['protein']! + recipePercentages['protein']!,
        'fat': currentPercentages['fat']! + recipePercentages['fat']!,
      };

      return totalPercentages;
    } catch (e) {
      return {};
    }
  }

  // Add this method to FirestoreService
  Future<void> debugNutritionData() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No authenticated user found');

      // Check nutrition goals
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      // Check made recipes
      final madeRecipes = await _firestore
          .collection('users')
          .doc(userId)
          .collection('made_recipes')
          .get();

    } catch (e) {
    }
  }

  Future<void> saveChatMessage(dash.ChatMessage message, bool isUser) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No authenticated user found');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .add({
            'text': message.text,
            'isUser': isUser,
            'timestamp': FieldValue.serverTimestamp(),
            'medias': message.medias?.map((media) => {
              'url': media.url,
              'type': media.type.toString(),
              'fileName': media.fileName,
            }).toList(),
          });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dash.ChatMessage>> getChatHistory() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No authenticated user found');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        List<dash.ChatMedia>? medias;

        if (data['medias'] != null) {
          medias = (data['medias'] as List).map((mediaData) => dash.ChatMedia(
            url: mediaData['url'],
            type: dash.MediaType.image,
            fileName: mediaData['fileName'],
          )).toList();
        }

        return dash.ChatMessage(
          text: data['text'],
          user: data['isUser'] ? currentUser : geminiUser,
          createdAt: (data['timestamp'] as Timestamp).toDate(),
          medias: medias,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      final notifications = querySnapshot.docs
          .map((doc) {
            return NotificationModel.fromMap(doc.data(), doc.id);
          })
          .toList();

      return notifications;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      final batch = FirebaseFirestore.instance.batch();

      final notifications = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      final notificationData = {
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': type,
        'relatedId': relatedId,
      };

      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add(notificationData);

    } catch (e) {
      rethrow;
    }
  }

  Future<Recipe?> getRecipeById(String recipeId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .get();

      if (!doc.exists) return null;

      return Recipe.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<void> planMeal(Recipe recipe, DateTime date, String mealType) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('planned_meals')
          .add({
        'recipeId': recipe.id,
        'date': date,
        'mealType': mealType,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteProfilePicture() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      // Pertama, ambil URL gambar profil saat ini
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        // Update dokumen user di Firestore dengan menghapus URL foto profil
        await _firestore.collection('users').doc(userId).update({
          'profilePictureUrl': "", // Atau gunakan FieldValue.delete()
        });
      }
    } catch (e) {
      throw Exception('Failed to delete profile picture: $e');
    }
  }
}