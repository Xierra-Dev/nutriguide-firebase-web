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
      await Navigator.push(
        context,
        SlideUpRoute(page: RecipeDetailPage(recipe: recipe)),
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
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan navigasi antar minggu
                  Text(
                    'Choose Day',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width *
                          0.05, // Adjusting font size based on screen width
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
                            _selectedDate =
                                _selectedDate.subtract(const Duration(days: 7));
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
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width *
                              0.04, // Adjusting font size based on screen width
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.04, // Adjusting font size based on screen width
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
                            DateFormat('EEE').format(
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
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width *
                                0.04, // Adjust font size based on screen width
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
    });
    try {
      final recipes = await _mealDBService.getRandomRecipes(number: 30);
      setState(() {
        this.recipes = recipes;
        _sortRecipes();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading recipes: $e');
      setState(() {
        isLoading = false;
      });
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
      await _cacheService.cacheIngredients(ingredients);
      setState(() {
        popularIngredients = ingredients;
      });
    } catch (e) {
      print('Error loading popular ingredients: $e');
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

  void _searchRecipes(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isLoading = false;
        errorMessage = null;
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        isLoading = true;
        errorMessage = null;
        _isSearching = true;
      });

      try {
        final results = await _mealDBService.searchRecipes(query);
        
        if (mounted) {
          setState(() {
            searchResults = results;
            isLoading = false;
          });

          // Check saved status for each recipe
          for (var recipe in results) {
            _checkIfSaved(recipe);
            _checkIfPlanned(recipe);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to search recipes. Please try again.';
            isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _searchRecipesByIngredient(String ingredient) async {
    setState(() {
      isLoading = true;
      selectedIngredient = ingredient;
    });
    try {
      final recipes =
          await _mealDBService.searchRecipesByIngredient(ingredient);
      setState(() {
        this.recipes = recipes;
        isLoading = false;
      });

      for (var recipe in recipes) {
        _checkIfSaved(recipe);
      }
    } catch (e) {
      print('Error searching recipes by ingredient: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _openRecipeDetail(Recipe recipe) async {
    try {
      // Tambahkan ke recently viewed
      await _firestoreService.addToRecentlyViewed(recipe);
      if (mounted) {
        // Check if widget is still mounted
        await Navigator.push(
          context,
          SlideUpRoute(
            page: RecipeDetailPage(recipe: recipe),
          ),
        );
      }
    } catch (e) {
      print('Error opening recipe detail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening recipe')),
        );
      }
    }
  }

  void _sortRecipes() {
    setState(() {
      switch (sortBy) {
        case 'Newest':
          recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'Popular':
          recipes.sort((a, b) => b.popularity.compareTo(a.popularity));
          break;
        case 'Rating':
          recipes.sort((a, b) => b.healthScore.compareTo(a.healthScore));
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
          Padding(
            padding: EdgeInsets.all(Dimensions.paddingM),
            child: AppText(
              '',
              fontSize: FontSizes.heading2,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!_isSearching) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingM),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(
                      context,
                      FontSizes.body
                    ),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(
                      color: AppColors.text.withOpacity(0.5),
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context,
                        FontSizes.body
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.text,
                      size: Dimensions.iconM,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingM,
                      vertical: Dimensions.paddingS,
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
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingM),
                        itemCount: popularIngredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = popularIngredients[index];
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return GestureDetector(
                                onTapDown: (_) => setState(() => _currentScale = 0.95),
                                onTapUp: (_) {
                                  setState(() => _currentScale = 1.0);
                                  _searchRecipesByIngredient(ingredient['name']!);
                                },
                                onTapCancel: () => setState(() => _currentScale = 1.0),
                                child: AnimatedScale(
                                  scale: _currentScale,
                                  duration: const Duration(milliseconds: 150),
                                  child: Container(
                                    width: 100,
                                    margin: EdgeInsets.only(right: Dimensions.paddingS),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                      image: DecorationImage(
                                        image: NetworkImage(ingredient['image']!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                      alignment: Alignment.bottomCenter,
                                      padding: EdgeInsets.all(Dimensions.paddingS),
                                      child: AppText(
                                        ingredient['name']!.toUpperCase(),
                                        fontSize: FontSizes.caption,
                                        color: AppColors.text,
                                        fontWeight: FontWeight.bold,
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
              padding: EdgeInsets.all(Dimensions.paddingM),
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
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _isSearching
                    ? _buildSearchResults()
                    : _buildRecipeGrid(recipes),
          ),
        ],
      ),
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

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Move the back button and title row closer to the top
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingM,
            vertical: Dimensions.paddingS
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.text,
                  size: Dimensions.iconM,
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    searchResults = [];
                    _searchController.clear();
                    errorMessage = null;
                  });
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
        // Reduce padding and spacing around the search bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingM),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: AppColors.text,
                fontSize: ResponsiveHelper.getAdaptiveTextSize(
                  context,
                  FontSizes.body
                ),
              ),
              decoration: InputDecoration(
                hintText: 'Search Recipes...',
                hintStyle: TextStyle(
                  color: AppColors.text.withOpacity(0.5),
                  fontSize: ResponsiveHelper.getAdaptiveTextSize(
                    context,
                    FontSizes.body
                  ),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.text,
                  size: Dimensions.iconM,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingM,
                  vertical: Dimensions.paddingS,
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _searchRecipes(value);
                }
              },
            ),
          ),
        ),
        // Remove or reduce the SizedBox height
        SizedBox(height: Dimensions.paddingS),
        // Expand the search results to take up more space
        Expanded(
          child: _buildRecipeGrid(searchResults),
        ),
        // Conditionally render the "You might also like" section
        if (searchResults.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(
              top: Dimensions.paddingM,
              bottom: 0,
              left: Dimensions.paddingM,
              right: Dimensions.paddingM,
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
                // Add an IconButton to toggle the section
                IconButton(
                  icon: Icon(
                    _isYouMightAlsoLikeSectionExpanded
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
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
          // Only show the grid when section is expanded
          if (_isYouMightAlsoLikeSectionExpanded)
            SizedBox(
              height: ResponsiveHelper.screenHeight(context) * 0.21,
              child: _buildRecipeGrid(
                recipes.take(10).toList(),
                scrollDirection: Axis.horizontal
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildRecipeGrid(List<Recipe> recipeList, {Axis scrollDirection = Axis.vertical}) {
    return GridView.builder(
      controller: _scrollController,
      scrollDirection: scrollDirection,
      padding: EdgeInsets.all(Dimensions.paddingM),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: scrollDirection == Axis.vertical ? 2 : 1,
        childAspectRatio: scrollDirection == Axis.vertical ? 0.8 : 1.2,
        crossAxisSpacing: Dimensions.paddingM,
        mainAxisSpacing: Dimensions.paddingM,
      ),
      itemCount: recipeList.length,
      itemBuilder: (context, index) {
        final recipe = recipeList[index];
        return GestureDetector(
          onTap: () => _viewRecipe(recipe),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusM),
              image: DecorationImage(
                image: NetworkImage(recipe.image),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusM),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              padding: EdgeInsets.all(Dimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row with Area Tag and Bookmark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingS,
                          vertical: Dimensions.paddingXS,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(Dimensions.radiusS),
                        ),
                        child: AppText(
                          recipe.area ?? 'International',
                          fontSize: FontSizes.caption,
                          color: AppColors.text,
                        ),
                      ),
                      Container(
                        width: Dimensions.iconXL,
                        height: Dimensions.iconXL,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: Dimensions.iconM,
                          icon: Icon(
                            Icons.more_vert,
                            color: AppColors.text,
                          ),
                          onSelected: (String value) {
                            if (value == 'Save Recipe') {
                              _toggleSave(recipe);
                            } else if (value == 'Plan Meal') {
                              _togglePlan(recipe);
                            }
                          },
                          color: AppColors.surface,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radiusM),
                          ),
                          offset: const Offset(0, 45),
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              height: 60,
                              value: 'Save Recipe',
                              child: Row(
                                children: [
                                  Icon(
                                    savedStatus[recipe.id] == true
                                        ? Icons.bookmark
                                        : Icons.bookmark_border_rounded,
                                    size: Dimensions.iconM,
                                    color: savedStatus[recipe.id] == true
                                        ? AppColors.primary
                                        : AppColors.text,
                                  ),
                                  SizedBox(width: Dimensions.paddingS),
                                  AppText(
                                    savedStatus[recipe.id] == true
                                        ? 'Saved'
                                        : 'Save Recipe',
                                    fontSize: FontSizes.body,
                                    color: savedStatus[recipe.id] == true
                                        ? AppColors.primary
                                        : AppColors.text,
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              height: 60,
                              value: 'Plan Meal',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: Dimensions.iconM,
                                    color: AppColors.text,
                                  ),
                                  SizedBox(width: Dimensions.paddingS),
                                  AppText(
                                    'Plan Meal',
                                    fontSize: FontSizes.body,
                                    color: AppColors.text,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        recipe.title,
                        fontSize: FontSizes.body,
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: Dimensions.paddingXS),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            color: AppColors.text,
                            size: Dimensions.iconS,
                          ),
                          SizedBox(width: Dimensions.paddingXS),
                          AppText(
                            '${recipe.preparationTime} min',
                            fontSize: FontSizes.caption,
                            color: AppColors.text,
                          ),
                          SizedBox(width: Dimensions.paddingS),
                          Icon(
                            Icons.favorite,
                            color: _getHealthScoreColor(recipe.healthScore),
                            size: Dimensions.iconS,
                          ),
                          SizedBox(width: Dimensions.paddingXS),
                          AppText(
                            recipe.healthScore.toStringAsFixed(1),
                            fontSize: FontSizes.caption,
                            color: _getHealthScoreColor(recipe.healthScore),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
