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

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isWeb ? 1200 : double.infinity,
              ),
              child: Row(
                children: [
                  if (isWeb)
                    Container(
                      width: 300,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        border: Border(
                          right: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      padding: EdgeInsets.all(Dimensions.paddingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(Dimensions.radiusM),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: AppColors.primary,
                                size: Dimensions.iconM,
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PersonalizationPage()),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: Dimensions.spacingL),
                          Text(
                            'Set Your Goals',
                            style: TextStyle(
                              fontSize: FontSizes.heading1,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          SizedBox(height: Dimensions.spacingM),
                          Text(
                            'Select at least 1 goal to continue',
                            style: TextStyle(
                              fontSize: FontSizes.body,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: Dimensions.spacingL),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              3,
                              (index) => Container(
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                width: index + 1 == currentStep ? 24 : 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: index + 1 == currentStep ? AppColors.primary : Colors.white24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        if (!isWeb)
                          Container(
                            padding: EdgeInsets.all(Dimensions.paddingM),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.arrow_back,
                                      color: AppColors.primary,
                                      size: Dimensions.iconM,
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const PersonalizationPage()),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: Dimensions.paddingM),
                                Text(
                                  'Set Your Goals',
                                  style: TextStyle(
                                    fontSize: FontSizes.heading2,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                child: SingleChildScrollView(
                            padding: EdgeInsets.all(isWeb ? Dimensions.paddingXL : Dimensions.paddingM),
                            child: Column(
                              children: [
                                if (!isWeb) _buildHeader(),
                                Container(
                                  padding: EdgeInsets.all(isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      if (isWeb)
                                        Wrap(
                                          spacing: Dimensions.paddingL,
                                          runSpacing: Dimensions.paddingL,
                                          children: goals.map((goal) {
                                            return SizedBox(
                                              width: (MediaQuery.of(context).size.width - 800) / 3,
                                              child: _buildGoalOption(goal),
                                            );
                                          }).toList(),
                                        )
                                      else
                                        Column(
                                          children: goals.map((goal) => _buildGoalOption(goal)).toList(),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isWeb ? Dimensions.paddingXL : Dimensions.paddingM,
                                  ),
                  child: Column(
                    children: [
                                      Container(
                                        height: 55,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              Color(0xFFFF6E40),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: selectedGoals.isNotEmpty ? _saveGoals : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                            ),
                                          ),
                                          child: Text(
                                            'Continue',
                                            style: TextStyle(
                                              fontSize: isWeb ? FontSizes.heading3 : FontSizes.button,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: Dimensions.spacingL),
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
                                            fontSize: isWeb ? FontSizes.body : FontSizes.button,
                                            fontWeight: FontWeight.w500,
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

  Widget _buildGoalOption(Map<String, dynamic> goal) {
    final bool isSelected = selectedGoals.contains(goal['title']);
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;
    
    return Container(
      margin: EdgeInsets.only(bottom: isWeb ? 0 : Dimensions.paddingM),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedGoals.remove(goal['title']);
          } else {
            selectedGoals.add(goal['title']);
          }
        });
      },
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
      child: Container(
            padding: EdgeInsets.all(isWeb ? Dimensions.paddingL : Dimensions.paddingM),
        decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.3)]
                    : [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: EdgeInsets.all(isWeb ? Dimensions.paddingM : Dimensions.paddingS),
              decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusM),
              ),
              child: Icon(
                    goal['icon'],
                    color: isSelected ? AppColors.primary : Colors.white70,
                    size: isWeb ? Dimensions.iconL : Dimensions.iconM,
                  ),
                ),
                SizedBox(height: isWeb ? Dimensions.paddingM : Dimensions.paddingS),
                  Text(
                  goal['title'],
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.white,
                    fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Dimensions.paddingXS),
                  Text(
                  goal['description'],
                    style: TextStyle(
                      color: Colors.white70,
                    fontSize: isWeb ? FontSizes.body : FontSizes.caption,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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