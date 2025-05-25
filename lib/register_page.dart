import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'login_page.dart';
import 'services/auth_service.dart';
import 'email_verification_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/font_sizes.dart';
import 'core/constants/dimensions.dart';
import 'core/helpers/responsive_helper.dart';
import 'landing_page.dart';
import 'package:simple_animations/simple_animations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isNameEmpty = true;
  bool _isEmailEmpty = true;
  bool _isPasswordEmpty = true;
  bool _isConfirmPasswordEmpty = true;
  bool _isNameFocused = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();
  }

  void _setupControllers() {
    _nameController.addListener(_updateNameEmpty);
    _emailController.addListener(_updateEmailEmpty);
    _passwordController.addListener(_updatePasswordEmpty);
    _confirmPasswordController.addListener(_updateConfirmPasswordEmpty);

    _setupFocusNodes();
  }

  void _setupFocusNodes() {
    _nameFocusNode.addListener(() {
      setState(() => _isNameFocused = _nameFocusNode.hasFocus);
    });

    _emailFocusNode.addListener(() {
      setState(() => _isEmailFocused = _emailFocusNode.hasFocus);
    });

    _passwordFocusNode.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocusNode.hasFocus);
    });

    _confirmPasswordFocusNode.addListener(() {
      setState(() => _isConfirmPasswordFocused = _confirmPasswordFocusNode.hasFocus);
    });

    _passwordController.addListener(() {
      _checkPasswordRequirements(_passwordController.text);
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

  void _updateNameEmpty() {
    setState(() => _isNameEmpty = _nameController.text.isEmpty);
  }

  void _updateEmailEmpty() {
    setState(() => _isEmailEmpty = _emailController.text.isEmpty);
  }

  void _updatePasswordEmpty() {
    setState(() => _isPasswordEmpty = _passwordController.text.isEmpty);
  }

  void _updateConfirmPasswordEmpty() {
    setState(() => _isConfirmPasswordEmpty = _confirmPasswordController.text.isEmpty);
  }

  void _checkPasswordRequirements(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasNumber = RegExp(r'[0-9]').hasMatch(value);
      _hasSymbol = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
    });
  }

  Widget _buildEnhancedRequirementItem(bool isMet, String text, bool isWeb) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isWeb ? 6 : 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isWeb ? 3 : 2),
            decoration: BoxDecoration(
              color: isMet ? AppColors.success.withOpacity(0.8) : AppColors.error.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMet ? Icons.check : Icons.close,
              size: isWeb ? 14 : 12,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isWeb ? 12 : 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? AppColors.success : AppColors.error.withOpacity(0.7),
              fontSize: isWeb 
                  ? 14
                  : ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        UserCredential credential = await _authService.registerWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(
              email: _emailController.text.trim(),
              user: credential.user,
            ),
          ),
        );
      } catch (e) {
        String errorTitle = 'Registration Error';
        String? errorMessage;
        String? specificImage;

        if (e.toString().contains('email-already-in-use')) {
          errorTitle = 'Email Already Registered';
          errorMessage = 'This email is already registered. Please use a different email or log in.';
          specificImage = 'assets/images/account-already-registered.png';
        } else if (e.toString().contains('network-request-failed')) {
          errorTitle = 'No Internet Connection';
          errorMessage = 'Please check your internet connection and try again.';
          specificImage = 'assets/images/no-internet.png';
        }

        _showRegistrationDialog(
          isSuccess: false,
          title: errorTitle,
          message: errorMessage,
          specificImage: specificImage,
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRegistrationDialog({
    required bool isSuccess,
    String? message,
    String? title,
    String? specificImage,
    UserCredential? credential,
  }) {
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
          child: Padding(
            padding: EdgeInsets.all(Dimensions.paddingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  specificImage ?? (isSuccess
                      ? 'assets/images/register-success.png'
                      : 'assets/images/error-occur.png'),
                  height: 100,
                  width: 100,
                ),
                SizedBox(height: Dimensions.spacingL),
                Text(
                  title ?? (isSuccess 
                      ? 'Registration Successful' 
                      : 'Registration Error'),
                  style: TextStyle(
                    color: isSuccess ? AppColors.success : AppColors.error,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  SizedBox(height: Dimensions.spacingM),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: Dimensions.spacingL),
                _buildDialogButton(isSuccess, credential),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogButton(bool isSuccess, UserCredential? credential) {
    return ElevatedButton(
      onPressed: () {
        if (isSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationPage(
                email: _emailController.text.trim(),
                user: credential?.user,
              ),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.paddingXL,
          vertical: Dimensions.paddingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
        ),
      ),
      child: Text(
        isSuccess ? 'Continue' : 'Try Again',
        style: TextStyle(
          fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
          color: AppColors.surface,
        ),
      ),
    );
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
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
                image: DecorationImage(
                  image: AssetImage('assets/images/register_bg.jpg'),
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
                  SizedBox(height: size.height * 0.03),
                  _buildBrandingContent(),
                  SizedBox(height: size.height * 0.04),
                  _buildFeaturesList(),
                ],
              ),
            ),
          ),
          // Right Panel - Registration Form
          Expanded(
            flex: 5,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
              child: Center(
                child: Container(
                  height: size.height * 0.75,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                      child: _buildRegistrationForm(true),
                    ),
                  ),
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
          _buildRegistrationForm(false),
        ],
      ),
    );
  }

  Widget _buildContent(Size size) {
    final isWeb = _isWebPlatform();
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(size.width * 0.03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(size),
              SizedBox(height: size.height * 0.05),
              _buildRegistrationForm(isWeb),
              SizedBox(height: size.height * 0.05),
              _buildLoginLink(isWeb),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Size size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(size.width * 0.03),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo_NutriGuide.png',
              width: size.width * 0.08,
              height: size.width * 0.08,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.05),
        Center(
          child: Text(
            'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading2),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(bool isWeb) {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isWeb) ...[
          Text(
            'Create Account',
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
            'Join us and start your journey',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size.height * 0.02),
        ],
        if (isWeb) ...[
          Text(
            'Create Account',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading2),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            'Start your journey to a healthier lifestyle',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
              color: Colors.white70,
            ),
          ),
          SizedBox(height: size.height * 0.025),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                label: 'Full Name',
                icon: Icons.person_outline,
                isWeb: isWeb,
              ),
              SizedBox(height: size.height * 0.015),
              _buildTextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                label: 'Email',
                icon: Icons.email_outlined,
                isWeb: isWeb,
              ),
              SizedBox(height: size.height * 0.015),
              _buildTextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                label: 'Password',
                icon: Icons.lock_outline,
                isPassword: true,
                isWeb: isWeb,
              ),
              SizedBox(height: size.height * 0.015),
              _buildPasswordRequirements(isWeb),
              SizedBox(height: size.height * 0.015),
              _buildTextField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocusNode,
                label: 'Confirm Password',
                icon: Icons.lock_outline,
                isPassword: true,
                isWeb: isWeb,
              ),
              SizedBox(height: size.height * 0.02),
              _buildRegisterButton(isWeb),
              SizedBox(height: size.height * 0.015),
              _buildLoginLink(isWeb),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focusNode.hasFocus 
              ? AppColors.primary 
              : Colors.white24,
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword && (label == 'Password' ? !_isPasswordVisible : !_isConfirmPasswordVisible),
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
                    (label == 'Password' ? _isPasswordVisible : _isConfirmPasswordVisible)
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: focusNode.hasFocus 
                        ? AppColors.primary 
                        : Colors.white70,
                    size: isWeb ? size.width * 0.015 : size.width * 0.05,
                  ),
                  onPressed: () {
                    setState(() {
                      if (label == 'Password') {
                        _isPasswordVisible = !_isPasswordVisible;
                      } else {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      }
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          if (label == 'Email' && !value.contains('@')) {
            return 'Please enter a valid email address';
          }
          if (label == 'Password' && (!_hasMinLength || !_hasNumber || !_hasSymbol)) {
            return 'Password does not meet requirements';
          }
          if (label == 'Confirm Password' && value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordRequirements(bool isWeb) {
    final size = MediaQuery.of(context).size;
    return Container(
      padding: EdgeInsets.all(size.width * 0.02),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: size.height * 0.01),
          _buildRequirementItem(_hasMinLength, 'At least 8 characters', isWeb),
          _buildRequirementItem(_hasNumber, 'Contains a number', isWeb),
          _buildRequirementItem(_hasSymbol, 'Contains a symbol', isWeb),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(bool isMet, String text, bool isWeb) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.005),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isWeb ? size.width * 0.002 : size.width * 0.004),
            decoration: BoxDecoration(
              color: isMet ? AppColors.success.withOpacity(0.8) : Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMet ? Icons.check : Icons.close,
              size: isWeb ? size.width * 0.01 : size.width * 0.03,
              color: Colors.white,
            ),
          ),
          SizedBox(width: size.width * 0.01),
          Text(
            text,
            style: TextStyle(
              color: isMet ? AppColors.success : Colors.white70,
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(bool isWeb) {
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
        onPressed: _isLoading ? null : _register,
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
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: isWeb ? size.width * 0.015 : size.width * 0.05,
                    ),
                    SizedBox(width: size.width * 0.01),
                    Text(
                      'Create Account',
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

  Widget _buildLoginLink(bool isWeb) {
    final size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: Colors.white70,
            fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
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
                'Login',
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
          color: Colors.black87,
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
            'Start Your Journey to\nHealthier Living',
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
            'Join our community and get personalized nutrition guidance tailored just for you',
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
          icon: Icons.person_outline,
          title: 'Personalized Plans',
        ),
        SizedBox(height: size.height * 0.02),
        _buildFeatureItem(
          icon: Icons.restaurant_menu,
          title: 'Custom Meal Plans',
        ),
        SizedBox(height: size.height * 0.02),
        _buildFeatureItem(
          icon: Icons.insights,
          title: 'Progress Analytics',
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
}