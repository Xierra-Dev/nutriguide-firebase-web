import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'services/themealdb_service.dart';
import 'recipe_detail_page.dart';
import 'services/firestore_service.dart';
import 'services/cache_service.dart';
import 'package:intl/intl.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';
import 'core/widgets/app_text.dart';
import 'dart:async';

import 'package:shimmer/shimmer.dart';

//import 'widgets/skeleton_loading.dart';
// Custom page route that animates from the tapped card
class RecipePageRoute extends PageRouteBuilder {
  final Recipe recipe;
  final Rect? beginRect;

  RecipePageRoute({required this.recipe, this.beginRect})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RecipeDetailPage(recipe: recipe),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuad,
              reverseCurve: Curves.easeInQuad,
            );

            // Fade animation
            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curve);

            // Scale animation - starts from smaller size
            var scaleAnimation = Tween<double>(
              begin: 0.85,
              end: 1.0,
            ).animate(curve);

            // Add a slight slide up effect
            var slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(curve);

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              ),
            );
          },
        );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class SlideUpRoute extends PageRouteBuilder {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> primaryAnimation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> primaryAnimation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0), // Start from bottom
                end: Offset.zero, // End at the center
              ).animate(CurvedAnimation(
                parent: primaryAnimation,
                curve: Curves.easeOutQuad,
              )),
              child: child,
            );
          },
        );
}

class _SearchPageState extends State<SearchPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TheMealDBService _mealDBService = TheMealDBService();
  final CacheService _cacheService = CacheService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> savedStatus = {};
  final Map<String, bool> plannedStatus = {};
  List<Recipe> recipes = [];
  List<Recipe> searchResults = [];
  List<Map<String, String>> popularIngredients = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String selectedIngredient = '';
  String sortBy = 'Newest';
  String? errorMessage;
  Timer? _debounce;
  bool _showPopularSection = true;
  bool _isSearching = false;
  bool _isYouMightAlsoLikeSectionExpanded = true;

  double _currentScale = 1.0;
  DateTime _selectedDate = DateTime.now();
  String _selectedMeal = 'Dinner';
  List<bool> _daysSelected = List.generate(7, (index) => false);
// ⬇️ Tambahkan ini:
  bool _isHovered = false;

  // Menambahkan Set untuk melacak ID resep yang sudah ditampilkan
  final Set<String> _displayedRecipeIds = {};

  @override
  void initState() {
    super.initState();
    _loadInitialRecipes().then((_) {
      // Check saved status for each recipe after loading
      for (var recipe in recipes) {
        _checkIfSaved(recipe);
        _checkIfPlanned(recipe);
      }
    });
    _loadPopularIngredients();
    _scrollController.addListener(_onScroll);
  }

  Color _getHealthScoreColor(double score) {
    if (score < 6) {
      return AppColors.error;
    } else if (score <= 7.5) {
      return AppColors.accent;
    } else {
      return AppColors.success;
    }
  }

  Future<void> _viewRecipe(Recipe recipe) async {
    await _firestoreService.addToRecentlyViewed(recipe);
    if (mounted) {
      // Get the render box of the tapped card to get its position
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      final position = renderBox?.localToGlobal(Offset.zero);
      final size = renderBox?.size;

      await Navigator.push(
        context,
        RecipePageRoute(
          recipe: recipe,
          beginRect: position != null && size != null
              ? Rect.fromLTWH(
                  position.dx,
                  position.dy,
                  size.width,
                  size.height,
                )
              : null,
        ),
      );
      // Refresh saved status after returning
      _checkIfSaved(recipe);
      _checkIfPlanned(recipe);
    }
  }

  void _showMealSelectionDialog(
      BuildContext context, StateSetter setDialogState, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter mealSetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Meal Type',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width *
                          0.05, // Adjust font size relative to screen width
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Meal type selection
                  ListView(
                    shrinkWrap: true,
                    children: [
                      'Breakfast',
                      'Lunch',
                      'Dinner',
                      'Supper',
                      'Snacks'
                    ].map((String mealType) {
                      return ListTile(
                        title: Text(
                          mealType,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width *
                                0.04, // Adjust font size relative to screen width
                          ),
                        ),
                        onTap: () {
                          // Update the selected meal in the parent dialog
                          setDialogState(() {
                            _selectedMeal = mealType;
                          });
                          // Close both dialogs
                          Navigator.of(context)
                              .pop(); // Close meal selection dialog
                          Navigator.of(context).pop(); // Close parent dialog

                          // Reopen the parent dialog with selected meal
                          _showPlannedDialog(recipe);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Cancel button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPlannedDialog(Recipe recipe) {
    // Reset selected days
    _daysSelected = List.generate(7, (index) => false);

    // Get the start of week (Sunday)
    DateTime now = DateTime.now();
    _selectedDate = now.subtract(Duration(days: now.weekday % 7));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900], // Background untuk dark mode
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.0)),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header dengan navigasi antar minggu
                    const Text(
                      'Choose Day',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            // Pindah ke minggu sebelumnya
                            setDialogState(() {
                              _selectedDate = _selectedDate
                                  .subtract(const Duration(days: 7));
                            });
                          },
                          icon: const Icon(
                            Icons.arrow_left_rounded,
                            size: 40,
                          ),
                          color: Colors.white,
                        ),
                        Text(
                          // Menampilkan rentang tanggal minggu
                          '${DateFormat('MMM dd').format(_selectedDate)} - '
                          '${DateFormat('MMM dd').format(_selectedDate.add(const Duration(days: 6)))}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Pindah ke minggu berikutnya
                            setDialogState(() {
                              _selectedDate =
                                  _selectedDate.add(const Duration(days: 7));
                            });
                          },
                          icon: const Icon(
                            Icons.arrow_right_rounded,
                            size: 40,
                          ),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 60,
                      child: Center(
                        child: InkWell(
                          onTap: () {
                            // Open meal selection dialog
                            _showMealSelectionDialog(
                                context, setDialogState, recipe);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedMeal.isEmpty
                                      ? 'Select Meal'
                                      : _selectedMeal,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Pilihan hari menggunakan ChoiceChip (dimulai dari Sunday)
                    Wrap(
                      spacing: 8,
                      children: [
                        for (int i = 0; i < 7; i++)
                          ChoiceChip(
                            label: Text(
                              DateFormat('EEE, dd').format(
                                _selectedDate.add(Duration(
                                    days: i - _selectedDate.weekday % 7)),
                              ), // Menampilkan hari dimulai dari Sunday
                            ),
                            selected: _daysSelected[i],
                            onSelected: (bool selected) {
                              setDialogState(() {
                                _daysSelected[i] = selected;
                              });
                            },
                            selectedColor: Colors.blue,
                            backgroundColor: Colors.grey[800],
                            labelStyle: TextStyle(
                              color:
                                  _daysSelected[i] ? Colors.white : Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tombol aksi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        ElevatedButton(
                          // Inside dialog's ElevatedButton onPressed
                          onPressed: () {
                            if (_selectedMeal.isEmpty ||
                                !_daysSelected.contains(true)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please select at least one day and a meal type!')),
                              );
                              return;
                            }
                            _saveSelectedPlan(recipe); // Pass the recipe
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

// Fungsi untuk menyimpan pilihan (sesuaikan dengan logika aplikasi Anda)
  void _saveSelectedPlan(Recipe recipe) async {
    try {
      List<DateTime> selectedDates = [];
      List<DateTime> successfullyPlannedDates =
          []; // Untuk menyimpan tanggal yang berhasil direncanakan

      for (int i = 0; i < _daysSelected.length; i++) {
        if (_daysSelected[i]) {
          // Normalize the date
          DateTime selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day + i,
          );
          print('Selected date: $selectedDate');
          selectedDates.add(selectedDate);
        }
      }

      for (DateTime date in selectedDates) {
        // Periksa apakah rencana dengan tanggal ini sudah ada
        bool exists = await _firestoreService.checkIfPlanExists(
          recipe.id,
          _selectedMeal,
          date,
        );

        if (exists) {
          print('Duplicate plan detected for date: $date');
          continue; // Lewati tanggal yang sudah direncanakan
        }

        // Simpan rencana baru
        print('Saving recipe for date: $date');
        await _firestoreService.addPlannedRecipe(
          recipe,
          _selectedMeal,
          date,
        );

        successfullyPlannedDates
            .add(date); // Tambahkan tanggal yang berhasil direncanakan
      }

      if (mounted) {
        if (successfullyPlannedDates.isNotEmpty) {
          // Tampilkan SnackBar untuk tanggal yang berhasil direncanakan
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.add_task_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                      'Recipe planned for ${successfullyPlannedDates.length} day(s)'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Tampilkan SnackBar jika semua tanggal adalah duplikat
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'No new plans were added. All selected plans already exist.',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width *
                          0.03, // Adjust font size based on screen width
                    ),
                  )
                ],
              ),
              backgroundColor: Colors.blue,
            ),
          );
        }

        // Perbarui status rencana di UI
        setState(() {
          plannedStatus[recipe.id] = true; // Tandai sebagai direncanakan
        });
      }
    } catch (e) {
      print('Error saving plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Failed to save plan: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkIfSaved(Recipe recipe) async {
    final isSaved = await _firestoreService.isRecipeSaved(recipe.id);
    if (mounted) {
      setState(() {
        savedStatus[recipe.id] = isSaved;
      });
    }
  }

  Future<void> _checkIfPlanned(Recipe recipe) async {
    final isPlanned = await _firestoreService.isRecipePlanned(recipe.id);
    if (mounted) {
      setState(() {
        plannedStatus[recipe.id] = isPlanned;
      });
    }
  }

  Future<void> _toggleSave(Recipe recipe) async {
    try {
      final isSaved = savedStatus[recipe.id] ?? false;

      if (isSaved) {
        await _firestoreService.unsaveRecipe(recipe.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.text,
                    size: Dimensions.iconM,
                  ),
                  SizedBox(width: Dimensions.paddingS),
                  AppText(
                    'Recipe removed from saved',
                    fontSize: FontSizes.body,
                    color: AppColors.text,
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await _firestoreService.saveRecipe(recipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.text,
                    size: Dimensions.iconM,
                  ),
                  SizedBox(width: Dimensions.paddingS),
                  AppText(
                    'Recipe saved successfully',
                    fontSize: FontSizes.body,
                    color: AppColors.text,
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      setState(() {
        savedStatus[recipe.id] = !isSaved;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: AppColors.text,
                  size: Dimensions.iconM,
                ),
                SizedBox(width: Dimensions.paddingS),
                AppText(
                  'Failed to update saved status',
                  fontSize: FontSizes.body,
                  color: AppColors.text,
                ),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _togglePlan(Recipe recipe) async {
    try {
      // Show the planning dialog without changing the planned status yet
      _showPlannedDialog(recipe);
    } catch (e) {
      // Handle error and show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Error planning recipe: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadInitialRecipes() async {
    setState(() {
      isLoading = true;
      isLoadingMore = false;
      recipes = []; // Reset the recipes list
      _displayedRecipeIds.clear(); // Clear the displayed recipes tracking
    });

    try {
      // Use a stream-like approach to load recipes progressively
      int batchSize = 5;
      int totalToLoad = 30;

      for (int i = 0; i < totalToLoad / batchSize; i++) {
        if (i > 0) {
          setState(() {
            isLoadingMore = true;
          });
        }

        final batchRecipes = await _mealDBService.getRandomRecipes(batchSize);

        if (mounted) {
          setState(() {
            // Add new recipes to the end of the list instead of resorting
            recipes.addAll(batchRecipes);

            // Only sort on the first batch to establish initial order
            if (i == 0) {
              _sortRecipes();
            }

            // Add all new recipe IDs to the displayed set
            for (var recipe in batchRecipes) {
              _displayedRecipeIds.add(recipe.id);
            }

            // Mark as not loading after first batch to show content while loading more
            if (i == 0) {
              isLoading = false;
            }

            // If this is the last batch, mark isLoadingMore as false
            if (i == (totalToLoad / batchSize) - 1) {
              isLoadingMore = false;
            }
          });

          // Check saved status for the batch of recipes
          for (var recipe in batchRecipes) {
            _checkIfSaved(recipe);
            _checkIfPlanned(recipe);
          }
        }
      }
    } catch (e) {
      print('Error loading recipes: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadPopularIngredients() async {
    try {
      // Try to get cached ingredients first
      final cachedIngredients = await _cacheService.getCachedIngredients();
      if (cachedIngredients != null) {
        setState(() {
          popularIngredients = cachedIngredients;
        });
        return;
      }

      // If no cache, fetch from API
      final ingredients = await _mealDBService.getPopularIngredients();
      // Convert List<String> to List<Map<String, String>>
      final mappedIngredients = ingredients
          .map((name) => {
                'name': name,
                'image':
                    'https://www.themealdb.com/images/ingredients/$name.png',
              })
          .toList();
      await _cacheService.cacheIngredients(mappedIngredients);
      setState(() {
        popularIngredients = mappedIngredients;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && _showPopularSection) {
      setState(() {
        _showPopularSection = false;
      });
    } else if (_scrollController.offset <= 100 && !_showPopularSection) {
      setState(() {
        _showPopularSection = true;
      });
    }
  }

  Future<void> _searchRecipes(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isLoading = false;
        isLoadingMore = false;
        errorMessage = null;
        _isSearching = false;
        _displayedRecipeIds.clear(); // Clear tracking when exiting search
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        isLoading = true;
        isLoadingMore = false;
        errorMessage = null;
        _isSearching = true;
        searchResults = []; // Reset search results
        _displayedRecipeIds.clear(); // Clear tracking when starting new search
      });

      try {
        // Get all search results first
        final allResults = await _mealDBService.searchRecipes(query);

        if (allResults.isEmpty) {
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
          return;
        }

        // Process results in batches
        int batchSize = 5;
        int totalResults = allResults.length;

        for (int i = 0; i < totalResults; i += batchSize) {
          if (i > 0) {
            setState(() {
              isLoadingMore = true;
            });
          }

          // Get a subset of recipes
          final int endIndex =
              (i + batchSize < totalResults) ? i + batchSize : totalResults;
          final resultsBatch = allResults.sublist(i, endIndex);

          if (mounted) {
            setState(() {
              // Add new search results at the end without resorting
              searchResults.addAll(resultsBatch);

              // Add new recipe IDs to the displayed set
              for (var recipe in resultsBatch) {
                _displayedRecipeIds.add(recipe.id);
              }

              // Only sort on the first batch to establish initial order
              if (i == 0) {
                // For search results, we could apply a similar sorting if needed
                // or keep them in the order returned by the API
              }

              // Mark as not loading after first batch
              if (i == 0) {
                isLoading = false;
              }

              // If this is the last batch, mark isLoadingMore as false
              if (endIndex == totalResults) {
                isLoadingMore = false;
              }
            });

            // Check saved status for each recipe in the batch
            for (var recipe in resultsBatch) {
              _checkIfSaved(recipe);
              _checkIfPlanned(recipe);
            }

            // Add a small delay to simulate progressive loading
            if (i + batchSize < totalResults) {
              await Future.delayed(const Duration(milliseconds: 300));
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to search recipes. Please try again.';
            isLoading = false;
            isLoadingMore = false;
          });
        }
      }
    });

    return Future.value();
  }

  Future<void> _searchRecipesByIngredient(String ingredient) async {
    // Minimize "You might also like" section immediately
    setState(() {
      isLoading = true;
      isLoadingMore = false;
      selectedIngredient = ingredient;
      searchResults = [];
      _displayedRecipeIds.clear();
      _isSearching = true;
      _searchController.text = ingredient;
      _isYouMightAlsoLikeSectionExpanded = false; // Minimize the section
    });

    try {
      final allRecipes =
          await _mealDBService.getRecipesByIngredient(ingredient);

      if (allRecipes.isEmpty) {
        setState(() {
          isLoading = false;
          searchResults = [];
        });
        return;
      }

      // Process in batches
      int batchSize = 5;
      int totalRecipes = allRecipes.length;

      for (int i = 0; i < totalRecipes; i += batchSize) {
        if (i > 0) {
          setState(() {
            isLoadingMore = true;
          });
        }

        final int endIndex =
            (i + batchSize < totalRecipes) ? i + batchSize : totalRecipes;
        final recipeBatch = allRecipes.sublist(i, endIndex);

        if (mounted) {
          setState(() {
            searchResults.addAll(recipeBatch);

            for (var recipe in recipeBatch) {
              _displayedRecipeIds.add(recipe.id);
            }

            if (i == 0) {
              isLoading = false;
            }

            if (endIndex == totalRecipes) {
              isLoadingMore = false;
            }
          });

          for (var recipe in recipeBatch) {
            _checkIfSaved(recipe);
            _checkIfPlanned(recipe);
          }

          if (i + batchSize < totalRecipes) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
      }

      // Add a delay of 5 seconds before showing the "You might also like" section again
      if (mounted) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _isYouMightAlsoLikeSectionExpanded = true;
            });
          }
        });
      }
    } catch (e) {
      print('Error searching recipes by ingredient: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
          searchResults = [];
          errorMessage = 'Failed to search recipes. Please try again.';
        });
      }
    }
  }

  void _sortRecipes() {
    setState(() {
      final listToSort = _isSearching ? searchResults : recipes;

      switch (sortBy) {
        case 'Newest':
          listToSort.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'Popular':
          listToSort.sort((a, b) => b.popularity.compareTo(a.popularity));
          break;
        case 'Rating':
          listToSort.sort((a, b) => b.healthScore.compareTo(a.healthScore));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isSearching) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.paddingM,
                vertical: Dimensions.paddingS,
              ),
              child: AppText(
                '',
                fontSize: FontSizes.heading2,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                left: Dimensions.paddingM,
                right: Dimensions.paddingM,
                bottom: Dimensions.paddingM,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: ResponsiveHelper.getAdaptiveTextSize(
                      context, FontSizes.body),
                ),
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(
                    color: AppColors.text.withOpacity(0.5),
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.text,
                    size: Dimensions.iconM,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: Dimensions.paddingM,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _searchRecipes(value);
                  } else {
                    setState(() {
                      _isSearching = false;
                    });
                  }
                },
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showPopularSection ? 160 : 0,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingM,
                        vertical: Dimensions.paddingS,
                      ),
                      child: AppText(
                        'Popular Ingredients',
                        fontSize: FontSizes.heading3,
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 120,
                      child: popularIngredients.isEmpty
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingM),
                              itemCount: popularIngredients.length,
                              itemBuilder: (context, index) {
                                final ingredient = popularIngredients[index];
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      onEnter: (_) =>
                                          setState(() => _isHovered = true),
                                      onExit: (_) =>
                                          setState(() => _isHovered = false),
                                      child: GestureDetector(
                                        onTapDown: (_) => setState(
                                            () => _currentScale = 0.95),
                                        onTapUp: (_) {
                                          setState(() => _currentScale = 1.0);
                                          _searchRecipesByIngredient(
                                              ingredient['name']!);
                                        },
                                        onTapCancel: () =>
                                            setState(() => _currentScale = 1.0),
                                        child: AnimatedScale(
                                          // ⬇️ Pakai _isHovered
                                          scale:
                                              _isHovered ? 1.05 : _currentScale,
                                          duration:
                                              const Duration(milliseconds: 150),
                                          child: Container(
                                            width: 100,
                                            margin:
                                                const EdgeInsets.only(right: 6),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Dimensions.radiusM),
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                    ingredient['image']!),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Dimensions.radiusM),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black
                                                        .withOpacity(0.7),
                                                  ],
                                                ),
                                              ),
                                              alignment: Alignment.bottomCenter,
                                              padding: EdgeInsets.all(
                                                  Dimensions.paddingS),
                                              child: AppText(
                                                ingredient['name']!
                                                    .toUpperCase(),
                                                fontSize: FontSizes.caption,
                                                color: AppColors.text,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: Dimensions.paddingM,
                bottom: Dimensions.paddingS,
                left: Dimensions.paddingM,
                right: Dimensions.paddingM,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    'Recipes you may like',
                    fontSize: FontSizes.heading3,
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                  PopupMenuButton<String>(
                    initialValue: sortBy,
                    onSelected: (String value) {
                      setState(() {
                        sortBy = value;
                        _sortRecipes();
                      });
                    },
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                    offset: const Offset(0, 40),
                    child: Row(
                      children: [
                        AppText(
                          sortBy,
                          fontSize: FontSizes.body,
                          color: AppColors.text,
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.text,
                          size: Dimensions.iconM,
                        ),
                      ],
                    ),
                    itemBuilder: (BuildContext context) => [
                      _buildSortMenuItem('Newest'),
                      _buildSortMenuItem('Popular'),
                      _buildSortMenuItem('Rating'),
                    ],
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: (isLoading && !_isSearching)
                  ? _buildRecipeGridSkeleton(key: ValueKey('skeleton'))
                  : (_isSearching || selectedIngredient.isNotEmpty)
                      ? _buildSearchResults(key: ValueKey('search_results'))
                      : _buildRecipeGrid(recipes, key: ValueKey('recipe_grid')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeGridSkeleton({Key? key}) {
    final width = ResponsiveHelper.screenWidth(context);
    return GridView.builder(
      key: key,
      padding: EdgeInsets.all(Dimensions.paddingM),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: Dimensions.paddingS,
        mainAxisSpacing: Dimensions.paddingS,
      ),
      itemCount: 6, // Show 6 skeleton items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surface.withOpacity(0.3),
          highlightColor: AppColors.surface.withOpacity(0.6),
          period: Duration(milliseconds: 1500),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(Dimensions.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(Dimensions.radiusM),
                        topRight: Radius.circular(Dimensions.radiusM),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(Dimensions.paddingS),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 70,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusS),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(Dimensions.paddingS),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          height: 16,
                          width: width * 0.3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusS),
                          ),
                        ),
                        SizedBox(height: Dimensions.paddingXS),
                        Container(
                          height: 12,
                          width: width * 0.25,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusS),
                          ),
                        ),
                        SizedBox(height: Dimensions.paddingS),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Container(
                                  width: 30,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        Dimensions.radiusS),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Container(
                                  width: 20,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        Dimensions.radiusS),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String value) {
    return PopupMenuItem<String>(
      value: value,
      height: 50,
      child: AppText(
        value,
        fontSize: FontSizes.body,
        color: AppColors.text,
      ),
    );
  }

  Widget _buildSearchResults({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(
            left: Dimensions.paddingS,
            right: Dimensions.paddingS,
            bottom: Dimensions.paddingM,
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.text,
                  size: Dimensions.iconM,
                ),
                onPressed: () async {
                  setState(() {
                    _isSearching = false;
                    searchResults = [];
                    _searchController.clear();
                    errorMessage = null;
                    isLoading = true;
                    _displayedRecipeIds.clear();
                  });

                  await _loadInitialRecipes();
                  await _loadPopularIngredients();

                  if (mounted) {
                    setState(() {
                      _isYouMightAlsoLikeSectionExpanded = true;
                      selectedIngredient = '';
                    });
                  }
                },
              ),
              SizedBox(width: Dimensions.paddingXS),
              AppText(
                'Search Results',
                fontSize: FontSizes.heading3,
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(
            left: Dimensions.paddingM,
            right: Dimensions.paddingM,
            bottom: Dimensions.paddingM,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: AppColors.text,
              fontSize:
                  ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
            ),
            decoration: InputDecoration(
              hintText: 'Search Recipes...',
              hintStyle: TextStyle(
                color: AppColors.text.withOpacity(0.5),
                fontSize: ResponsiveHelper.getAdaptiveTextSize(
                    context, FontSizes.body),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.text,
                size: Dimensions.iconM,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: Dimensions.paddingM,
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _searchRecipes(value);
              }
            },
          ),
        ),
        SizedBox(height: Dimensions.paddingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (searchResults.isEmpty && !isLoading)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          color: AppColors.text,
                          size: Dimensions.iconL,
                        ),
                        SizedBox(height: Dimensions.paddingM),
                        AppText(
                          "No Results Found",
                          fontSize: FontSizes.heading3,
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: Dimensions.paddingS),
                        AppText(
                          "Try searching with different keywords",
                          fontSize: FontSizes.body,
                          color: AppColors.text.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Expanded(
                    child: isLoading
                        ? _buildSearchResultsSkeleton()
                        : _buildRecipeGrid(searchResults)),
                Padding(
                  padding: EdgeInsets.only(
                    top: Dimensions.paddingXS,
                    left: Dimensions.paddingM,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        'You might also like',
                        fontSize: FontSizes.heading3,
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                      IconButton(
                        icon: Icon(
                          _isYouMightAlsoLikeSectionExpanded
                              ? Icons.arrow_drop_down
                              : Icons.arrow_drop_up,
                          color: AppColors.text,
                          size: Dimensions.iconL,
                        ),
                        onPressed: () {
                          setState(() {
                            _isYouMightAlsoLikeSectionExpanded =
                                !_isYouMightAlsoLikeSectionExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (_isYouMightAlsoLikeSectionExpanded)
                  SizedBox(
                    height: ResponsiveHelper.screenHeight(context) * 0.245,
                    child: _buildRecipeGrid(recipes.take(10).toList(),
                        scrollDirection: Axis.horizontal),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsSkeleton() {
    return GridView.builder(
      padding: EdgeInsets.all(Dimensions.paddingM),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: Dimensions.paddingS,
        mainAxisSpacing: Dimensions.paddingS,
      ),
      itemCount: 6, // Menampilkan 6 skeleton items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surface.withOpacity(0.3),
          highlightColor: AppColors.surface.withOpacity(0.6),
          period: Duration(milliseconds: 1500),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(Dimensions.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(Dimensions.radiusM),
                        topRight: Radius.circular(Dimensions.radiusM),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(Dimensions.paddingS),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 70,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusS),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(Dimensions.paddingS),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          height: 16,
                          width: ResponsiveHelper.screenWidth(context) * 0.3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusS),
                          ),
                        ),
                        SizedBox(height: Dimensions.paddingXS),
                        Container(
                          height: 12,
                          width: ResponsiveHelper.screenWidth(context) * 0.25,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusS),
                          ),
                        ),
                        SizedBox(height: Dimensions.paddingS),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Container(
                                  width: 30,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        Dimensions.radiusS),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Container(
                                  width: 20,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        Dimensions.radiusS),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => _viewRecipe(recipe),
        child: AnimatedScale(
          scale: _isHovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Hero(
            tag: 'recipe-${recipe.id}',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.3),
                border: Border.all(
                  color: _isHovered
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovered ? 0.4 : 0.2),
                    blurRadius: _isHovered ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 7,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                      child: Stack(
                        children: [
                          Image.network(
                            recipe.image,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.2),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                                stops: [0.0, 0.3, 1.0],
                              ),
                            ),
                          ),

                          // Ini posisi tombol More Button di pojok kanan atas
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _buildMoreButton(recipe),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bagian bawah card tetap seperti biasa
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          recipe.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isWeb ? 14 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${recipe.preparationTime} min',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color:
                                      _getHealthScoreColor(recipe.healthScore),
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  recipe.healthScore.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: _getHealthScoreColor(
                                        recipe.healthScore),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreButton(Recipe recipe) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.7),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(
          Icons.more_vert,
          color: Colors.white,
        ),
        onSelected: (String value) {
          if (value == 'save') {
            _toggleSave(recipe);
          } else if (value == 'plan') {
            _togglePlan(recipe);
          }
        },
        color: Colors.black.withOpacity(0.9),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        offset: const Offset(0, 32),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            height: 40,
            value: 'save',
            child: Row(
              children: [
                Icon(
                  savedStatus[recipe.id] == true
                      ? Icons.bookmark
                      : Icons.bookmark_border_rounded,
                  size: 16,
                  color: savedStatus[recipe.id] == true
                      ? AppColors.primary
                      : Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  savedStatus[recipe.id] == true ? 'Saved' : 'Save Recipe',
                  style: TextStyle(
                    fontSize: 12,
                    color: savedStatus[recipe.id] == true
                        ? AppColors.primary
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            height: 40,
            value: 'plan',
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Plan Meal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid(List<Recipe> recipeList,
      {Axis scrollDirection = Axis.vertical, Key? key}) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return Stack(
      key: key,
      children: [
        GridView.builder(
          controller: _scrollController,
          scrollDirection: scrollDirection,
          padding: EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                scrollDirection == Axis.vertical ? (isWeb ? 4 : 2) : 1,
            childAspectRatio:
                scrollDirection == Axis.vertical ? (isWeb ? 0.95 : 0.9) : 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: recipeList.length,
          itemBuilder: (context, index) {
            final recipe = recipeList[index];
            final int row = index ~/ (isWeb ? 4 : 2);
            final int col = index % (isWeb ? 4 : 2);
            final int staggerIndex = row * (isWeb ? 4 : 2) + col;
            final bool isNewRecipe = !_displayedRecipeIds.contains(recipe.id);

            if (!isNewRecipe) {
              return _buildRecipeCard(recipe);
            }

            return FutureBuilder(
              future: Future.delayed(Duration(milliseconds: staggerIndex * 80)),
              builder: (context, snapshot) {
                final bool shouldAnimate =
                    snapshot.connectionState == ConnectionState.done;

                return AnimatedOpacity(
                  duration: Duration(milliseconds: 400),
                  opacity: shouldAnimate ? 1.0 : 0.0,
                  curve: Curves.easeOutQuad,
                  child: AnimatedScale(
                    duration: Duration(milliseconds: 400),
                    scale: shouldAnimate ? 1.0 : 0.8,
                    curve: Curves.easeOutQuad,
                    child: _buildRecipeCard(recipe),
                  ),
                );
              },
            );
          },
        ),
        if (isLoadingMore)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading more recipes...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
