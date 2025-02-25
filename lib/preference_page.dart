import 'package:flutter/material.dart';
import 'package:nutriguide/settings_page.dart';
import 'health_data_page.dart';
import 'goals_settings_page.dart';
import 'allergies_settings_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/widgets/app_text.dart';

class PreferencePage extends StatefulWidget {
  const PreferencePage({super.key});

  @override
  _PreferencePageState createState() => _PreferencePageState();
}

class _PreferencePageState extends State<PreferencePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(Dimensions.paddingM),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.text,
                      size: Dimensions.iconL,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                  SizedBox(width: Dimensions.paddingS),
                  AppText(
                    'Preferences',
                    fontSize: FontSizes.heading3,
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(Dimensions.paddingM),
                children: [
                  _buildPreferenceCard(
                    title: 'Health Data',
                    description: 'Manage your personal health information',
                    icon: Icons.favorite,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HealthDataPage()),
                      );
                    },
                  ),
                  SizedBox(height: Dimensions.paddingM),
                  _buildPreferenceCard(
                    title: 'Personalized Goals',
                    description: 'Set and track your nutrition goals',
                    icon: Icons.track_changes,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GoalsSettingsPage()),
                      );
                    },
                  ),
                  SizedBox(height: Dimensions.paddingM),
                  _buildPreferenceCard(
                    title: 'Allergies',
                    description: 'Manage your food allergies and restrictions',
                    icon: Icons.warning_amber,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AllergiesSettingsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceListTile({
    required BuildContext context,
    required String leadingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        vertical: Dimensions.paddingS,
        horizontal: Dimensions.paddingM,
      ),
      title: AppText(
        leadingText,
        fontSize: FontSizes.body,
        color: AppColors.text,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.text,
        size: Dimensions.iconS,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColors.border,
      thickness: 0.5,
    );
  }

  Widget _buildPreferenceCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          child: Padding(
            padding: EdgeInsets.all(Dimensions.paddingL),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Dimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  ),
                  child: Icon(
                    icon,
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
                        title,
                        fontSize: FontSizes.body,
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: Dimensions.paddingXS),
                      AppText(
                        description,
                        fontSize: FontSizes.caption,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.text,
                  size: Dimensions.iconS,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
