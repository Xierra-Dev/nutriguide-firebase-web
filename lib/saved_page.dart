import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'services/firestore_service.dart';
import 'recipe_detail_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/widgets/app_text.dart';
import 'package:intl/intl.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  _SavedPageState createState() => _SavedPageState();
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
          begin: const Offset(0.0, 1.0),  // Start from bottom
          end: Offset.zero,  // End at the center
        ).animate(CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.easeOutQuad,
        )),
        child: child,
      );
    },
  );
}

class _SavedPageState extends State<SavedPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Recipe> savedRecipes = [];
  bool isLoading = true;
  String? errorMessage;
  String sortBy = 'Date Added';

  @override
  void initState() {
    super.initState();
    _loadSavedRecipes();
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
        MaterialPageRoute(builder: (context) => RecipeDetailPage(recipe: recipe)),
      );
      _loadSavedRecipes(); // Reload in case of changes
    }
  }

  Future<void> _loadSavedRecipes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final recipes = await _firestoreService.getSavedRecipes();
      if (mounted) {
        setState(() {
          savedRecipes = recipes;
          isLoading = false;
        });
        _sortRecipes();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load saved recipes';
          isLoading = false;
        });
        _showErrorSnackBar('Error loading saved recipes');
      }
    }
  }

  void _sortRecipes() {
    setState(() {
      switch (sortBy) {
        case 'Name':
          savedRecipes.sort((a, b) => a.title.compareTo(b.title));
          break;
        case 'Rating':
          savedRecipes.sort((a, b) => b.healthScore.compareTo(a.healthScore));
          break;
        case 'Time':
          savedRecipes.sort((a, b) => a.preparationTime.compareTo(b.preparationTime));
          break;
        case 'Date Added':
        default:
          // Already sorted by date from Firestore
          break;
      }
    });
  }

  Future<void> _removeSavedRecipe(Recipe recipe) async {
    try {
      await _firestoreService.removeFromSavedRecipes(recipe);
      
      if (mounted) {
        setState(() {
          savedRecipes.removeWhere((r) => r.id == recipe.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.text, size: Dimensions.iconM),
                SizedBox(width: Dimensions.paddingS),
                AppText(
                  'Recipe removed from saved',
                  fontSize: FontSizes.body,
                  color: AppColors.text,
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppColors.text,
              onPressed: () => _undoRemove(recipe),
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to remove recipe');
    }
  }

  Future<void> _undoRemove(Recipe recipe) async {
    try {
      await _firestoreService.saveRecipe(recipe);
      _loadSavedRecipes();
    } catch (e) {
      _showErrorSnackBar('Failed to restore recipe');
    }
  }

  Future<void> _showPlanMealDialog(Recipe recipe) async {
    final DateTime now = DateTime.now();
    DateTime selectedDate = now;
    String selectedMealType = 'Lunch';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: AppColors.surface,
          ),
          child: AlertDialog(
            title: AppText(
              'Plan Meal',
              fontSize: FontSizes.heading3,
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: AppText(
                        'Date',
                        fontSize: FontSizes.body,
                        color: AppColors.text,
                      ),
                      subtitle: AppText(
                        DateFormat('MMM d, y').format(selectedDate),
                        fontSize: FontSizes.caption,
                        color: AppColors.primary,
                      ),
                      trailing: Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                        size: Dimensions.iconM,
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: AppColors.primary,
                                  surface: AppColors.surface,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                    ListTile(
                      title: AppText(
                        'Meal Type',
                        fontSize: FontSizes.body,
                        color: AppColors.text,
                      ),
                      subtitle: DropdownButton<String>(
                        value: selectedMealType,
                        dropdownColor: AppColors.surface,
                        underline: Container(
                          height: 1,
                          color: AppColors.primary,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => selectedMealType = newValue);
                          }
                        },
                        items: ['Breakfast', 'Lunch', 'Dinner']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: AppText(
                              value,
                              fontSize: FontSizes.body,
                              color: AppColors.text,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: AppText(
                  'Cancel',
                  fontSize: FontSizes.body,
                  color: AppColors.textSecondary,
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'date': selectedDate,
                  'mealType': selectedMealType,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  ),
                ),
                child: AppText(
                  'Plan',
                  fontSize: FontSizes.body,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      try {
        await _firestoreService.planMeal(
          recipe,
          result['date'] as DateTime,
          result['mealType'] as String,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.text, size: Dimensions.iconM),
                  SizedBox(width: Dimensions.paddingS),
                  AppText(
                    'Meal planned successfully',
                    fontSize: FontSizes.body,
                    color: AppColors.text,
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar('Failed to plan meal');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: AppColors.text, size: Dimensions.iconM),
              SizedBox(width: Dimensions.paddingS),
              AppText(
                message,
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

  Future<void> _removeSaveRecipe(Recipe recipe) async {
    try {
      // Remove the recipe from saved recipes
      await _firestoreService.removeFromSavedRecipes(recipe);

      // Update state langsung tanpa loading
      setState(() {
        savedRecipes.removeWhere((r) => r.id == recipe.id);
      });

      // Show success message with Icon.delete
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.bookmark_remove_rounded, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Recipe: "${recipe.title}" removed from saved')),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error toggling save status: $e');
      // Show error message with Icon.error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to remove ${recipe.title} from saved recipes.\nError: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : savedRecipes.isEmpty
                      ? _buildEmptyState()
                      : _buildRecipeGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(Dimensions.paddingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            'Saved Recipes',
            fontSize: FontSizes.heading2,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
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
      child: Container(
        padding: EdgeInsets.all(Dimensions.paddingS),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
        ),
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
      ),
      itemBuilder: (BuildContext context) => [
        _buildSortMenuItem('Date Added'),
        _buildSortMenuItem('Name'),
        _buildSortMenuItem('Rating'),
        _buildSortMenuItem('Time'),
      ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: Dimensions.iconXXL,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: Dimensions.paddingM),
          AppText(
            'No saved recipes yet',
            fontSize: FontSizes.body,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: Dimensions.paddingS),
          AppText(
            'Your saved recipes will appear here',
            fontSize: FontSizes.caption,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(Dimensions.paddingM),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: Dimensions.paddingM,
        mainAxisSpacing: Dimensions.paddingM,
      ),
      itemCount: savedRecipes.length,
      itemBuilder: (context, index) {
        final recipe = savedRecipes[index];
        return GestureDetector(
          onTap: () => _viewRecipe(recipe),
          child: _buildRecipeCard(recipe),
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Container(
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
            _buildRecipeActions(recipe),
            _buildRecipeInfo(recipe),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeActions(Recipe recipe) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Area info
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
            recipe.area ?? 'Unknown',
            fontSize: FontSizes.caption,
            color: AppColors.textSecondary,
          ),
        ),
        // Delete button
        Container(
          width: Dimensions.iconXL,
          height: Dimensions.iconXL,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.5),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: Dimensions.iconM,
            icon: Icon(Icons.delete_outline, color: AppColors.text),
            onPressed: () => _removeSavedRecipe(recipe),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: Dimensions.iconM, color: color),
        SizedBox(width: Dimensions.paddingS),
        AppText(
          text,
          fontSize: FontSizes.body,
          color: color,
        ),
      ],
    );
  }

  Widget _buildRecipeInfo(Recipe recipe) {
    return Column(
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
              Icons.timer,
              color: AppColors.primary,
              size: Dimensions.iconS,
            ),
            SizedBox(width: Dimensions.paddingXS),
            AppText(
              '${recipe.preparationTime} min',
              fontSize: FontSizes.caption,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: Dimensions.paddingM),
          ],
        ),
      ],
    );
  }

  
}