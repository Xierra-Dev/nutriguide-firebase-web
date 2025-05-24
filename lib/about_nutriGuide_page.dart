import 'package:flutter/material.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (context, primaryAnimation, secondaryAnimation) => page,
          transitionsBuilder: (context, primaryAnimation, secondaryAnimation, child) {
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

class AboutNutriguidePage extends StatelessWidget {
  const AboutNutriguidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return Scaffold(
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
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        SizedBox(height: Dimensions.spacingL),
                        Text(
                          'About NutriGuide',
                          style: TextStyle(
                            fontSize: FontSizes.heading1,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: Dimensions.spacingM),
                        Text(
                          'Learn more about our app and features',
                          style: TextStyle(
                            fontSize: FontSizes.body,
                            color: AppColors.textSecondary,
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
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              SizedBox(width: Dimensions.paddingM),
                              Text(
                                'About NutriGuide',
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
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
                                    Container(
                                      width: isWeb ? 200 : 120,
                                      height: isWeb ? 200 : 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary.withOpacity(0.1),
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/logo_NutriGuide.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
                                    Text(
                                      'NutriGuide',
                                      style: TextStyle(
                                        fontSize: isWeb ? FontSizes.heading1 : FontSizes.heading2,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    SizedBox(height: Dimensions.paddingS),
                                    Text(
                                      'Version 1.0.1',
                                      style: TextStyle(
                                        fontSize: isWeb ? FontSizes.body : FontSizes.bodySmall,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'About',
                                      style: TextStyle(
                                        fontSize: isWeb ? FontSizes.heading2 : FontSizes.heading3,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(height: Dimensions.paddingM),
                                    Text(
                                      'NutriGuide is your personal nutrition and meal planning assistant. We help you discover, plan, and prepare healthy meals tailored to your preferences and dietary needs.',
                                      style: TextStyle(
                                        fontSize: isWeb ? FontSizes.body : FontSizes.bodySmall,
                                        color: AppColors.textSecondary,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Key Features',
                                      style: TextStyle(
                                        fontSize: isWeb ? FontSizes.heading2 : FontSizes.heading3,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(height: Dimensions.paddingL),
                                    _buildFeatureItem(
                                      'Recipe Discovery',
                                      'Explore thousands of healthy recipes',
                                      isWeb,
                                    ),
                                    SizedBox(height: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                    _buildFeatureItem(
                                      'Meal Planning',
                                      'Plan your meals with smart scheduling',
                                      isWeb,
                                    ),
                                    SizedBox(height: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                    _buildFeatureItem(
                                      'AI Assistant',
                                      'Get personalized nutrition advice',
                                      isWeb,
                                    ),
                                    SizedBox(height: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                    _buildFeatureItem(
                                      'Save Recipe',
                                      'Save your favorite recipes',
                                      isWeb,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
                              Text(
                                '© 2024 NutriGuide. All rights reserved.',
                                style: TextStyle(
                                  fontSize: isWeb ? FontSizes.body : FontSizes.caption,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: Dimensions.paddingL),
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
    );
  }

  Widget _buildFeatureItem(String title, String description, bool isWeb) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isWeb ? Dimensions.paddingM : Dimensions.paddingS),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
          ),
          child: Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: isWeb ? Dimensions.iconL : Dimensions.iconM,
          ),
        ),
        SizedBox(width: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: Dimensions.paddingXS),
              Text(
                description,
                style: TextStyle(
                  fontSize: isWeb ? FontSizes.body : FontSizes.bodySmall,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
