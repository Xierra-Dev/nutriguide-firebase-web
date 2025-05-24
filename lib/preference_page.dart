import 'package:flutter/material.dart';
import 'package:nutriguide/settings_page.dart';
import 'health_data_page.dart';
import 'goals_settings_page.dart';
import 'allergies_settings_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/widgets/app_text.dart';
import 'core/helpers/responsive_helper.dart';

class PreferencePage extends StatefulWidget {
  const PreferencePage({super.key});

  @override
  _PreferencePageState createState() => _PreferencePageState();
}

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;
  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
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
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutQuad,
              )),
              child: child,
            );
          },
        );
}

class _PreferencePageState extends State<PreferencePage> {
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
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                SlideRightRoute(page: const SettingsPage()),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: Dimensions.spacingL),
                        Text(
                          'Preferences',
                          style: TextStyle(
                            fontSize: FontSizes.heading1,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: Dimensions.spacingM),
                        Text(
                          'Customize your app experience and settings',
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
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      SlideRightRoute(page: const SettingsPage()),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: Dimensions.paddingM),
                              Text(
                                'Preferences',
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
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Wrap(
                                spacing: isWeb ? Dimensions.paddingXL : Dimensions.paddingM,
                                runSpacing: isWeb ? Dimensions.paddingXL : Dimensions.paddingM,
                                children: [
                                  SizedBox(
                                    width: isWeb ? (constraints.maxWidth - Dimensions.paddingXL * 2) / 3 : constraints.maxWidth,
                                    child: _buildPreferenceCard(
                                      title: 'Health Data',
                                      description: 'Manage your personal health information',
                                      icon: Icons.favorite,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          SlideLeftRoute(page: const HealthDataPage()),
                                        );
                                      },
                                      isWeb: isWeb,
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWeb ? (constraints.maxWidth - Dimensions.paddingXL * 2) / 3 : constraints.maxWidth,
                                    child: _buildPreferenceCard(
                                      title: 'Personalized Goals',
                                      description: 'Set and track your nutrition goals',
                                      icon: Icons.track_changes,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          SlideLeftRoute(page: const GoalsSettingsPage()),
                                        );
                                      },
                                      isWeb: isWeb,
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWeb ? (constraints.maxWidth - Dimensions.paddingXL * 2) / 3 : constraints.maxWidth,
                                    child: _buildPreferenceCard(
                                      title: 'Allergies',
                                      description: 'Manage your food allergies and restrictions',
                                      icon: Icons.warning_amber,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          SlideLeftRoute(page: const AllergiesSettingsPage()),
                                        );
                                      },
                                      isWeb: isWeb,
                                    ),
                                  ),
                                ],
                              );
                            },
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

  Widget _buildPreferenceCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required bool isWeb,
  }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          child: Padding(
            padding: EdgeInsets.all(isWeb ? Dimensions.paddingL : Dimensions.paddingM),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: isWeb ? Dimensions.iconXL : Dimensions.iconL,
                  ),
                ),
                SizedBox(height: isWeb ? Dimensions.paddingM : Dimensions.paddingS),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Dimensions.paddingXS),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isWeb ? FontSizes.bodySmall : FontSizes.caption,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: isWeb ? Dimensions.paddingM : Dimensions.paddingS),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? Dimensions.paddingM : Dimensions.paddingS,
                    vertical: isWeb ? Dimensions.paddingS : Dimensions.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Configure',
                        style: TextStyle(
                          fontSize: isWeb ? FontSizes.bodySmall : FontSizes.caption,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: Dimensions.paddingXS),
                      Icon(
                        Icons.arrow_forward,
                        color: AppColors.primary,
                        size: isWeb ? Dimensions.iconS : Dimensions.iconS * 0.8,
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
}
