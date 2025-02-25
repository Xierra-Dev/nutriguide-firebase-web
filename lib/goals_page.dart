import 'package:flutter/material.dart';
import 'package:nutriguide/services/firestore_service.dart';
import 'package:nutriguide/core/constants/colors.dart';
import 'package:nutriguide/core/constants/dimensions.dart';
import 'package:nutriguide/core/constants/font_sizes.dart';
import 'package:nutriguide/core/helpers/responsive_helper.dart';
import 'package:nutriguide/allergies_page.dart';
import 'package:nutriguide/personalization_page.dart';
import 'package:nutriguide/home_page.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  _GoalsPageState createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final Set<String> selectedGoals = <String>{};
  bool _isLoading = false;
  int currentStep = 2; // Changed to 2 since this is the second step

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> goals = [
    {
      'title': 'Weight Less',
      'icon': Icons.trending_down_outlined,
      'description': 'Achieve healthy weight reduction',
    },
    {
      'title': 'Get Healthier',
      'icon': Icons.favorite_outline,
      'description': 'Improve overall health and wellness',
    },
    {
      'title': 'Look Better',
      'icon': Icons.person_outline,
      'description': 'Enhance physical appearance',
    },
    {
      'title': 'Reduce Stress',
      'icon': Icons.spa_outlined,
      'description': 'Manage stress through better nutrition',
    },
    {
      'title': 'Sleep Better',
      'icon': Icons.nightlight_outlined,
      'description': 'Improve sleep quality naturally',
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surface,
                      AppColors.background,
                    ],
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildGoalsContainer(),
                      _buildBottomButtons(),
                    ],
                  ),
                ),
              ),

              // Back button
              _buildBackButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(Dimensions.paddingXL),
      child: Column(
        children: [
          // Logo with glow effect (similar to personalization page)
          Container(
            padding: EdgeInsets.all(Dimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.flag_outlined,  // Changed to represent goals
              size: 60,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: Dimensions.spacingL),
          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index + 1 == currentStep ? AppColors.primary : Colors.white24,
                ),
              ),
            ),
          ),
          SizedBox(height: Dimensions.spacingL),
          Text(
            'Set Your Goals',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading2),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Dimensions.spacingM),
          Text(
            'Select at least 1 goal to continue.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsContainer() {
    return Container(
      margin: EdgeInsets.all(Dimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: goals.map((goal) => _buildGoalOption(goal)).toList(),
      ),
    );
  }

  Widget _buildGoalOption(Map<String, dynamic> goal) {
    final bool isSelected = selectedGoals.contains(goal['title']);
    
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedGoals.remove(goal['title']);
          } else {
            selectedGoals.add(goal['title']);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.all(Dimensions.paddingL),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Icon container with gradient (similar to personalization page)
            Container(
              padding: EdgeInsets.all(Dimensions.paddingS),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isSelected ? AppColors.primary : Colors.white24,
                    isSelected ? AppColors.primary.withOpacity(0.7) : Colors.white12,
                  ],
                ),
                borderRadius: BorderRadius.circular(Dimensions.radiusM),
              ),
              child: Icon(
                goal['icon'] as IconData,
                color: Colors.white,
                size: Dimensions.iconM,
              ),
            ),
            SizedBox(width: Dimensions.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal['title'] as String,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.white,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingXS),
                  Text(
                    goal['description'] as String,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(Dimensions.paddingXS),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: Dimensions.iconS,
                ),
              ),
          ],
        ),
      ),
    );
  }

    Widget _buildBottomButtons() {
    final bool hasSelectedGoals = selectedGoals.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(Dimensions.paddingL),
      child: Column(
        children: [
          // Continue Button with gradient
          Container(
            height: 55,
            decoration: BoxDecoration(
              gradient: hasSelectedGoals
                  ? LinearGradient(
                      colors: [
                        AppColors.primary,
                        Color(0xFFFF6E40),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey[800]!,
                        Colors.grey[700]!,
                      ],
                    ),
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              boxShadow: hasSelectedGoals
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: hasSelectedGoals ? _saveGoals : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                ),
                disabledBackgroundColor: Colors.transparent,
              ),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveTextSize(
                              context, FontSizes.button),
                          fontWeight: FontWeight.bold,
                          color: hasSelectedGoals ? Colors.white : Colors.grey[400],
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: Dimensions.spacingL),
          // Set Up Later Button
          TextButton(
            onPressed: _showSetUpLaterDialog,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: Dimensions.paddingM,
                horizontal: Dimensions.paddingXL,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                side: BorderSide(color: Colors.white24),
              ),
            ),
            child: Text(
              'Set Up Later',
              style: TextStyle(
                color: Colors.white70,
                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + Dimensions.paddingM,
      left: Dimensions.paddingL,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PersonalizationPage()),
            );
          },
        ),
      ),
    );
  }

  // Keep existing methods for dialog and navigation
  void _showSetUpLaterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 10.0),
            backgroundColor: Color.fromARGB(255, 91, 91, 91),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Don't Want Our Health\nFeatures?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22.5,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          "To receive personalized meal and recipe recommendations, you need to complete the questionnaire to use Health Features.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          "You can set up later in Settings > Preferences.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(
                      bottom: 30,
                      left: 30,
                      right: 30,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                          ),
                          child: Text(
                            "Skip Questionnaire",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                        ),
                        SizedBox(height: 17.5),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                          ),
                          child: Text(
                            "Return to Questionnaire",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveGoals() async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.saveUserGoals(selectedGoals.toList());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AllergiesPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goals: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}