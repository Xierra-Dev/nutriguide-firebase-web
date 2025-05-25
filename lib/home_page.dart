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
import 'widgets/notifications_dialog.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';
import 'widgets/skeleton_loading.dart';

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
                begin: const Offset(0.0, 1.0),
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

class _HomePageState extends State<HomePage> {
  // Services
  final TheMealDBService _mealDBService = TheMealDBService();
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final CacheService _cacheService = CacheService();

  // State variables
  Map<String, bool> savedStatus = {};
  Map<String, bool> plannedStatus = {};
  Set<String> hoveredItems = {}; // Changed to Set for individual hover tracking
  List<Recipe> recommendedRecipes = [];
  List<Recipe> popularRecipes = [];
  List<Recipe> recentlyViewedRecipes = [];
  List<Recipe> feedRecipes = [];

  // Loading states
  bool isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingRecentlyViewed = true;
  bool _isLoadingRecommended = true;
  bool _isLoadingPopular = true;
  bool _isLoadingFeed = true;

  String? errorMessage;
  int _currentIndex = 0;

  // Planning dialog state
  DateTime _selectedDate = DateTime.now();
  String _selectedMeal = 'Dinner';
  List<bool> _daysSelected = List.generate(7, (index) => false);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    // Clean up any resources here if needed
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      await _loadRecipes();
      if (mounted) {
        await _loadRecentlyViewedRecipes();
        _checkAllRecipeStatuses();
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

  void _checkAllRecipeStatuses() {
    final allRecipes = [
      ...recommendedRecipes,
      ...popularRecipes,
      ...feedRecipes,
    ];

    for (var recipe in allRecipes) {
      _checkIfSaved(recipe);
      _checkIfPlanned(recipe);
    }
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
    try {
      final saved = await _firestoreService.isRecipeSaved(recipe.id);
      if (mounted) {
        setState(() {
          savedStatus[recipe.id] = saved;
        });
      }
    } catch (e) {
      debugPrint('Error checking save status: $e');
    }
  }

  Future<void> _checkIfPlanned(Recipe recipe) async {
    try {
      final planned = await _firestoreService.isRecipePlanned(recipe.id);
      if (mounted) {
        setState(() {
          plannedStatus[recipe.id] = planned;
        });
      }
    } catch (e) {
      debugPrint('Error checking plan status: $e');
    }
  }

  Future<void> _toggleSave(Recipe recipe) async {
    try {
      final bool currentStatus = savedStatus[recipe.id] ?? false;

      if (currentStatus) {
        await _firestoreService.unsaveRecipe(recipe.id);
      } else {
        await _firestoreService.saveRecipe(recipe);
      }

      if (mounted) {
        setState(() {
          savedStatus[recipe.id] = !currentStatus;
        });

        _showSnackBar(
          icon: savedStatus[recipe.id] == true
              ? Icons.bookmark_added
              : Icons.delete_rounded,
          message: savedStatus[recipe.id] == true
              ? 'Recipe: "${recipe.title}" saved'
              : 'Recipe: "${recipe.title}" removed from saved',
          backgroundColor: AppColors.success,
          iconColor:
              savedStatus[recipe.id] == true ? Colors.deepOrange : Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          icon: Icons.error,
          message: 'Error saving recipe: ${e.toString()}',
          backgroundColor: AppColors.error,
          iconColor: Colors.white,
        );
      }
    }
  }

  Future<void> _togglePlan(Recipe recipe) async {
    try {
      _showPlannedDialog(recipe);
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          icon: Icons.error,
          message: 'Error planning recipe: ${e.toString()}',
          backgroundColor: AppColors.error,
          iconColor: Colors.white,
        );
      }
    }
  }

  void _showSnackBar({
    required IconData icon,
    required String message,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showMealSelectionDialog(
      BuildContext context, StateSetter setDialogState, Recipe recipe) {
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
                  horizontal: Dimensions.paddingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Meal Type',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                          context, FontSizes.heading3),
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
                                context, FontSizes.body),
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
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: ResponsiveHelper.getAdaptiveTextSize(
                                context, FontSizes.body),
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
    _daysSelected = List.generate(7, (index) => false);
    DateTime now = DateTime.now();
    _selectedDate = now.subtract(Duration(days: now.weekday % 7));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.0)),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            setDialogState(() {
                              _selectedDate = _selectedDate
                                  .subtract(const Duration(days: 7));
                            });
                          },
                          icon: const Icon(Icons.arrow_left_rounded, size: 40),
                          color: Colors.white,
                        ),
                        Text(
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
                            setDialogState(() {
                              _selectedDate =
                                  _selectedDate.add(const Duration(days: 7));
                            });
                          },
                          icon: const Icon(Icons.arrow_right_rounded, size: 40),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 60,
                      child: Center(
                        child: InkWell(
                          onTap: () => _showMealSelectionDialog(
                              context, setDialogState, recipe),
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
                                      color: Colors.white, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_drop_down,
                                    color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (int i = 0; i < 7; i++)
                          ChoiceChip(
                            label: Text(
                              DateFormat('EEE, dd').format(
                                _selectedDate.add(Duration(
                                    days: i - _selectedDate.weekday % 7)),
                              ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.red)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_selectedMeal.isEmpty ||
                                !_daysSelected.contains(true)) {
                              _showSnackBar(
                                icon: Icons.warning,
                                message:
                                    'Please select at least one day and a meal type!',
                                backgroundColor: AppColors.accent,
                                iconColor: Colors.white,
                              );
                              return;
                            }
                            _saveSelectedPlan(recipe);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
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
          await _firestoreService.addPlannedRecipe(recipe, _selectedMeal, date);
          successfullyPlannedDates.add(date);
        }
      }

      if (mounted) {
        if (successfullyPlannedDates.isNotEmpty) {
          setState(() {
            plannedStatus[recipe.id] = true;
          });

          _showSnackBar(
            icon: Icons.add_task_rounded,
            message:
                'Recipe planned for ${successfullyPlannedDates.length} day(s)',
            backgroundColor: AppColors.success,
            iconColor: AppColors.text,
          );
        } else {
          _showSnackBar(
            icon: Icons.info,
            message:
                'No new plans were added. All selected plans already exist.',
            backgroundColor: AppColors.info,
            iconColor: AppColors.text,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          icon: Icons.error,
          message: 'Failed to save plan: $e',
          backgroundColor: AppColors.error,
          iconColor: AppColors.text,
        );
      }
    }
  }

  Future<void> _loadRecipes() async {
    try {
      if (_isRefreshing) {
        final futures = await Future.wait([
          _mealDBService.getRecommendedRecipes(),
          _mealDBService.getPopularRecipes(),
          _mealDBService.getFeedRecipes(),
        ]);

        if (mounted) {
          setState(() {
            recommendedRecipes = futures[0];
            popularRecipes = futures[1];
            feedRecipes = futures[2];
            _isLoadingRecommended = false;
            _isLoadingPopular = false;
            _isLoadingFeed = false;
            isLoading = false;
          });

          // Cache the results
          await Future.wait([
            _cacheService.cacheRecipes(
                CacheService.RECOMMENDED_CACHE_KEY, futures[0]),
            _cacheService.cacheRecipes(
                CacheService.POPULAR_CACHE_KEY, futures[1]),
            _cacheService.cacheRecipes(CacheService.FEED_CACHE_KEY, futures[2]),
          ]);
        }
        return;
      }

      // Try loading from cache first
      final cachedResults = await Future.wait([
        _cacheService.getCachedRecipes(CacheService.RECOMMENDED_CACHE_KEY),
        _cacheService.getCachedRecipes(CacheService.POPULAR_CACHE_KEY),
        _cacheService.getCachedRecipes(CacheService.FEED_CACHE_KEY),
      ]);

      bool needsNetworkCall = false;

      if (mounted) {
        setState(() {
          if (cachedResults[0] != null) {
            recommendedRecipes = cachedResults[0]!;
            _isLoadingRecommended = false;
          } else {
            needsNetworkCall = true;
          }

          if (cachedResults[1] != null) {
            popularRecipes = cachedResults[1]!;
            _isLoadingPopular = false;
          } else {
            needsNetworkCall = true;
          }

          if (cachedResults[2] != null) {
            feedRecipes = cachedResults[2]!;
            _isLoadingFeed = false;
          } else {
            needsNetworkCall = true;
          }

          isLoading = _isLoadingRecentlyViewed ||
              _isLoadingRecommended ||
              _isLoadingPopular ||
              _isLoadingFeed;
        });
      }

      // Load missing data from network
      if (needsNetworkCall) {
        final futures = <Future>[];

        if (cachedResults[0] == null) {
          futures.add(_loadRecommendedRecipes());
        }
        if (cachedResults[1] == null) {
          futures.add(_loadPopularRecipes());
        }
        if (cachedResults[2] == null) {
          futures.add(_loadFeedRecipes());
        }

        if (futures.isNotEmpty) {
          await Future.wait(futures);
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

  Future<void> _loadRecentlyViewedRecipes() async {
    try {
      final recipes = await _firestoreService.getRecentlyViewedRecipes();
      if (mounted) {
        setState(() {
          recentlyViewedRecipes = recipes;
          _isLoadingRecentlyViewed = false;
          _updateLoadingState();
        });
      }
    } catch (e) {
      debugPrint('Error loading recently viewed recipes: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecentlyViewed = false;
          _updateLoadingState();
        });
      }
    }
  }

  Future<void> _loadRecommendedRecipes() async {
    try {
      final recipes = await _mealDBService.getRecommendedRecipes();
      if (mounted) {
        setState(() {
          recommendedRecipes = recipes;
          _isLoadingRecommended = false;
          _updateLoadingState();
        });
        await _cacheService.cacheRecipes(
            CacheService.RECOMMENDED_CACHE_KEY, recipes);
      }
    } catch (e) {
      debugPrint('Error loading recommended recipes: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecommended = false;
          _updateLoadingState();
        });
      }
    }
  }

  Future<void> _loadPopularRecipes() async {
    try {
      final recipes = await _mealDBService.getPopularRecipes();
      if (mounted) {
        setState(() {
          popularRecipes = recipes;
          _isLoadingPopular = false;
          _updateLoadingState();
        });
        await _cacheService.cacheRecipes(
            CacheService.POPULAR_CACHE_KEY, recipes);
      }
    } catch (e) {
      debugPrint('Error loading popular recipes: $e');
      if (mounted) {
        setState(() {
          _isLoadingPopular = false;
          _updateLoadingState();
        });
      }
    }
  }

  Future<void> _loadFeedRecipes() async {
    try {
      final recipes = await _mealDBService.getFeedRecipes();
      if (mounted) {
        setState(() {
          feedRecipes = recipes;
          _isLoadingFeed = false;
          _updateLoadingState();
        });
        await _cacheService.cacheRecipes(CacheService.FEED_CACHE_KEY, recipes);
      }
    } catch (e) {
      debugPrint('Error loading feed recipes: $e');
      if (mounted) {
        setState(() {
          _isLoadingFeed = false;
          _updateLoadingState();
        });
      }
    }
  }

  void _updateLoadingState() {
    isLoading = _isLoadingRecentlyViewed ||
        _isLoadingRecommended ||
        _isLoadingPopular ||
        _isLoadingFeed;
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
      errorMessage = null;
      _isLoadingRecentlyViewed = true;
      _isLoadingRecommended = true;
      _isLoadingPopular = true;
      _isLoadingFeed = true;
    });

    await Future.wait([
      _loadRecipes(),
      _loadRecentlyViewedRecipes(),
    ]);

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _handleNavigationTap(int index) async {
    if (!mounted) return;

    if (_currentIndex == index) {
      _refreshIndicatorKey.currentState?.show();
      await _handleRefresh();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<void> _viewRecipe(Recipe recipe) async {
    try {
      await _firestoreService.addToRecentlyViewed(recipe);
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipe: recipe),
          ),
        );

        if (result == true) {
          await _loadRecentlyViewedRecipes();
        }
      }
    } catch (e) {
      debugPrint('Error viewing recipe: $e');
    }
  }

  Future<bool> _showExitDialog() async {
    if (!mounted) return false;

    return await showDialog<bool>(
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
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                          context, FontSizes.heading3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingM),
                  Text(
                    'Are you sure you want to exit the app?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                          context, FontSizes.body),
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
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusM),
                              side: BorderSide(
                                color: AppColors.primary.withOpacity(0.5),
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: ResponsiveHelper.getAdaptiveTextSize(
                                  context, FontSizes.body),
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
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusM),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Exit',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: ResponsiveHelper.getAdaptiveTextSize(
                                  context, FontSizes.body),
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
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return WillPopScope(
      onWillPop: _showExitDialog,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            if (isWeb) _buildWebNavbar() else _buildAppBar(),
            Expanded(
              child: Row(
                children: [
                  if (isWeb) _buildWebSidebar(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
            if (!isWeb) _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    if (_currentIndex != 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingM,
        vertical: Dimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/logo_NutriGuide.png',
                  width: Dimensions.iconXL,
                  height: Dimensions.iconXL,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: Dimensions.iconXL,
                    height: Dimensions.iconXL,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: Dimensions.iconM,
                    ),
                  ),
                ),
                SizedBox(width: Dimensions.paddingS),
                Text(
                  'NutriGuide',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context, FontSizes.heading2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: AppColors.text,
                size: Dimensions.iconM,
              ),
              onPressed: () {
                final RenderBox button =
                    context.findRenderObject() as RenderBox;
                final Offset offset = button.localToGlobal(Offset.zero);
                final RelativeRect position = RelativeRect.fromLTRB(
                  offset.dx,
                  offset.dy + button.size.height,
                  offset.dx + button.size.width,
                  offset.dy + button.size.height,
                );
                NotificationsDialog.show(context, position);
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
        ),
      ),
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
          child: isLoading ? const SearchSkeleton() : const SearchPage(),
        );
      case 2:
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: isLoading ? const PlannerSkeleton() : const PlannerPage(),
        );
      case 3:
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: isLoading ? const SavedSkeleton() : const SavedPage(),
        );
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildMoreButton(Recipe recipe) {
    return Container(
      width: 32,
      height: 32,
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
        iconSize: 18,
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (String value) {
          if (value == 'Save Recipe') {
            _toggleSave(recipe);
          } else if (value == 'Plan Meal') {
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
            height: 48,
            value: 'Save Recipe',
            child: Row(
              children: [
                Icon(
                  savedStatus[recipe.id] == true
                      ? Icons.bookmark
                      : Icons.bookmark_border_rounded,
                  size: 18,
                  color: savedStatus[recipe.id] == true
                      ? AppColors.primary
                      : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  savedStatus[recipe.id] == true ? 'Saved' : 'Save Recipe',
                  style: TextStyle(
                    fontSize: 14,
                    color: savedStatus[recipe.id] == true
                        ? AppColors.primary
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            height: 48,
            value: 'Plan Meal',
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Plan Meal',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSection(String title, List<Recipe> recipes) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? Dimensions.paddingXL : Dimensions.paddingL,
            vertical: Dimensions.paddingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: ResponsiveHelper.getAdaptiveTextSize(
                      context, isWeb ? FontSizes.heading2 : FontSizes.heading3),
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    SlideLeftRoute(
                        page: AllRecipesPage(title: title, recipes: recipes)),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context, isWeb ? FontSizes.body : FontSizes.caption),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Dimensions.paddingS),
        SizedBox(
          height: isWeb ? 320 : ResponsiveHelper.screenHeight(context) * 0.3,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
                horizontal: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              final itemId = '${title}_${recipe.id}';

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) {
                  setState(() {
                    hoveredItems.add(itemId);
                  });
                },
                onExit: (_) {
                  setState(() {
                    hoveredItems.remove(itemId);
                  });
                },
                child: GestureDetector(
                  onTap: () => _viewRecipe(recipe),
                  child: AnimatedScale(
                    scale: hoveredItems.contains(itemId) ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Hero(
                      tag: 'recipe-${recipe.id}',
                      child: Container(
                        width: isWeb
                            ? 280
                            : ResponsiveHelper.screenWidth(context) * 0.525,
                        margin: EdgeInsets.symmetric(
                          horizontal: isWeb
                              ? Dimensions.paddingS
                              : Dimensions.paddingXS,
                          vertical: Dimensions.paddingXS,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black.withOpacity(0.3),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius:
                                  hoveredItems.contains(itemId) ? 12 : 8,
                              offset: Offset(
                                  0, hoveredItems.contains(itemId) ? 6 : 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: Stack(
                                children: [
                                  Image.network(
                                    recipe.image,
                                    height: isWeb ? 180 : 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      height: isWeb ? 180 : 160,
                                      width: double.infinity,
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.restaurant,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                    ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: isWeb ? 180 : 160,
                                        width: double.infinity,
                                        color: Colors.grey[800],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        recipe.area ?? 'International',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: _buildMoreButton(recipe),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isWeb ? 16 : 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.timer,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${recipe.preparationTime} min',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.favorite,
                                              color: _getHealthScoreColor(
                                                  recipe.healthScore),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              recipe.healthScore
                                                  .toStringAsFixed(1),
                                              style: TextStyle(
                                                color: _getHealthScoreColor(
                                                    recipe.healthScore),
                                                fontSize: 12,
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
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeFeed() {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? Dimensions.paddingXL : Dimensions.paddingL,
            vertical: Dimensions.paddingS,
          ),
          child: Text(
            'Recipe Feed',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveHelper.getAdaptiveTextSize(
                  context, isWeb ? FontSizes.heading2 : FontSizes.heading3),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: Dimensions.paddingS),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWeb ? 3 : 1,
              childAspectRatio: isWeb ? 1.5 : 1.6,
              crossAxisSpacing:
                  isWeb ? Dimensions.paddingM : Dimensions.paddingS,
              mainAxisSpacing:
                  isWeb ? Dimensions.paddingM : Dimensions.paddingS,
            ),
            itemCount: feedRecipes.length,
            itemBuilder: (context, index) {
              final recipe = feedRecipes[index];
              final itemId = 'feed_${recipe.id}';

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) {
                  setState(() {
                    hoveredItems.add(itemId);
                  });
                },
                onExit: (_) {
                  setState(() {
                    hoveredItems.remove(itemId);
                  });
                },
                child: GestureDetector(
                  onTap: () => _viewRecipe(recipe),
                  child: AnimatedScale(
                    scale: hoveredItems.contains(itemId) ? 1.03 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withOpacity(0.3),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: hoveredItems.contains(itemId) ? 12 : 8,
                            offset: Offset(
                                0, hoveredItems.contains(itemId) ? 6 : 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.network(
                              recipe.image,
                              height: double.infinity,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: double.infinity,
                                width: double.infinity,
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.restaurant,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: double.infinity,
                                  width: double.infinity,
                                  color: Colors.grey[800],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          recipe.area ?? 'International',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      _buildMoreButton(recipe),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    recipe.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isWeb ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.timer,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${recipe.preparationTime} min',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.favorite,
                                            color: _getHealthScoreColor(
                                                recipe.healthScore),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            recipe.healthScore
                                                .toStringAsFixed(1),
                                            style: TextStyle(
                                              color: _getHealthScoreColor(
                                                  recipe.healthScore),
                                              fontSize: 12,
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleRefresh,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        SizedBox(height: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
        if (_isLoadingRecentlyViewed)
          _buildSkeletonSection('Recently Viewed')
        else if (recentlyViewedRecipes.isNotEmpty)
          _buildRecipeSection('Recently Viewed', recentlyViewedRecipes),
        SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
        if (_isLoadingRecommended)
          _buildSkeletonSection('Recommended')
        else
          _buildRecipeSection('Recommended', recommendedRecipes),
        SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
        if (_isLoadingPopular)
          _buildSkeletonSection('Popular')
        else
          _buildRecipeSection('Popular', popularRecipes),
        SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
        if (_isLoadingFeed)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      isWeb ? Dimensions.paddingXL : Dimensions.paddingL,
                  vertical: Dimensions.paddingS,
                ),
                child: Text(
                  'Recipe Feed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(context,
                        isWeb ? FontSizes.heading2 : FontSizes.heading3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return const RecipeFeedSkeleton();
                },
              ),
            ],
          )
        else
          _buildRecipeFeed(),
        SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
      ],
    );
  }

  Widget _buildSkeletonSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingM,
            vertical: ResponsiveHelper.screenHeight(context) * 0.0015,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: ResponsiveHelper.getAdaptiveTextSize(
                      context, FontSizes.heading3),
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: null,
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context, FontSizes.body),
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
            itemCount: 3,
            itemBuilder: (context, index) {
              return const RecipeCardSkeleton();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Padding(
      padding: EdgeInsets.all(Dimensions.paddingM),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Dimensions.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: Dimensions.paddingM,
                vertical: Dimensions.paddingXS),
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: _buildNavItem(
                      0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                ),
                Flexible(
                  child: _buildNavItem(
                      1, Icons.search_outlined, Icons.search_rounded, 'Search'),
                ),
                SizedBox(width: Dimensions.paddingXS),
                _buildCenterNavItem(),
                SizedBox(width: Dimensions.paddingXS),
                Flexible(
                  child: _buildNavItem(2, Icons.calendar_today_outlined,
                      Icons.calendar_today_rounded, 'Planner'),
                ),
                Flexible(
                  child: _buildNavItem(3, Icons.bookmark_border_rounded,
                      Icons.bookmark_rounded, 'Saved'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterNavItem() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Container(
            width: 120,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8 * value,
                  offset: Offset(0, 4 * value),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    SlideUpRoute(page: const AssistantPage()),
                  );
                },
                borderRadius: BorderRadius.circular(28),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _handleNavigationTap(index),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
        duration: const Duration(milliseconds: 200),
        builder: (context, double value, child) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingXS),
            width: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 1 + (0.2 * value),
                  child: Container(
                    padding: EdgeInsets.all(value * Dimensions.paddingXS),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.transparent,
                        AppColors.primary.withOpacity(0.1),
                        value,
                      ),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      color: Color.lerp(
                        AppColors.textSecondary,
                        AppColors.primary,
                        value,
                      ),
                      size: Dimensions.iconM,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Color.lerp(
                      AppColors.textSecondary,
                      AppColors.primary,
                      value,
                    ),
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(
                            context, FontSizes.caption) -
                        1,
                    fontWeight: FontWeight.lerp(
                      FontWeight.normal,
                      FontWeight.w600,
                      value,
                    ),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebNavbar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingXL,
        vertical: Dimensions.paddingM,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/logo_NutriGuide.png',
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.restaurant,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  SizedBox(width: Dimensions.paddingM),
                  const Text(
                    'NutriGuide',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWebNavItem(0, Icons.home_rounded, 'Home'),
                _buildWebNavItem(1, Icons.search_rounded, 'Search'),
                _buildWebNavItem(2, Icons.calendar_today_rounded, 'Planner'),
                _buildWebNavItem(3, Icons.bookmark_rounded, 'Saved'),
              ],
            ),
          ),
          SizedBox(width: Dimensions.paddingL),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    SlideUpRoute(page: const AssistantPage()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: Dimensions.paddingM),
          _buildWebActionButton(
            Icons.notifications_outlined,
            () {
              final RenderBox button = context.findRenderObject() as RenderBox;
              final Offset offset = button.localToGlobal(Offset.zero);
              final RelativeRect position = RelativeRect.fromLTRB(
                offset.dx,
                offset.dy + button.size.height,
                offset.dx + button.size.width,
                offset.dy + button.size.height,
              );
              NotificationsDialog.show(context, position);
            },
          ),
          _buildWebActionButton(
            Icons.person,
            () {
              Navigator.push(
                context,
                SlideLeftRoute(page: const ProfilePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebActionButton(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNavigationTap(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border(
          right: BorderSide(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.assistant_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Assistant',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get personalized recipe recommendations',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildSidebarSection(
              'Discover',
              [
                _buildSidebarItem(
                  icon: Icons.explore_rounded,
                  label: 'Explore Recipes',
                  onTap: () {},
                ),
                _buildSidebarItem(
                  icon: Icons.trending_up_rounded,
                  label: 'Trending Now',
                  onTap: () {},
                ),
                _buildSidebarItem(
                  icon: Icons.new_releases_rounded,
                  label: 'New Recipes',
                  onTap: () {},
                ),
              ],
            ),
            Divider(color: Colors.white.withOpacity(0.1)),
            _buildSidebarSection(
              'Meal Types',
              [
                _buildSidebarItem(
                  icon: Icons.local_cafe_rounded,
                  label: 'Breakfast & Brunch',
                  onTap: () {},
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber[700]!,
                      Colors.amber[700]!.withOpacity(0.7)
                    ],
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.restaurant_rounded,
                  label: 'Main Course',
                  onTap: () {},
                  gradient: LinearGradient(
                    colors: [
                      Colors.red[700]!,
                      Colors.red[700]!.withOpacity(0.7)
                    ],
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.local_pizza_rounded,
                  label: 'Appetizers & Snacks',
                  onTap: () {},
                  gradient: LinearGradient(
                    colors: [
                      Colors.green[700]!,
                      Colors.green[700]!.withOpacity(0.7)
                    ],
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.icecream_rounded,
                  label: 'Desserts',
                  onTap: () {},
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple[700]!,
                      Colors.purple[700]!.withOpacity(0.7)
                    ],
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.local_bar_rounded,
                  label: 'Drinks & Beverages',
                  onTap: () {},
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue[700]!,
                      Colors.blue[700]!.withOpacity(0.7)
                    ],
                  ),
                ),
              ],
            ),
            Divider(color: Colors.white.withOpacity(0.1)),
            _buildSidebarSection(
              'Dietary',
              [
                _buildSidebarItem(
                  icon: Icons.eco_rounded,
                  label: 'Vegetarian',
                  onTap: () {},
                  gradient: LinearGradient(
                    colors: [
                      Colors.lightGreen[700]!,
                      Colors.lightGreen[700]!.withOpacity(0.7)
                    ],
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.spa_rounded,
                  label: 'Vegan',
                  onTap: () {},
                  gradient: LinearGradient(
                    colors: [
                      Colors.teal[700]!,
                      Colors.teal[700]!.withOpacity(0.7)
                    ],
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.fitness_center_rounded,
                  label: 'High Protein',
                  onTap: () {},
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepOrange[700]!,
                      Colors.deepOrange[700]!.withOpacity(0.7)
                    ],
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.favorite_rounded,
                  label: 'Heart Healthy',
                  onTap: () {},
                  gradient: LinearGradient(
                    colors: [
                      Colors.pink[700]!,
                      Colors.pink[700]!.withOpacity(0.7)
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimensions.paddingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Gradient? gradient,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: gradient,
                  color:
                      gradient == null ? Colors.white.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurvedPainter extends CustomPainter {
  final int selectedIndex;
  final Color color;

  CurvedPainter({required this.selectedIndex, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path();

    final itemWidth = size.width / 4;
    final curveHeight = 20.0;

    path.moveTo(0, 0);
    path.lineTo(itemWidth * selectedIndex, 0);

    path.quadraticBezierTo(
      itemWidth * selectedIndex + itemWidth / 2,
      curveHeight,
      itemWidth * (selectedIndex + 1),
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
