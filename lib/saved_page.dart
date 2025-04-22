import 'package:flutter/material.dart';
import 'core/helpers/responsive_helper.dart';
import 'models/recipe.dart';
import 'services/firestore_service.dart';
import 'recipe_detail_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/widgets/app_text.dart';
import 'package:intl/intl.dart';
import 'widgets/skeleton_loading.dart';
import 'search_page.dart';

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

class _SavedPageState extends State<SavedPage> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  List<Recipe> savedRecipes = [];
  bool isLoading = true;
  String? errorMessage;
  String sortBy = 'Date Added';
  
  AnimationController? _animationController;
  Animation<double> _fadeAnimation = const AlwaysStoppedAnimation(1.0);

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadSavedRecipes();
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
        RecipePageRoute(recipe: recipe),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                ? const SavedSkeleton()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildBody(),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'Saved Recipes',
                    fontSize: FontSizes.heading2,
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: Dimensions.paddingXS),
                  AppText(
                    'Your favorite recipes collection',
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
                  Icons.bookmark,
                  color: AppColors.primary,
                  size: Dimensions.iconM,
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.paddingM),
          _buildSortBar(),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Container(
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
          Row(
            children: [
              Icon(
                Icons.sort,
                color: AppColors.primary,
                size: Dimensions.iconM,
              ),
              SizedBox(width: Dimensions.paddingS),
              AppText(
                'Sort by:',
                fontSize: FontSizes.body,
                color: AppColors.textSecondary,
              ),
            ],
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
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.paddingM,
          vertical: Dimensions.paddingS,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
        ),
        child: Row(
          children: [
            AppText(
              sortBy,
              fontSize: FontSizes.body,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
            SizedBox(width: Dimensions.paddingXS),
            Icon(
              Icons.arrow_drop_down,
              color: AppColors.primary,
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
      padding: EdgeInsets.all(Dimensions.paddingS),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: Dimensions.paddingS,
        mainAxisSpacing: Dimensions.paddingS,
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
    return Hero(
      tag: 'recipe-${recipe.id}',
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
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveHelper.screenHeight(context) * 0.0155,
            horizontal: ResponsiveHelper.screenWidth(context) * 0.025,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRecipeActions(recipe),
              _buildRecipeInfo(recipe),
            ],
          ),
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
            recipe.area ?? 'International',
            fontSize: FontSizes.bodySmall,
            color: AppColors.textSecondary,
          ),
        ),
        // Delete button
        Container(
          width: Dimensions.iconL,
          height: Dimensions.iconL,
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
            SizedBox(width: 47.5),
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
    );
  }

  Widget _buildBody() {
    return savedRecipes.isEmpty
        ? _buildEmptyState()
        : _buildRecipeGrid();
  }
}