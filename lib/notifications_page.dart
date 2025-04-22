import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/widgets/app_text.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final status = await Permission.notification.status;
    setState(() {
      _notificationsEnabled = status.isGranted;
    });
  }

  Future<void> _toggleNotifications() async {
    if (_notificationsEnabled) {
      openAppSettings();
    } else {
      final status = await Permission.notification.request();
      setState(() {
        _notificationsEnabled = status.isGranted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          'Notifications',
          fontSize: FontSizes.heading3,
          color: AppColors.text,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(Dimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(Dimensions.paddingL),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(Dimensions.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                    child: Icon(
                      Icons.notifications_active,
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
                          'Stay Updated',
                          fontSize: FontSizes.heading3,
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: Dimensions.paddingXS),
                        AppText(
                          'Enable notifications to never miss out on personalized recipe recommendations and updates',
                          fontSize: FontSizes.body,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Dimensions.paddingL),
            Container(
              padding: EdgeInsets.all(Dimensions.paddingL),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'Notification Settings',
                    fontSize: FontSizes.heading3,
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: Dimensions.paddingM),
                  _buildNotificationOption(
                    'Push Notifications',
                    'Get instant updates about your favorite recipes',
                    Icons.notifications_outlined,
                    _notificationsEnabled,
                    _toggleNotifications,
                  ),
                ],
              ),
            ),
            SizedBox(height: Dimensions.paddingL),
            Container(
              padding: EdgeInsets.all(Dimensions.paddingL),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'What You\'ll Receive',
                    fontSize: FontSizes.heading3,
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: Dimensions.paddingM),
                  _buildFeatureItem(
                    'Recipe Recommendations',
                    'Personalized recipe ideas just for you',
                    Icons.restaurant_menu,
                  ),
                  SizedBox(height: Dimensions.paddingM),
                  _buildFeatureItem(
                    'New Features',
                    'Stay updated with latest app features',
                    Icons.new_releases,
                  ),
                  SizedBox(height: Dimensions.paddingM),
                  _buildFeatureItem(
                    'Special Offers',
                    'Exclusive NutriGuide offers and updates',
                    Icons.local_offer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOption(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function() onTap,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(Dimensions.paddingS),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: Dimensions.iconM,
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
                subtitle,
                fontSize: FontSizes.caption,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (value) => onTap(),
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(Dimensions.paddingS),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: Dimensions.iconM,
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
                subtitle,
                fontSize: FontSizes.caption,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}