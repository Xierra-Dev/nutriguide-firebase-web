import 'package:flutter/material.dart';
import 'dart:ui';
import 'home_page.dart';
import 'register_page.dart';
import 'services/auth_service.dart';
import 'personalization_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';
import 'landing_page.dart';
import 'package:simple_animations/simple_animations.dart';

class ErrorDetails {
  final String title;
  final String? message;
  final String? imagePath;

  ErrorDetails({
    required this.title,
    this.message,
    this.imagePath,
  });
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isPasswordVisible = false;
  bool _isEmailEmpty = true;
  bool _isPasswordEmpty = true;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isLoading = false;
  bool _isDialogShowing = false;
  String _loadingMessage = '';
  DateTime? _lastLoginAttempt;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();
  }

  void _setupControllers() {
    _emailController.addListener(_updateEmailEmpty);
    _passwordController.addListener(_updatePasswordEmpty);
    _setupFocusNodes();
  }

  void _setupFocusNodes() {
    _emailFocusNode.addListener(() {
      setState(() => _isEmailFocused = _emailFocusNode.hasFocus);
    });

    _passwordFocusNode.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocusNode.hasFocus);
    });
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

  void _updateEmailEmpty() {
    setState(() => _isEmailEmpty = _emailController.text.isEmpty);
  }

  void _updatePasswordEmpty() {
    setState(() => _isPasswordEmpty = _passwordController.text.isEmpty);
  }

  bool _isWebPlatform() {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = _isWebPlatform();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Color(0xFF1A1A1A),
              Color(0xFF262626),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Pattern Background
            Positioned.fill(
              child: _buildPatternBackground(),
            ),
            
            // Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: isWeb
                        ? _buildWebLayout(size)
                        : _buildMobileLayout(size),
                  ),
                ),
              ),
            ),

            // Close Button
            Positioned(
              top: 20,
              right: 20,
              child: _buildCloseButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternBackground() {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ).createShader(bounds),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebLayout(Size size) {
    return Container(
      width: size.width * 0.85,
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Panel - Branding
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
                image: DecorationImage(
                  image: AssetImage('assets/images/login_bg.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.7),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(true),
                  SizedBox(height: size.height * 0.04),
                  _buildBrandingContent(),
                  SizedBox(height: size.height * 0.06),
                  _buildFeaturesList(),
                ],
              ),
            ),
          ),
          // Right Panel - Login Form
          Expanded(
            flex: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              child: Center(
                child: SingleChildScrollView(
                  child: _buildLoginForm(true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(Size size) {
    return Container(
      width: size.width * 0.9,
      padding: EdgeInsets.all(size.width * 0.06),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLogo(false),
          SizedBox(height: size.height * 0.03),
          _buildLoginForm(false),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isWeb) {
    final size = MediaQuery.of(context).size;
    final logoSize = isWeb ? size.width * 0.08 : size.width * 0.2;
    final paddingSize = isWeb ? logoSize * 0.2 : logoSize * 0.2;
    
    return Column(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          padding: EdgeInsets.all(paddingSize),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
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
            fit: BoxFit.contain,
          ),
        ),
        if (isWeb) ...[
          SizedBox(height: size.height * 0.02),
          Text(
            'NutriGuide',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading2),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBrandingContent() {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
      child: Column(
        children: [
          Text(
            'Your Journey to\nHealthier Living',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading1),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size.height * 0.02),
          Text(
            'Join thousands of users who have transformed their lives with personalized nutrition guidance',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        _buildFeatureItem(
          icon: Icons.restaurant_menu,
          title: 'Smart Meal Planning',
        ),
        SizedBox(height: size.height * 0.02),
        _buildFeatureItem(
          icon: Icons.trending_up,
          title: 'Progress Tracking',
        ),
        SizedBox(height: size.height * 0.02),
        _buildFeatureItem(
          icon: Icons.psychology,
          title: 'AI-Powered Insights',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
  }) {
    final size = MediaQuery.of(context).size;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.015,
        vertical: size.height * 0.012,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: ResponsiveHelper.screenWidth(context) * 0.02,
          ),
          SizedBox(width: size.width * 0.01),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(bool isWeb) {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isWeb) ...[
          Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading3),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            'Sign in to continue your journey',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size.height * 0.03),
        ],
        if (isWeb) ...[
          Text(
            'Sign In',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading2),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            'Welcome back! Please enter your details',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
              color: Colors.white70,
            ),
          ),
          SizedBox(height: size.height * 0.04),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                label: 'Email',
                icon: Icons.email_outlined,
                isWeb: isWeb,
              ),
              SizedBox(height: size.height * 0.02),
              _buildTextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                label: 'Password',
                icon: Icons.lock_outline,
                isPassword: true,
                isWeb: isWeb,
              ),
              SizedBox(height: isWeb ? size.height * 0.03 : size.height * 0.025),
              _buildLoginButton(isWeb),
              SizedBox(height: size.height * 0.02),
              _buildRegisterLink(isWeb),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    bool isPassword = false,
    required bool isWeb,
  }) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: isWeb ? size.height * 0.07 : size.height * 0.065,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: focusNode.hasFocus 
              ? AppColors.primary 
              : Colors.white24,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword && !_isPasswordVisible,
        style: TextStyle(
          fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
          color: Colors.white,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: focusNode.hasFocus 
                ? AppColors.primary 
                : Colors.white70,
            fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
          ),
          prefixIcon: Icon(
            icon,
            color: focusNode.hasFocus 
                ? AppColors.primary 
                : Colors.white70,
            size: isWeb ? size.width * 0.015 : size.width * 0.05,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: focusNode.hasFocus 
                        ? AppColors.primary 
                        : Colors.white70,
                    size: isWeb ? size.width * 0.015 : size.width * 0.05,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.02,
            vertical: size.height * 0.015,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isWeb) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: isWeb ? size.height * 0.07 : size.height * 0.065,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            Color(0xFFFF6E40),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child: _isLoading
              ? SizedBox(
                  height: size.height * 0.03,
                  width: size.height * 0.03,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: isWeb ? size.width * 0.015 : size.width * 0.05,
                    ),
                    SizedBox(width: size.width * 0.01),
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink(bool isWeb) {
    final size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account? ',
          style: TextStyle(
            color: Colors.white70,
            fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.008,
                vertical: size.height * 0.005,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                'Register',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          Icons.close,
          color: Color(0xFF2C3E50),
          size: 24,
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
      ),
    );
  }

  ErrorDetails _getErrorDetails(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('The supplied auth credential is incorrect')) {
      return ErrorDetails(
        title: 'Double Check Your Email and Password',
        message: null,
        imagePath: 'assets/images/double-check-password-email.png',
      );
    } else if (errorStr.contains('A network error')) {
      return ErrorDetails(
        title: 'No Internet Connection',
        message: 'Network error. Please check your internet connection.',
        imagePath: 'assets/images/no-internet.png',
      );
    } else if (errorStr.contains('email-not-verified')) {
      return ErrorDetails(
        title: 'EMAIL NOT VERIFIED',
        message: 'Please verify your email first. Check your inbox for verification link.',
        imagePath: 'assets/images/email-verification.png',
      );
    }

    return ErrorDetails(
      title: 'AN ERROR OCCURRED',
      message: 'Please try again later',
      imagePath: 'assets/images/error-occur.png',
    );
  }

  bool _validateInput() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showLoginDialog(
        isSuccess: false,
        title: 'Invalid Input',
        message: 'Please fill in all fields',
      );
      return false;
    }

    if (!_emailController.text.contains('@')) {
      _showLoginDialog(
        isSuccess: false,
        title: 'Invalid Email',
        message: 'Please enter a valid email address',
      );
      return false;
    }

    return true;
  }

  void _navigateBasedOnLoginStatus(bool isFirstTime) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            isFirstTime ? const PersonalizationPage() : const HomePage(),
      ),
    );
  }

  void _updateLoadingState(bool isLoading, [String message = '']) {
    setState(() {
      _isLoading = isLoading;
      _loadingMessage = message;
    });
  }

  Future<void> _login() async {
    final now = DateTime.now();
    if (_lastLoginAttempt != null &&
        now.difference(_lastLoginAttempt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastLoginAttempt = now;

    if (!_formKey.currentState!.validate() || !_validateInput()) return;

    try {
      _updateLoadingState(true, 'Signing in...');

      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final isFirstTime = await _authService.isFirstTimeLogin();

      _navigateBasedOnLoginStatus(isFirstTime);
    } catch (e) {
      final errorDetails = _getErrorDetails(e);
      _showLoginDialog(
        isSuccess: false,
        message: errorDetails.message,
        title: errorDetails.title,
        specificImage: errorDetails.imagePath,
      );
    } finally {
      _updateLoadingState(false);
    }
  }

  void _showLoginDialog({
    required bool isSuccess,
    String? message,
    String? title,
    String? specificImage,
  }) {
    if (_isDialogShowing) return;

    setState(() {
      _isDialogShowing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
          ),
          backgroundColor: AppColors.surface,
          child: Container(
            padding: EdgeInsets.all(Dimensions.paddingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  specificImage ?? 'assets/images/error-occur.png',
                  height: 100,
                  width: 100,
                ),
                SizedBox(height: Dimensions.spacingL),
                Text(
                  title ?? 'AN ERROR OCCURRED',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context, FontSizes.body),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  SizedBox(height: Dimensions.spacingM),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                          context, FontSizes.bodySmall),
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: Dimensions.spacingL),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                  ),
                  child: Text(
                    'Try Again',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                          context, FontSizes.button),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isDialogShowing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
}