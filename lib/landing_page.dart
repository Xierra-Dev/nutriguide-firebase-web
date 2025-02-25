import 'package:flutter/material.dart';
import 'dart:async';
import 'login_page.dart';
import 'register_page.dart';
import 'services/themealdb_service.dart';
import 'permission/notifications_permission.dart';
import 'core/constants/font_sizes.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/colors.dart';
import 'core/helpers/responsive_helper.dart';
import 'package:shimmer/shimmer.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
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

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  String? _currentImageUrl;
  String? _previousImageUrl;
  bool _isLoading = true;
  final TheMealDBService _mealService = TheMealDBService();
  Timer? _imageChangeTimer;
  AnimationController? _controller;
  Animation<double>? _animation;

  NotificationsServices notificationsServices = NotificationsServices();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOut,
    );

    _loadRandomMealImage();
    notificationsServices.requestNotificationPermission();

    _imageChangeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadRandomMealImage();
    });
  }

  @override
  void dispose() {
    _imageChangeTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadRandomMealImage() async {
    try {
      final imageUrl = await _mealService.getRandomMealImage();
      if (mounted) {
        _controller?.reset();
        setState(() {
          _previousImageUrl = _currentImageUrl;
          _currentImageUrl = imageUrl;
          _isLoading = false;
        });
        _controller?.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildShimmerTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          Colors.white,
          Colors.white.withOpacity(0.5),
          Colors.white,
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        tileMode: TileMode.clamp,
      ).createShader(bounds),
      child: Shimmer.fromColors(
        period: const Duration(seconds: 3),
        baseColor: Colors.white,
        highlightColor: Colors.deepOrange.shade300,
        child: Text(
          'NutriGuide',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading2 * 1.5),
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Responsive text style method
  TextStyle _responsiveTextStyle(BuildContext context, {
    required double baseSize,
    FontWeight fontWeight = FontWeight.bold,
    List<Color>? gradientColors,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final scaleFactor = screenWidth / 375.0; // Base design width

    // Calculate responsive font size
    double fontSize = baseSize * scaleFactor;
    fontSize = fontSize.clamp(baseSize * 0.5, baseSize * 1.5);

    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'Roboto',
      foreground: Paint()
        ..shader = LinearGradient(
          colors: gradientColors ?? [
            const Color(0xFFFF6A00),
            const Color(0xFF00BFFF),
          ],
        ).createShader(
          Rect.fromLTWH(0.0, 0.0, screenWidth, mediaQuery.size.height),
        ),
      shadows: [
        Shadow(
          offset: const Offset(2, 2),
          blurRadius: 4,
          color: Colors.black.withOpacity(0.4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.0,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with Enhanced Gradient Overlay
            if (_previousImageUrl != null)
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(_previousImageUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ),

            if (_currentImageUrl != null && _animation != null)
              FadeTransition(
                opacity: _animation!,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(_currentImageUrl!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Main Content with Enhanced Design
            SafeArea(
              child: Column(
                children: [
                  // Logo/Title Section with Enhanced Design
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 800),
                        opacity: _isLoading ? 0.0 : 1.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Enhanced App Logo
                            Container(
                              padding: EdgeInsets.all(Dimensions.paddingL),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo_NutriGuide.png',
                                width: Dimensions.iconXXL,
                                height: Dimensions.iconXXL,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: Dimensions.spacingL),
                            
                            // Enhanced App Name with Gradient
                            _buildShimmerTitle(),
                            SizedBox(height: Dimensions.spacingM),
                            
                            // Enhanced Tagline
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingL,
                                vertical: Dimensions.paddingS,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                              ),
                              child: Text(
                                'Your Personal Nutrition Assistant',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Enhanced Buttons Section
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingL,
                        vertical: Dimensions.paddingXS,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Enhanced Register Button
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 800),
                            opacity: _isLoading ? 0.0 : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    SlideLeftRoute(page: const RegisterPage()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: Dimensions.paddingL),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: Dimensions.spacingL),

                          // Enhanced Login Button
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 800),
                            opacity: _isLoading ? 0.0 : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    SlideLeftRoute(page: const LoginPage()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: Dimensions.paddingL),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: Dimensions.spacingXL),

                          // Enhanced Terms and Privacy
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 800),
                            opacity: _isLoading ? 0.0 : 1.0,
                            child: Container(
                              padding: EdgeInsets.all(Dimensions.paddingS),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(Dimensions.radiusM),
                              ),
                              child: Text(
                                'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                                  color: Colors.white.withOpacity(0.7),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
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
    );
  }
}