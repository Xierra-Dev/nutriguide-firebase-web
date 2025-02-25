import 'package:flutter/material.dart';
import 'package:nutriguide/home_page.dart';
import 'settings_page.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'profile_edit_page.dart';
import 'models/recipe.dart';
import 'models/nutrition_goals.dart';
import 'recipe_detail_page.dart';
import 'widgets/nutrition_tracker.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/widgets/app_text.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

// Tambahkan class ini di luar _ProfilePageState
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
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
          begin: const Offset(-1.0, 0.0),
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

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isLoadingActivity = true;
  List<Recipe> activityRecipes = [];
  bool isLoadingCreated = true;

  final Color selectedColor = const Color.fromARGB(255, 240, 182, 75);

  // Define the daily nutrition variables
  double dailyCalories = 0;
  double dailyProtein = 0;
  double dailyCarbs = 0;
  double dailyFat = 0;

  NutritionGoals nutritionGoals = NutritionGoals.recommended();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _loadDailyNutritionData();
    _loadActivityData();
    _loadNutritionGoals();

    // Add listener to update state when tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  Future<void> _loadNutritionGoals() async {
    final goals = await _firestoreService.getNutritionGoals();
    setState(() {
      nutritionGoals = goals;
    });
  }

  Future<void> _loadActivityData() async {
    try {
      setState(() => isLoadingActivity = true);
      final recipes = await _firestoreService.getMadeRecipes();
      setState(() {
        activityRecipes = recipes;
        isLoadingActivity = false;
      });
    } catch (e) {
      print('Error loading activity data: $e');
      setState(() {
        activityRecipes = [];
        isLoadingActivity = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _firestoreService.getUserPersonalization();
      print('Loaded userData: $data'); // Debug print
      if (data != null) {
        print('Profile Picture URL: ${data['profilePictureUrl']}'); // Debug print
        setState(() {
          userData = data;
          isLoading = false;
        });
      } else {
        print('No user data found');
        setState(() {
          userData = {};
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userData = {};
        isLoading = false;
      });
    }
  }

  Future<void> _loadDailyNutritionData() async {
    try {
      final nutritionTotals = await _firestoreService.getDailyNutritionTotals();
      setState(() {
        dailyCalories = nutritionTotals['calories'] ?? 0;
        dailyProtein = nutritionTotals['protein'] ?? 0;
        dailyCarbs = nutritionTotals['carbs'] ?? 0;
        dailyFat = nutritionTotals['fat'] ?? 0;
      });
    } catch (e) {
      print('Error loading daily nutrition data: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 380, // Sesuaikan dengan kebutuhan
              floating: false,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.text),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings, color: AppColors.text),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  children: [
                    SizedBox(height: 100), // Untuk kompensasi AppBar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                      ),
                      child: ClipOval(
                        child: _buildProfileImage(),
                      ),
                    ),
                    SizedBox(height: Dimensions.paddingM),
                    AppText(
                      _authService.currentUser?.displayName ?? 'User',
                      fontSize: FontSizes.heading2,
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                    if (userData?['username'] != null)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: Dimensions.paddingS),
                        child: AppText(
                          userData!['username'],
                          fontSize: FontSizes.body,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (userData?['bio'] != null)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: Dimensions.paddingS),
                        child: AppText(
                          userData!['bio'],
                          fontSize: FontSizes.body,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    SizedBox(height: Dimensions.paddingM),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileEditPage()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingL,
                          vertical: Dimensions.paddingM,
                        ),
                      ),
                      child: AppText(
                        'Edit Profile',
                        fontSize: FontSizes.body,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.text,
                  tabs: const [
                    Tab(text: 'Insights'),
                    Tab(text: 'Activity'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInsightsTab(),
            _buildActivityTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: () {
        if (userData?['profilePictureUrl'] != null) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Dimensions.radiusM),
                          child: Image.network(
                            userData!['profilePictureUrl'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: MediaQuery.of(context).size.width * 0.8,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: MediaQuery.of(context).size.width * 0.8,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                ),
                                child: Icon(
                                  Icons.error_outline,
                                  size: Dimensions.iconXL,
                                  color: AppColors.error,
                                ),
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(Dimensions.paddingXS),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: AppColors.surface,
                              size: Dimensions.iconM,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }
      },
      child: userData?['profilePictureUrl'] != null
          ? Image.network(
              userData!['profilePictureUrl'],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.person, size: Dimensions.iconXL, color: AppColors.text);
              },
            )
          : Icon(Icons.person, size: Dimensions.iconXL, color: AppColors.text),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Dimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(Dimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Dimensions.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Your daily nutrition goals',
                  fontSize: FontSizes.heading3,
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: Dimensions.paddingXS),
                AppText(
                  'Balanced macros',
                  fontSize: FontSizes.caption,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: Dimensions.paddingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNutritionItem('Cal', '${nutritionGoals.calories.toStringAsFixed(0)}', Colors.blue),
                    _buildNutritionItem('Carbs', '${nutritionGoals.carbs.toStringAsFixed(0)}g', Colors.orange),
                    _buildNutritionItem('Fiber', '${nutritionGoals.fiber.toStringAsFixed(0)}g', Colors.green),
                    _buildNutritionItem('Protein', '${nutritionGoals.protein.toStringAsFixed(0)}g', Colors.pink),
                    _buildNutritionItem('Fat', '${nutritionGoals.fat.toStringAsFixed(0)}g', Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: Dimensions.paddingL),
          NutritionTracker(nutritionGoals: nutritionGoals),
        ],
      ),
    );
  }


  Widget _buildNutritionItem(String label, String value, Color color) {
  return Column(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      SizedBox(height: Dimensions.paddingXS),
      AppText(
        label,
        fontSize: FontSizes.caption,
        color: AppColors.textSecondary,
      ),
      AppText(
        value,
        fontSize: FontSizes.body,
        color: AppColors.text,
        fontWeight: FontWeight.bold,
      ),
    ],
  );
}

  Widget _buildNutrientIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDayColumn(String day, bool isSelected, double height) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 120,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 30,
            height: height,
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : Colors.grey[800],
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            color: isSelected ? Colors.orange : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    if (isLoadingActivity) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return RefreshIndicator(
      onRefresh: _loadActivityData,
      color: AppColors.primary,
      child: activityRecipes.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.465,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/no-activity.png',
                          width: 125,
                          height: 125,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: Dimensions.paddingM),
                        AppText(
                          'No activity yet',
                          fontSize: FontSizes.body,
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: EdgeInsets.all(Dimensions.paddingM),
              itemCount: activityRecipes.length,
              itemBuilder: (context, index) {
                final recipe = activityRecipes[index];
                return Container(
                  margin: EdgeInsets.only(bottom: Dimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(Dimensions.paddingM),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(userData?['profilePictureUrl'] ?? ''),
                            ),
                            SizedBox(width: Dimensions.paddingM),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  _authService.currentUser?.displayName ?? 'User',
                                  fontSize: FontSizes.body,
                                  color: AppColors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                                AppText(
                                  'a moment ago',
                                  fontSize: FontSizes.caption,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailPage(recipe: recipe),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Image.network(
                              recipe.image,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: Dimensions.paddingM,
                              right: Dimensions.paddingM,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingM,
                                  vertical: Dimensions.paddingS,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusS),
                                ),
                                child: AppText(
                                  'Made it ✨',
                                  fontSize: FontSizes.caption,
                                  color: AppColors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(Dimensions.paddingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              recipe.title.toUpperCase(),
                              fontSize: FontSizes.body,
                              color: AppColors.text,
                              fontWeight: FontWeight.bold,
                            ),
                            if (recipe.area != null)
                              Padding(
                                padding: EdgeInsets.only(top: Dimensions.paddingXS),
                                child: AppText(
                                  recipe.area!,
                                  fontSize: FontSizes.caption,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            if (recipe.category != null)
                              Padding(
                                padding: EdgeInsets.only(top: Dimensions.paddingXS),
                                child: AppText(
                                  recipe.category!,
                                  fontSize: FontSizes.caption,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}