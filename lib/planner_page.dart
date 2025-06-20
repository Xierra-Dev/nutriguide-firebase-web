import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/planned_recipe.dart';
import 'models/recipe.dart';
import 'services/firestore_service.dart';
import 'recipe_detail_page.dart';
import 'widgets/nutrition_warning_dialog.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';
import 'core/widgets/app_text.dart';
import 'widgets/skeleton_loading.dart';
import 'search_page.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  _PlannerPageState createState() => _PlannerPageState();
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

class _PlannerPageState extends State<PlannerPage> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, List<PlannedMeal>> weeklyMeals = {};
  bool isLoading = true;
  Map<String, bool> madeStatus = {};
  
  AnimationController? _animationController;
  Animation<double> _fadeAnimation = const AlwaysStoppedAnimation(1.0);

  // Track the current week
  DateTime currentSunday = DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7));

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadPlannedMeals().then((_) => _loadMadeStatus());
    _firestoreService.debugNutritionData();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
    
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (weeklyMeals.isNotEmpty) {
      _loadMadeStatus(); // Reload made status when page becomes visible
    }
  }

  Future<void> _viewRecipe(Recipe recipe) async {
    await _firestoreService.addToRecentlyViewed(recipe);
    if (mounted) {
      await Navigator.push(
        context,
        SlideUpRoute(page: RecipeDetailPage(recipe: recipe)),
      );
    }
  }

  Future<void> _loadMadeStatus() async {
    try {
      if (!mounted) return;
      print('Loading made status...');
      
      final newMadeStatus = Map<String, bool>.from(madeStatus);
      final List<Future<void>> futures = [];

      weeklyMeals.forEach((date, meals) {
        for (var meal in meals) {
          final mealKey = '${meal.recipe.id}_${meal.mealType}_${meal.dateKey}';
          if (!newMadeStatus.containsKey(mealKey)) { // Check only if not already loaded
            futures.add(
              _firestoreService.isRecipeMade(mealKey).then((isMade) {
                if (mounted) {
                  newMadeStatus[mealKey] = isMade;
                  print('Made status for $mealKey: $isMade');
                }
              })
            );
          }
        }
      });

      if (futures.isNotEmpty) {
        await Future.wait(futures);
        if (mounted) {
          setState(() {
            madeStatus = newMadeStatus;
          });
        }
      }
    } catch (e) {
      print('Error loading made status: $e');
    }
  }

  Future<void> _loadPlannedMeals() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final meals = await _firestoreService.getPlannedMeals();
      setState(() {
        weeklyMeals = meals;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppColors.text),
                SizedBox(width: Dimensions.paddingS),
                AppText(
                  'Error loading planned meals: $e',
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

  void _changeWeek(int delta) {
    setState(() {
      currentSunday = currentSunday.add(Duration(days: delta * 7));
    });
  }

  Future<void> _toggleMade(PlannedMeal plannedMeal) async {
    try {
      final String mealKey = '${plannedMeal.recipe.id}_${plannedMeal.mealType}_${plannedMeal.dateKey}';
      final bool currentStatus = madeStatus[mealKey] ?? false;

      if (!currentStatus) {
        final nutritionWarnings = await _firestoreService.checkNutritionWarnings(plannedMeal.recipe);
        
        bool shouldWarn = nutritionWarnings.entries.any((entry) => entry.value >= 80);
        
        if (shouldWarn && mounted) {
          final shouldProceed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => Theme(
              data: Theme.of(context).copyWith(
                dialogBackgroundColor: AppColors.surface,
              ),
              child: NutritionWarningDialog(
                nutritionPercentages: nutritionWarnings,
                onProceed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ),
          );

          if (shouldProceed != true) return;
        }

        await _firestoreService.madeRecipe(
          plannedMeal.recipe,
          mealKey: mealKey,
          mealType: plannedMeal.mealType,
          plannedDate: plannedMeal.date,
        );
      } else {
        await _firestoreService.removeMadeRecipe(mealKey);
      }

      if (mounted) {
        setState(() => madeStatus[mealKey] = !currentStatus);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  !currentStatus ? Icons.check_circle : Icons.remove_circle,
                  color: AppColors.text,
                  size: Dimensions.iconM,
                ),
                SizedBox(width: Dimensions.paddingS),
                AppText(
                  !currentStatus 
                    ? 'Recipe marked as made' 
                    : 'Recipe marked as not made',
                  fontSize: FontSizes.body,
                  color: AppColors.text,
                ),
              ],
            ),
            backgroundColor: !currentStatus ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppColors.text, size: Dimensions.iconM),
                SizedBox(width: Dimensions.paddingS),
                AppText(
                  'Error updating recipe status',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildDatePicker(context),
            Expanded(
              child: isLoading 
                ? const PlannerSkeleton()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildMealSchedule(),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(Dimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(Dimensions.radiusL),
          bottomRight: Radius.circular(Dimensions.radiusL),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Meal Planner',
                fontSize: FontSizes.heading2,
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: Dimensions.paddingXS),
              AppText(
                'Plan your meals for the week',
                fontSize: FontSizes.body,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(Dimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
            ),
            child: Icon(
              Icons.calendar_today,
              color: AppColors.primary,
              size: Dimensions.iconM,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final endOfWeek = currentSunday.add(const Duration(days: 6));
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingL,
        vertical: Dimensions.paddingM,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingM,
        vertical: Dimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeWeek(-1),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColors.text,
              size: Dimensions.iconM,
            ),
          ),
          Column(
            children: [
              AppText(
                '${DateFormat('MMM').format(currentSunday)} - ${DateFormat('MMM').format(endOfWeek)}',
                fontSize: FontSizes.heading3,
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: Dimensions.paddingXS),
              AppText(
                '${DateFormat('dd').format(currentSunday)} - ${DateFormat('dd').format(endOfWeek)}',
                fontSize: FontSizes.body,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          IconButton(
            onPressed: () => _changeWeek(1),
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.text,
              size: Dimensions.iconM,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSchedule() {
    return _buildWeekMeals(currentSunday);
  }

  Widget _buildWeekMeals(DateTime sunday) {
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = DateTime(
          sunday.year,
          sunday.month,
          sunday.day + index,
        );
        final dateKey = DateFormat('yyyy-MM-dd').format(day);
        final dayName = DateFormat('EEEE').format(day);
        final dateStr = DateFormat('dd MMM').format(day);

        final meals = weeklyMeals[dateKey] ?? [];

        return Container(
          margin: EdgeInsets.symmetric(
            vertical: Dimensions.paddingS,
            horizontal: Dimensions.paddingM,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Row(
                  children: [
                    AppText(
                      dayName,
                      fontSize: FontSizes.heading3,
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(width: Dimensions.paddingS),
                    AppText(
                      dateStr,
                      fontSize: FontSizes.bodySmall,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.text,
                  size: Dimensions.iconM,
                ),
                onTap: () => _showDayMeals(context, '$dayName, $dateStr', meals),
              ),
              if (meals.isNotEmpty)
                SizedBox(
                  height: ResponsiveHelper.screenHeight(context) * 0.2,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingL),
                    itemCount: meals.length,
                    itemBuilder: (context, mealIndex) {
                      final meal = meals[mealIndex];
                      final mealKey = '${meal.recipe.id}_${meal.mealType}_${meal.dateKey}';
                      
                      return _buildMealCard(meal, mealKey);
                    },
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingL,
                    vertical: Dimensions.paddingM,
                  ),
                  child: AppText(
                    'No meals planned for $dayName, $dateStr',
                    fontSize: FontSizes.body,
                    color: AppColors.textSecondary,
                  ),
                ),
              SizedBox(height: Dimensions.paddingM),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealCard(PlannedMeal meal, String mealKey) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;
    
    return Hero(
      tag: 'recipe-${meal.recipe.id}',
      child: Container(
        width: ResponsiveHelper.screenWidth(context) * (isWeb ? 0.25 : 0.45),
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.3),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _viewRecipe(meal.recipe),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                Expanded(
                  flex: 7,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      children: [
                        Image.network(
                          meal.recipe.image,
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
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: AppText(
                              meal.mealType,
                              fontSize: 10,
                              color: AppColors.text,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
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
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              icon: Icon(
                                Icons.check_circle,
                                color: madeStatus[mealKey] ?? false
                                  ? AppColors.success
                                  : AppColors.text.withOpacity(0.6),
                              ),
                              onPressed: () => _toggleMade(meal),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        meal.recipe.title,
                        fontSize: isWeb ? 14 : 12,
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
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
                                color: AppColors.primary,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              AppText(
                                '${meal.recipe.preparationTime} min',
                                fontSize: 10,
                                color: AppColors.textSecondary,
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
    );
  }

  Future<void> _deletePlannedMeal(PlannedMeal meal, String dayName) async {
    try {
      await _firestoreService.deletePlannedMeal(meal);
      // Reload meals after deletion
      await _loadPlannedMeals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 10),
                Text('Recipe: "${meal.recipe.title}" unplanned'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Text('Error removing meal: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePlannedMealByDay(String dayName) async {
    try {
      // Parse the dayName back to a date
      // Example dayName format: "Monday, 25 Dec"
      final parts = dayName.split(', ');

      // Get the date for the specified day from currentSunday
      final targetDate = currentSunday.add(
        Duration(
          days: [
            'Sunday',
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday'
          ].indexOf(parts[0]),
        ),
      );

      // Format the date to match the dateKey format used in weeklyMeals
      final dateKey = DateFormat('yyyy-MM-dd').format(targetDate);

      // Get all meals for that day
      final mealsForDay = weeklyMeals[dateKey] ?? [];

      // Delete each meal
      for (final meal in mealsForDay) {
        await _firestoreService.deletePlannedMeal(meal);
      }

      // Reload the meals to update the UI
      await _loadPlannedMeals();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 10),
                Text('All meals have been deleted'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Text('Error removing meal: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDayMeals(BuildContext context, String dayName, List<PlannedMeal> meals) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Meals for $dayName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // List of meals
              Expanded(
                child: meals.isEmpty
                    ? Center(
                  child: Text(
                    'No meals planned for $dayName',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            RecipePageRoute(recipe: meal.recipe),
                          );
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Hero(
                            tag: 'recipe-${meal.recipe.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.network(
                                meal.recipe.image,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  meal.recipe.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  meal.mealType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Icon(
                                Icons.timer,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${meal.recipe.preparationTime} min',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _deletePlannedMeal(meal, dayName);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Fixed Delete All Meals button
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: meals.isNotEmpty
                        ? () {
                      // Show confirmation dialog before deleting all meals
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          final isWeb = ResponsiveHelper.screenWidth(context) > 800;
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            child: Container(
                              width: isWeb ? 450 : MediaQuery.of(context).size.width * 0.9,
                              padding: EdgeInsets.all(isWeb ? 32 : 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: isWeb ? 80 : 60,
                                    height: isWeb ? 80 : 60,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red,
                                      size: isWeb ? 40 : 30,
                                    ),
                                  ),
                                  SizedBox(height: isWeb ? 24 : 16),
                                  Text(
                                    'Delete All Meals',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isWeb ? 24 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: isWeb ? 16 : 12),
                                  Text(
                                    'Are you sure you want to delete all meals for this day?\nThis action can\'t be undone',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isWeb ? 16 : 14.5,
                                      height: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: isWeb ? 32 : 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Cancel Button
                                      Expanded(
                                        child: SizedBox(
                                          height: isWeb ? 50 : 45,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(dialogContext).pop();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: EdgeInsets.symmetric(
                                                vertical: isWeb ? 14 : 12
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(25),
                                                side: BorderSide(
                                                  color: Colors.white.withOpacity(0.2),
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontSize: isWeb ? 16 : 14,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: isWeb ? 16 : 12),
                                      // Delete Button
                                      Expanded(
                                        child: SizedBox(
                                          height: isWeb ? 50 : 45,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(dialogContext).pop();
                                              Navigator.of(context).pop();
                                              _deletePlannedMealByDay(dayName);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: EdgeInsets.symmetric(
                                                vertical: isWeb ? 14 : 12
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(25),
                                              ),
                                            ),
                                            child: Text(
                                              'Delete',
                                              style: TextStyle(
                                                fontSize: isWeb ? 16 : 14,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Delete All Meals'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}