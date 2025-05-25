import 'package:flutter/material.dart';
import 'package:nutriguide/about_nutriGuide_page.dart';
import 'package:nutriguide/notifications_page.dart';
import 'account_page.dart';
import 'services/auth_service.dart';
import 'profile_edit_page.dart';
import 'preference_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';
import 'profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
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

class _SettingsPageState extends State<SettingsPage> {
  String? email;
  String? displayName;
  String? firstName;
  String? lastName;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final authService = AuthService();
    try {
      email = authService.getCurrentUserEmail();
      Map<String, String?> userNames = await authService.getUserNames();
      displayName = userNames['displayName'];
      firstName = userNames['firstName'];
      lastName = userNames['lastName'];
      setState(() {
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(255, 0, 0, 0).withOpacity(0.8),
                const Color.fromARGB(255, 0, 0, 0),
              ],
            ),
          ),
          child: SafeArea(
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
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(Dimensions.radiusM),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: Dimensions.iconM,
                                ),
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    SlideRightRoute(page: const ProfilePage()),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: Dimensions.spacingL),
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: FontSizes.heading1,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: Dimensions.spacingM),
                            Text(
                              'Manage your account settings and preferences',
                              style: TextStyle(
                                fontSize: FontSizes.body,
                                color: Colors.white70,
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
                              padding: EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingM,
                                vertical: Dimensions.paddingM,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                        size: Dimensions.iconM,
                                      ),
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          SlideRightRoute(page: const ProfilePage()),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: Dimensions.spacingM),
                                  Text(
                                    'Settings',
                                    style: TextStyle(
                                      fontSize: FontSizes.heading3,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.all(isWeb ? Dimensions.paddingXL : Dimensions.paddingM),
                              children: [
                                _buildSettingsSection(
                                  title: 'Account Settings',
                                  children: [
                                    _buildSettingsListTile(
                                      context: context,
                                      leadingIcon: Icons.person_outline,
                                      leadingText: 'Account',
                                      trailingText: email ?? '',
                                      onTap: () => Navigator.of(context).pushReplacement(
                                        SlideLeftRoute(page: const AccountPage()),
                                      ),
                                    ),
                                    _buildSettingsListTile(
                                      context: context,
                                      leadingIcon: Icons.edit_outlined,
                                      leadingText: 'Profile',
                                      trailingText: displayName ?? '',
                                      onTap: () => Navigator.push(
                                        context,
                                        SlideLeftRoute(page: const ProfileEditPage()),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: Dimensions.spacingL),
                                _buildSettingsSection(
                                  title: 'Preferences',
                                  children: [
                                    _buildSettingsListTile(
                                      context: context,
                                      leadingIcon: Icons.notifications_outlined,
                                      leadingText: 'Notifications',
                                      trailingText: '',
                                      onTap: () => Navigator.of(context).push(
                                        SlideLeftRoute(page: const NotificationsPage()),
                                      ),
                                    ),
                                    _buildSettingsListTile(
                                      context: context,
                                      leadingIcon: Icons.tune_outlined,
                                      leadingText: 'Preferences',
                                      trailingText: '',
                                      onTap: () => Navigator.pushReplacement(
                                        context,
                                        SlideLeftRoute(page: const PreferencePage()),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: Dimensions.spacingL),
                                _buildSettingsSection(
                                  title: 'About',
                                  children: [
                                    _buildSettingsListTile(
                                      context: context,
                                      leadingIcon: Icons.info_outline,
                                      leadingText: 'About NutriGuide',
                                      trailingText: '',
                                      onTap: () => Navigator.push(
                                        context,
                                        SlideLeftRoute(page: const AboutNutriguidePage()),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
      ),
    );
  }

  Widget _buildSettingsSection({required String title, required List<Widget> children}) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(Dimensions.paddingM),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isWeb ? FontSizes.heading3 : FontSizes.bodySmall,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsListTile({
    required BuildContext context,
    required IconData leadingIcon,
    required String leadingText,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        child: Container(
          padding: EdgeInsets.all(isWeb ? Dimensions.paddingL : Dimensions.paddingM),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isWeb ? Dimensions.paddingM : Dimensions.paddingS),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Icon(
                  leadingIcon,
                  color: Colors.white,
                  size: isWeb ? Dimensions.iconL : Dimensions.iconM,
                ),
              ),
              SizedBox(width: isWeb ? Dimensions.spacingL : Dimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leadingText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (trailingText.isNotEmpty) ...[
                      SizedBox(height: Dimensions.spacingXS),
                      Text(
                        trailingText,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isWeb ? FontSizes.body : FontSizes.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: isWeb ? Dimensions.iconM : Dimensions.iconS,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
