import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';

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
                          'Notifications',
                          style: TextStyle(
                            fontSize: FontSizes.heading1,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: Dimensions.spacingM),
                        Text(
                          'Manage your notification preferences and settings',
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
                                'Notifications',
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                      ),
                                      child: Icon(
                                        Icons.notifications_active,
                                        color: AppColors.primary,
                                        size: isWeb ? Dimensions.iconXL : Dimensions.iconL,
                                      ),
                                    ),
                                    SizedBox(width: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Stay Updated',
                                            style: TextStyle(
                                              fontSize: isWeb ? FontSizes.heading2 : FontSizes.heading3,
                                              color: AppColors.text,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: Dimensions.paddingXS),
                                          Text(
                                            'Enable notifications to never miss out on personalized recipe recommendations and updates',
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
                                      'Notification Settings',
                                      style: TextStyle(
                                        fontSize: isWeb ? FontSizes.heading2 : FontSizes.heading3,
                                        color: AppColors.text,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                    _buildNotificationOption(
                                      'Push Notifications',
                                      'Get instant updates about your favorite recipes',
                                      Icons.notifications_outlined,
                                      _notificationsEnabled,
                                      _toggleNotifications,
                                      isWeb,
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
                                      'What You\'ll Receive',
                                      style: TextStyle(
                                        fontSize: isWeb ? FontSizes.heading2 : FontSizes.heading3,
                                        color: AppColors.text,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                    _buildFeatureItem(
                                      'Recipe Recommendations',
                                      'Personalized recipe ideas just for you',
                                      Icons.restaurant_menu,
                                      isWeb,
                                    ),
                                    SizedBox(height: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                    _buildFeatureItem(
                                      'New Features',
                                      'Stay updated with latest app features',
                                      Icons.new_releases,
                                      isWeb,
                                    ),
                                    SizedBox(height: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                    _buildFeatureItem(
                                      'Special Offers',
                                      'Exclusive NutriGuide offers and updates',
                                      Icons.local_offer,
                                      isWeb,
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
    );
  }

  Widget _buildNotificationOption(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function() onTap,
    bool isWeb,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isWeb ? Dimensions.paddingM : Dimensions.paddingS),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
          ),
          child: Icon(
            icon,
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
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Dimensions.paddingXS),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isWeb ? FontSizes.body : FontSizes.caption,
                  color: AppColors.textSecondary,
                ),
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

  Widget _buildFeatureItem(String title, String subtitle, IconData icon, bool isWeb) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isWeb ? Dimensions.paddingM : Dimensions.paddingS),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
          ),
          child: Icon(
            icon,
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
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Dimensions.paddingXS),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isWeb ? FontSizes.body : FontSizes.caption,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}