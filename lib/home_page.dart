import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'services/themealdb_service.dart';
import 'services/firestore_service.dart';
import 'recipe_detail_page.dart';
import 'all_recipes_page.dart';
import 'search_page.dart';
import 'saved_page.dart';
import 'profile_page.dart';
import 'planner_page.dart';
import 'package:intl/intl.dart';
import 'services/cache_service.dart';
import 'assistant_page.dart';
import 'home_notifications_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class SlideLeftRoute extends PageRouteBuilder {
  final Widget page;

  SlideLeftRoute({required this.page})
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
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: primaryAnimation,
                curve: Curves.easeOutQuad,
              )),
              child: child,
            );
          },
        );
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

class _HomePageState extends State<HomePage> {
  final TheMealDBService _mealDBService = TheMealDBService();
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final CacheService _cacheService = CacheService();
  Map<String, bool> savedStatus = {};
  Map<String, bool> plannedStatus = {};
  List<Recipe> recommendedRecipes = [];
  List<Recipe> popularRecipes = [];
  List<Recipe> recentlyViewedRecipes = [];
  List<Recipe> feedRecipes = [];
  bool isLoading = true;
  bool _isRefreshing = false;
  final bool _isFirstTimeLoading = true;
  String? errorMessage;
  int _currentIndex = 0;

  DateTime _selectedDate = DateTime.now();
  String _selectedMeal = 'Dinner';
  List<bool> _daysSelected = List.generate(7, (index) => false);

  @override
  void initState() {
    super.initState();
    _loadRecipes().then((_) {
      // After recipes are loaded, check saved status for each recipe
      for (var recipe in recommendedRecipes) {
        _checkIfSaved(recipe);
        _checkIfPlanned(recipe);
      }
      for (var recipe in popularRecipes) {
        _checkIfSaved(recipe);
        _checkIfPlanned(recipe);
      }
      for (var recipe in feedRecipes) {
        _checkIfSaved(recipe);
        _checkIfPlanned(recipe);
      }
    });
    _loadRecentlyViewedRecipes();
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

  Future<void> _checkIfSaved(Recipe recipe) async {
    final saved = await _firestoreService.isRecipeSaved(recipe.id);
    setState(() {
      savedStatus[recipe.id] = saved;
    });
  }

  Future<void> _checkIfPlanned(Recipe recipe) async {
    final planned = await _firestoreService.isRecipePlanned(recipe.id);
    setState(() {
      plannedStatus[recipe.id] = planned;
    });
  }

  Future<void> _toggleSave(Recipe recipe) async {
    try {
      final bool currentStatus = savedStatus[recipe.id] ?? false;

      if (savedStatus[recipe.id] == true) {
        await _firestoreService.unsaveRecipe(recipe.id);
      } else {
        await _firestoreService.saveRecipe(recipe);
      }
      setState(() {
        savedStatus[recipe.id] = !currentStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                  savedStatus[recipe.id] == true
                      ? Icons.bookmark_added
                      : Icons.delete_rounded,
                  color: savedStatus[recipe.id] == true
                      ? Colors.deepOrange
                      : Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  savedStatus[recipe.id] == true
                      ? 'Recipe: "${recipe.title}" saved'
                      : 'Recipe: "${recipe.title}" removed from saved',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Error plan recipe: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
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

  void _showMealSelectionDialog(
    BuildContext context,
    StateSetter setDialogState,
    Recipe recipe
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusL),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter mealSetState) {
            return Padding(
              padding: EdgeInsets.symmetric(
                vertical: Dimensions.paddingXL,
                horizontal: Dimensions.paddingL
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Meal Type',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context,
                        FontSizes.heading3
                      ),
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: Dimensions.paddingM),
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
                            color: AppColors.text,
                            fontSize: ResponsiveHelper.getAdaptiveTextSize(
                              context,
                              FontSizes.body
                            ),
                          ),
                        ),
                        onTap: () {
                          setDialogState(() {
                            _selectedMeal = mealType;
                          });
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _showPlannedDialog(recipe);
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: Dimensions.paddingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: ResponsiveHelper.getAdaptiveTextSize(
                              context,
                              FontSizes.body
                            ),
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

  void _showPlannedDialog(Recipe recipe) {
    // Reset selected days
    _daysSelected = List.generate(7, (index) => false);

    // Get the start of week (Sunday)
    DateTime now = DateTime.now();
    _selectedDate = now.subtract(Duration(days: now.weekday % 7));

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusL),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Padding(
              padding: EdgeInsets.symmetric(
                vertical: Dimensions.paddingL,
                horizontal: Dimensions.paddingL
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Day',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context,
                        FontSizes.heading3
                      ),
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: Dimensions.paddingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                          });
                        },
                        icon: Icon(
                          Icons.arrow_left_rounded,
                          size: Dimensions.iconXL,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        '${DateFormat('MMM dd').format(_selectedDate)} - '
                        '${DateFormat('MMM dd').format(_selectedDate.add(const Duration(days: 6)))}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveTextSize(
                            context,
                            FontSizes.body
                          ),
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            _selectedDate = _selectedDate.add(const Duration(days: 7));
                          });
                        },
                        icon: Icon(
                          Icons.arrow_right_rounded,
                          size: Dimensions.iconXL,
                          color: AppColors.text,
                        ),
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
                                      0.05, // Adjust font size based on screen width
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
  Future<void> _saveSelectedPlan(Recipe recipe) async {
    try {
      List<DateTime> selectedDates = [];
      List<DateTime> successfullyPlannedDates = [];

      for (int i = 0; i < _daysSelected.length; i++) {
        if (_daysSelected[i]) {
          DateTime selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day + i,
          );
          selectedDates.add(selectedDate);
        }
      }

      for (DateTime date in selectedDates) {
        bool exists = await _firestoreService.checkIfPlanExists(
          recipe.id,
          _selectedMeal,
          date,
        );

        if (!exists) {
          await _firestoreService.addPlannedRecipe(
            recipe,
            _selectedMeal,
            date,
          );
          successfullyPlannedDates.add(date);
        }
      }

      if (mounted) {
        if (successfullyPlannedDates.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.add_task_rounded,
                    color: AppColors.text,
                    size: Dimensions.iconM,
                  ),
                  SizedBox(width: Dimensions.paddingS),
                  Text(
                    'Recipe planned for ${successfullyPlannedDates.length} day(s)',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context,
                        FontSizes.body
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: AppColors.text,
                    size: Dimensions.iconM,
                  ),
                  SizedBox(width: Dimensions.paddingS),
                  Expanded(
                    child: Text(
                      'No new plans were added. All selected plans already exist.',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveTextSize(
                          context,
                          FontSizes.body
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.info,
            ),
          );
        }

        setState(() {
          plannedStatus[recipe.id] = true;
        });
      }
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
                Expanded(
                  child: Text(
                    'Failed to save plan: $e',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context,
                        FontSizes.body
                      ),
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadRecipes() async {
    try {
      if (_isRefreshing) {
        final recommended = await _mealDBService.getRecommendedRecipes();
        final popular = await _mealDBService.getPopularRecipes();
        final feed = await _mealDBService.getFeedRecipes();

        await _cacheService.cacheRecipes(
          CacheService.RECOMMENDED_CACHE_KEY,
          recommended
        );
        await _cacheService.cacheRecipes(
          CacheService.POPULAR_CACHE_KEY,
          popular
        );
        await _cacheService.cacheRecipes(
          CacheService.FEED_CACHE_KEY,
          feed
        );

        if (mounted) {
          setState(() {
            recommendedRecipes = recommended;
            popularRecipes = popular;
            feedRecipes = feed;
            isLoading = false;
          });
        }
        return;
      }

      final cachedRecommended = await _cacheService.getCachedRecipes(
        CacheService.RECOMMENDED_CACHE_KEY
      );
      final cachedPopular = await _cacheService.getCachedRecipes(
        CacheService.POPULAR_CACHE_KEY
      );
      final cachedFeed = await _cacheService.getCachedRecipes(
        CacheService.FEED_CACHE_KEY
      );

      if (cachedRecommended != null &&
          cachedPopular != null &&
          cachedFeed != null) {
        setState(() {
          recommendedRecipes = cachedRecommended;
          popularRecipes = cachedPopular;
          feedRecipes = cachedFeed;
          isLoading = false;
        });
      } else {
        final recommended = await _mealDBService.getRecommendedRecipes();
        final popular = await _mealDBService.getPopularRecipes();
        final feed = await _mealDBService.getFeedRecipes();

        await _cacheService.cacheRecipes(
          CacheService.RECOMMENDED_CACHE_KEY,
          recommended
        );
        await _cacheService.cacheRecipes(
          CacheService.POPULAR_CACHE_KEY,
          popular
        );
        await _cacheService.cacheRecipes(
          CacheService.FEED_CACHE_KEY,
          feed
        );

        if (mounted) {
          setState(() {
            recommendedRecipes = recommended;
            popularRecipes = popular;
            feedRecipes = feed;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
      errorMessage = null;
    });

    await _loadRecipes();
    await _loadRecentlyViewedRecipes();

    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _handleNavigationTap(int index) async {
    if (_currentIndex == index) {
      switch (index) {
        case 0:
        case 1:
        case 2:
        case 3:
          _refreshIndicatorKey.currentState?.show();
          await _handleRefresh();
          break;
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<void> _loadRecentlyViewedRecipes() async {
    try {
      final recipes = await _firestoreService.getRecentlyViewedRecipes();
      if (mounted) {
        setState(() {
          recentlyViewedRecipes = recipes;
        });
      }
    } catch (e) {
      print('Error loading recently viewed recipes: $e');
    }
  }

  void _viewRecipe(Recipe recipe) async {
    await _firestoreService.addToRecentlyViewed(recipe);
    if (mounted) {
      await Navigator.push(
        context,
        SlideUpRoute(page: RecipeDetailPage(recipe: recipe)),
      );
      await _loadRecentlyViewedRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(Dimensions.paddingL),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(Dimensions.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      color: AppColors.primary,
                      size: Dimensions.iconXL,
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingL),
                  Text(
                    'Exit NutriGuide',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingM),
                  Text(
                    'Are you sure you want to exit the app?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingXL),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: Dimensions.paddingM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Dimensions.radiusM),
                              side: BorderSide(
                                color: AppColors.primary.withOpacity(0.5),
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: Dimensions.spacingM),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(
                              vertical: Dimensions.paddingM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Dimensions.radiusM),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Exit',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ?? false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _currentIndex != 1 
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  SlideUpRoute(page: const AssistantPage()),
                );
              },
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.chat_bubble_rounded,
                color: AppColors.surface,
                size: Dimensions.iconM,
              ),
            ) 
          : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  AppBar? _buildAppBar() {
    if (_currentIndex != 0) return null;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo_NutriGuide.png',
            width: Dimensions.iconXL,
            height: Dimensions.iconXL,
          ),
          SizedBox(width: Dimensions.paddingS),
          Text(
            'NutriGuide',
            style: TextStyle(
              color: AppColors.text,
              fontSize: ResponsiveHelper.getAdaptiveTextSize(
                context, 
                FontSizes.heading2
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined, 
            color: AppColors.text,
            size: Dimensions.iconM,
          ),
          onPressed: () {
            Navigator.push(
              context,
              SlideLeftRoute(page: const HomeNotificationsPage()),
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.person, 
            color: AppColors.text,
            size: Dimensions.iconM,
          ),
          onPressed: () {
            Navigator.push(
              context,
              SlideLeftRoute(page: const ProfilePage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: _buildHomeContent(),
        );
      case 1:
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: const SearchPage(),
        );
      case 2:
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: const PlannerPage(),
        );
      case 3:
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: const SavedPage(),
        );
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildRecipeSection(String title, List<Recipe> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingM,
            vertical: Dimensions.paddingS
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: ResponsiveHelper.getAdaptiveTextSize(
                    context,
                    FontSizes.heading3
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    SlideLeftRoute(
                      page: AllRecipesPage(title: title, recipes: recipes)
                    ),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(
                      context,
                      FontSizes.body
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: ResponsiveHelper.screenHeight(context) * 0.3,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return GestureDetector(
                onTap: () => _viewRecipe(recipe),
                child: Container(
                  width: ResponsiveHelper.screenWidth(context) * 0.5,
                  margin: EdgeInsets.only(
                    left: Dimensions.paddingM,
                    bottom: Dimensions.paddingM
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    image: DecorationImage(
                      image: NetworkImage(recipe.image),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Gradient overlay
                      Container(
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
                      ),
                      // Content
                      Padding(
                        padding: EdgeInsets.all(Dimensions.paddingM),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row with area tag and more button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingS,
                                    vertical: Dimensions.paddingXS
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(Dimensions.radiusS),
                                  ),
                                  child: Text(
                                    recipe.area ?? 'International',
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                                        context,
                                        FontSizes.caption
                                      ),
                                    ),
                                  ),
                                ),
                                _buildMoreButton(recipe),
                              ],
                            ),
                            // Bottom info
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.title,
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: ResponsiveHelper.getAdaptiveTextSize(
                                      context,
                                      FontSizes.body
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: Dimensions.paddingXS),
                                _buildRecipeInfo(recipe),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoreButton(Recipe recipe) {
    return Container(
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
        constraints: BoxConstraints(
          minWidth: ResponsiveHelper.screenWidth(context) * 0.4,
          maxWidth: ResponsiveHelper.screenWidth(context) * 0.4,
        ),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            height: 60,
            value: 'Save Recipe',
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
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
                  Text(
                    savedStatus[recipe.id] == true ? 'Saved' : 'Save Recipe',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context,
                        FontSizes.body
                      ),
                      color: savedStatus[recipe.id] == true
                          ? AppColors.primary
                          : AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuItem<String>(
            height: 60,
            value: 'Plan Meal',
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: Dimensions.iconM,
                    color: AppColors.text,
                  ),
                  SizedBox(width: Dimensions.paddingS),
                  Text(
                    'Plan Meal',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context,
                        FontSizes.body
                      ),
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeInfo(Recipe recipe) {
    return Row(
      children: [
        Icon(
          Icons.timer,
          color: AppColors.text,
          size: Dimensions.iconS,
        ),
        SizedBox(width: Dimensions.paddingXS),
        Text(
          '${recipe.preparationTime} min',
          style: TextStyle(
            color: AppColors.text,
            fontSize: ResponsiveHelper.getAdaptiveTextSize(
              context,
              FontSizes.caption
            ),
          ),
        ),
        const Spacer(),
        Icon(
          Icons.favorite,
          color: _getHealthScoreColor(recipe.healthScore),
          size: Dimensions.iconS,
        ),
        SizedBox(width: Dimensions.paddingXS),
        Text(
          recipe.healthScore.toStringAsFixed(1),
          style: TextStyle(
            color: _getHealthScoreColor(recipe.healthScore),
            fontSize: ResponsiveHelper.getAdaptiveTextSize(
              context,
              FontSizes.caption
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    if (_isFirstTimeLoading && isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    } else if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: Dimensions.iconXL * 2,
            ),
            SizedBox(height: Dimensions.paddingM),
            Text(
              'Oops! Something Went Wrong',
              style: TextStyle(
                color: AppColors.text,
                fontSize: ResponsiveHelper.getAdaptiveTextSize(
                  context,
                  FontSizes.heading3
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Dimensions.paddingS),
            Text(
              errorMessage!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: ResponsiveHelper.getAdaptiveTextSize(
                  context,
                  FontSizes.body
                ),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Dimensions.paddingM),
            ElevatedButton(
              onPressed: _handleRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingL,
                  vertical: Dimensions.paddingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveTextSize(
                    context,
                    FontSizes.body
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (recentlyViewedRecipes.isNotEmpty) ...[
          _buildRecipeSection('Recently Viewed', recentlyViewedRecipes),
          SizedBox(height: Dimensions.paddingM),
        ],
        _buildRecipeSection('Recommended', recommendedRecipes),
        SizedBox(height: Dimensions.paddingM),
        _buildRecipeSection('Popular', popularRecipes),
        SizedBox(height: Dimensions.paddingM),
        _buildRecipeFeed(),
      ],
    );
  }

  Widget _buildRecipeFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Recipe Feed',
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width *
                  0.05, // Adjust font size based on screen width
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: feedRecipes.length,
          itemBuilder: (context, index) {
            final recipe = feedRecipes[index];
            return GestureDetector(
              onTap: () => _viewRecipe(recipe),
              child: Container(
                height: 250,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(recipe.image),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: MediaQuery.of(context).size.width *
                                  0.05, // Adjust font size based on screen width
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Health Score: ${recipe.healthScore.toStringAsFixed(1)}',
                                style: TextStyle(
                                  color:
                                      _getHealthScoreColor(recipe.healthScore),
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.04, // Adjust font size based on screen width
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timer,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${recipe.preparationTime} min',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.04,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(recipe.area ?? 'International',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.03, // Adjust font size based on screen width
                                )),
                          ),
                          Container(
                            width: 32.5,
                            height: 32.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              iconSize: 24,
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                              ),
                              onSelected: (String value) {
                                if (value == 'Save Recipe') {
                                  _toggleSave(recipe);
                                } else if (value == 'Plan Meal') {
                                  _togglePlan(recipe);
                                }
                              },
                              color: Colors.grey[900],
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              offset: const Offset(0, 45),
                              constraints: const BoxConstraints(
                                minWidth: 175, // Makes popup menu wider
                                maxWidth: 175,
                              ),
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  height: 60, // Makes item taller
                                  value: 'Save Recipe',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Icon(
                                          savedStatus[recipe.id] == true
                                              ? Icons.bookmark
                                              : Icons.bookmark_border_rounded,
                                          size: 22,
                                          color: savedStatus[recipe.id] == true
                                              ? Colors.deepOrange
                                              : Colors
                                                  .white, // Mengubah warna icon menjadi putih
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          savedStatus[recipe.id] == true
                                              ? 'Saved'
                                              : 'Save Recipe',
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.04, // Adjust font size based on screen width
                                            color: savedStatus[recipe.id] ==
                                                    true
                                                ? Colors.deepOrange
                                                : Colors
                                                    .white, // Change text color based on savedStatus
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  height: 60, // Makes item taller
                                  value: 'Plan Meal',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Plan Meal',
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.04, // Adjust font size based on screen width
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _handleNavigationTap,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home_outlined,
            size: Dimensions.iconM,
          ),
          activeIcon: Icon(
            Icons.home_rounded,
            size: Dimensions.iconM,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.search_outlined,
            size: Dimensions.iconM,
          ),
          activeIcon: Icon(
            Icons.search_rounded,
            size: Dimensions.iconM,
          ),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.calendar_today_outlined,
            size: Dimensions.iconM,
          ),
          activeIcon: Icon(
            Icons.calendar_today_rounded,
            size: Dimensions.iconM,
          ),
          label: 'Planner',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.bookmark_border_rounded,
            size: Dimensions.iconM,
          ),
          activeIcon: Icon(
            Icons.bookmark_rounded,
            size: Dimensions.iconM,
          ),
          label: 'Saved',
        ),
      ],
      selectedLabelStyle: TextStyle(
        fontSize: ResponsiveHelper.getAdaptiveTextSize(
          context,
          FontSizes.caption
        ),
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: ResponsiveHelper.getAdaptiveTextSize(
          context,
          FontSizes.caption
        ),
      ),
    );
  }
}
