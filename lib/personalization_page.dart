import 'package:flutter/material.dart';
import 'package:nutriguide/goals_page.dart';
import 'package:nutriguide/services/firestore_service.dart';
import 'package:nutriguide/widgets/custom_gender_picker.dart';
import 'package:nutriguide/widgets/custom_number_picker.dart';
import 'package:nutriguide/widgets/custom_activitiyLevel_picker.dart';
import 'package:nutriguide/core/constants/colors.dart';
import 'package:nutriguide/core/constants/dimensions.dart';
import 'package:nutriguide/core/constants/font_sizes.dart';
import 'package:nutriguide/core/helpers/responsive_helper.dart';
import 'package:nutriguide/home_page.dart';

class PersonalizationPage extends StatefulWidget {
  const PersonalizationPage({super.key});

  @override
  _PersonalizationPageState createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends State<PersonalizationPage> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  
  String? gender;
  int? birthYear;
  double? height;
  double? weight;
  String? activityLevel;
  String heightUnit = 'cm';
  int currentStep = 1;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

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
                      // Header with logo and title
                      _buildHeader(),
                      
                      // Form Container with frosted glass effect
                      _buildFormContainer(),

                      // Bottom buttons
                      _buildBottomButtons(),
                    ],
                  ),
                ),
              ),
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
          // Logo with glow effect
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
              Icons.person_outline,
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
            'Personalize Your Experience',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading2),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Dimensions.spacingM),
          Text(
            'Help us customize your nutrition journey',
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

  Widget _buildFormContainer() {
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
        children: [
          _buildFormField('Gender', gender, Icons.person_outline, _showGenderDialog),
          _buildFormField('Birth Year', birthYear?.toString(), Icons.cake_outlined, _showBirthYearDialog),
          _buildFormField('Height', height != null ? '$height cm' : null, Icons.height, _showHeightDialog),
          _buildFormField('Weight', weight != null ? '$weight kg' : null, Icons.monitor_weight_outlined, _showWeightDialog),
          _buildFormField('Activity Level', activityLevel, Icons.directions_run, _showActivityLevelDialog),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, String? value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
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
            // Icon container with gradient
            Container(
              padding: EdgeInsets.all(Dimensions.paddingS),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(Dimensions.radiusM),
              ),
              child: Icon(
                icon,
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
                    label,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingXS),
                  Text(
                    value ?? 'Not Set',
                    style: TextStyle(
                      color: value == null ? AppColors.error : Colors.white,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white70,
              size: Dimensions.iconM,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(Size size, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: Dimensions.paddingL,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            width: isSmallScreen ? 10 : 12,
            height: isSmallScreen ? 10 : 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index + 1 == currentStep ? AppColors.primary : Colors.white24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.all(Dimensions.paddingL),
      child: Column(
        children: [
          // Continue Button with gradient
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
              onPressed: _isLoading ? null : _saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                ),
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
                          color: Colors.white,
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

  void _showGenderDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomGenderPicker(
          initialValue: gender,
        ),
      ),
    ).then((selectedGender) {
      if (selectedGender != null) {
        setState(() {
          gender = selectedGender;
        });
      }
    });
  }

  void _showBirthYearDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'What year were you born in?',
          unit: '',
          initialValue: 2000,
          minValue: 1900,
          maxValue: 2099,
          onValueChanged: (value) {
            setState(() => birthYear = value.toInt());
          },
        ),
      ),
    );
  }

  void _showHeightDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'Your height',
          unit: 'cm',
          initialValue: 100,
          minValue: 0,
          maxValue: 999,
          showDecimals: true,
          onValueChanged: (value) {
            setState(() => height = value);
          },
        ),
      ),
    );
  }

  void _showWeightDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'Your weight',
          unit: 'kg',
          initialValue: 50,
          minValue: 0,
          maxValue: 999,
          showDecimals: true,
          onValueChanged: (value) {
            setState(() => weight = value);
          },
        ),
      ),
    );
  }

  void _showActivityLevelDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomActivityLevelPicker(
          initialValue: activityLevel,
        ),
      ),
    ).then((selectedActivityLevel) {
      if (selectedActivityLevel != null) {
        setState(() {
          activityLevel = selectedActivityLevel;
        });
      }
    });
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.saveUserPersonalization({
        'gender': gender,
        'birthYear': birthYear,
        'heightUnit': heightUnit,
        'height': height,
        'weight': weight,
        'activityLevel': activityLevel,
      });

      // Navigate to GoalsPage after successful save
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GoalsPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
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