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
import 'search_page.dart';
import 'core/helpers/responsive_helper.dart';
import 'landing_page.dart';


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
      if (data != null) {
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
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isWeb)
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  right: BorderSide(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(Dimensions.paddingXL),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: AppColors.text),
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            SlideRightRoute(page: const HomePage()),
                          ),
                        ),
                        SizedBox(width: Dimensions.paddingM),
                        AppText(
                          'Profile',
                          fontSize: FontSizes.heading3,
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(Dimensions.paddingL),
                      child: Column(
                        children: [
                          _buildProfileHeader(),
                          SizedBox(height: Dimensions.paddingL),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isWeb 
              ? DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Container(
                        color: AppColors.background,
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingXL,
                          vertical: Dimensions.paddingM,
                        ),
                        child: TabBar(
                          indicatorColor: AppColors.primary,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.text,
                          indicatorSize: TabBarIndicatorSize.label,
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.insights_rounded),
                                  SizedBox(width: Dimensions.paddingS),
                                  Text('Insights'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_activity_rounded),
                                  SizedBox(width: Dimensions.paddingS),
                                  Text('Activity'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildInsightsTab(),
                            _buildActivityTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: 280,
                        floating: false,
                        pinned: true,
                        backgroundColor: AppColors.background,
                        leading: IconButton(
                          icon: Icon(Icons.arrow_back, color: AppColors.text),
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            SlideRightRoute(page: const HomePage()),
                          ),
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primary.withOpacity(0.1),
                                  AppColors.background,
                                ],
                              ),
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: 100),
                                _buildProfileHeader(),
                                SizedBox(height: Dimensions.paddingL),
                                _buildActionButtons(),
                              ],
                            ),
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
                            indicatorSize: TabBarIndicatorSize.label,
                            tabs: [
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.insights_rounded),
                                    SizedBox(width: Dimensions.paddingS),
                                    Text('Insights'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.local_activity_rounded),
                                    SizedBox(width: Dimensions.paddingS),
                                    Text('Activity'),
                                  ],
                                ),
                              ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              width: isWeb ? 150 : 120,
              height: isWeb ? 150 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.primary.withOpacity(0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _buildProfileImage(),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(Dimensions.paddingXS),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surface,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit,
                  color: AppColors.surface,
                  size: Dimensions.iconS,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Dimensions.paddingM),
        AppText(
          _authService.currentUser?.displayName ?? 'User',
          fontSize: isWeb ? FontSizes.heading2 : FontSizes.heading3,
          color: AppColors.text,
          fontWeight: FontWeight.bold,
          textAlign: TextAlign.center,
        ),
        if (userData?['username'] != null && userData!['username'].isNotEmpty) ...[
          SizedBox(height: Dimensions.paddingXS),
          AppText(
            '@${userData!['username']}',
            fontSize: isWeb ? FontSizes.body : FontSizes.caption,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
        ],
        if (userData?['bio'] != null && userData!['bio'].isNotEmpty) ...[
          SizedBox(height: Dimensions.paddingS),
          Container(
            margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingM),
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.paddingM,
              vertical: Dimensions.paddingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusM),
            ),
            child: AppText(
              '"${userData!['bio']}"',
              fontSize: isWeb ? FontSizes.body : FontSizes.caption,
              color: AppColors.text,
              textAlign: TextAlign.center,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? Dimensions.paddingXL : Dimensions.paddingXS,
      ),
      child: Column(
        children: [
          _buildActionButton(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileEditPage()),
            ),
            icon: Icons.edit_rounded,
            label: 'Edit Profile',
            color: AppColors.primary,
          ),
          SizedBox(height: Dimensions.paddingS),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildActionButton(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      SlideLeftRoute(page: const SettingsPage()),
                    ),
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    color: AppColors.info,
                    compact: true,
                  ),
                ),
                SizedBox(width: Dimensions.paddingXS),
                Expanded(
                  child: _buildActionButton(
                    onTap: _showLogoutDialog,
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    color: AppColors.error,
                    isDestructive: true,
                    compact: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    bool isDestructive = false,
    bool compact = false,
  }) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4.0 : Dimensions.paddingM,
            vertical: isWeb ? Dimensions.paddingM : Dimensions.paddingS,
          ),
          decoration: BoxDecoration(
            color: isDestructive ? color.withOpacity(0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: compact ? 16 : (isWeb ? Dimensions.iconM : Dimensions.iconS),
              ),
              SizedBox(width: 4.0),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: compact 
                      ? FontSizes.small
                      : (isWeb ? FontSizes.body : FontSizes.caption),
                    color: isDestructive ? color : AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: GestureDetector(
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
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.radiusM),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
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
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 4,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                AppColors.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: ClipOval(
            child: userData?['profilePictureUrl'] != null
                ? Image.network(
                    userData!['profilePictureUrl'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.person,
                          size: Dimensions.iconXL, color: AppColors.primary.withOpacity(0.5));
                    },
                  )
                : Icon(Icons.person,
                    size: Dimensions.iconXL, color: AppColors.primary.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWeb ? Dimensions.paddingXL : Dimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(Dimensions.paddingL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Dimensions.paddingS),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        color: AppColors.primary,
                        size: Dimensions.iconL,
                      ),
                    ),
                    SizedBox(width: Dimensions.paddingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            'Your daily nutrition goals',
                            fontSize: isWeb ? FontSizes.heading2 : FontSizes.heading3,
                            color: AppColors.text,
                            fontWeight: FontWeight.bold,
                          ),
                          SizedBox(height: Dimensions.paddingXS),
                          AppText(
                            'Track your progress',
                            fontSize: isWeb ? FontSizes.body : FontSizes.caption,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Dimensions.paddingL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAnimatedNutritionItem('Cal', nutritionGoals.calories.toStringAsFixed(0), Colors.blue),
                    _buildAnimatedNutritionItem('Carbs', '${nutritionGoals.carbs.toStringAsFixed(0)}g', Colors.orange),
                    _buildAnimatedNutritionItem('Fiber', '${nutritionGoals.fiber.toStringAsFixed(0)}g', Colors.green),
                    _buildAnimatedNutritionItem('Protein', '${nutritionGoals.protein.toStringAsFixed(0)}g', Colors.pink),
                    _buildAnimatedNutritionItem('Fat', '${nutritionGoals.fat.toStringAsFixed(0)}g', Colors.purple),
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

  Widget _buildAnimatedNutritionItem(String label, String value, Color color) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutQuad,
      builder: (context, val, child) {
        return Transform.scale(
          scale: val,
          child: Container(
            padding: EdgeInsets.all(Dimensions.paddingM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusM),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: isWeb ? 16 : 12,
                  height: isWeb ? 16 : 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Dimensions.paddingS),
                AppText(
                  label,
                  fontSize: isWeb ? FontSizes.body : FontSizes.caption,
                  color: AppColors.textSecondary,
                ),
                AppText(
                  value,
                  fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityTab() {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;
    
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
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, val, child) {
                            return Transform.scale(
                              scale: val,
                              child: Image.asset(
                                'assets/images/no-activity.png',
                                width: 125,
                                height: 125,
                                fit: BoxFit.contain,
                              ),
                            );
                          },
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
          : GridView.builder(
              padding: EdgeInsets.all(isWeb ? Dimensions.paddingL : Dimensions.paddingM),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWeb ? 3 : 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: Dimensions.paddingM,
                mainAxisSpacing: Dimensions.paddingM,
              ),
              itemCount: activityRecipes.length,
              itemBuilder: (context, index) {
                final recipe = activityRecipes[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  curve: Curves.easeOutQuad,
                  builder: (context, val, child) {
                    return Transform.scale(
                      scale: val,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(Dimensions.radiusM),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(Dimensions.paddingS),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 15,
                                      backgroundImage: NetworkImage(userData?['profilePictureUrl'] ?? ''),
                                    ),
                                  ),
                                  SizedBox(width: Dimensions.paddingS),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          _authService.currentUser?.displayName ?? 'User',
                                          fontSize: FontSizes.caption,
                                          color: AppColors.text,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        AppText(
                                          'a moment ago',
                                          fontSize: FontSizes.small,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    RecipePageRoute(recipe: recipe),
                                  );
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Hero(
                                      tag: 'recipe-${recipe.id}',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.vertical(
                                          bottom: Radius.circular(Dimensions.radiusM),
                                        ),
                                        child: Image.network(
                                          recipe.image,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.vertical(
                                          bottom: Radius.circular(Dimensions.radiusM),
                                        ),
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
                                    Positioned(
                                      top: Dimensions.paddingS,
                                      right: Dimensions.paddingS,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: Dimensions.paddingS,
                                          vertical: Dimensions.paddingXS,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(Dimensions.radiusS),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 2),
                                            AppText(
                                              'Made it',
                                              fontSize: FontSizes.small,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: Dimensions.paddingS,
                                      left: Dimensions.paddingS,
                                      right: Dimensions.paddingS,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AppText(
                                            recipe.title.toUpperCase(),
                                            fontSize: FontSizes.caption,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (recipe.area != null)
                                            Padding(
                                              padding: EdgeInsets.only(top: 2),
                                              child: AppText(
                                                recipe.area!,
                                                fontSize: FontSizes.small,
                                                color: Colors.white.withOpacity(0.8),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          if (recipe.category != null)
                                            Padding(
                                              padding: EdgeInsets.only(top: 2),
                                              child: AppText(
                                                recipe.category!,
                                                fontSize: FontSizes.small,
                                                color: Colors.white.withOpacity(0.8),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
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
              },
            ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
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
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                    size: Dimensions.iconXL,
                  ),
                ),
                SizedBox(height: Dimensions.spacingL),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Dimensions.spacingM),
                Text(
                  'Are you sure you want to logout?',
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
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: Dimensions.paddingM,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radiusM),
                            side: BorderSide(
                              color: AppColors.error.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Dimensions.spacingM),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _authService.signOut();
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              SlideRightRoute(page: const LandingPage()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: Dimensions.paddingM,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radiusM),
                          ),
                          elevation: 2,
                          shadowColor: AppColors.error.withOpacity(0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              size: Dimensions.iconM,
                              color: Colors.white,
                            ),
                            SizedBox(width: Dimensions.paddingXS),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
}