import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'services/auth_service.dart';
import 'email_verification_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/font_sizes.dart';
import 'core/constants/dimensions.dart';
import 'core/helpers/responsive_helper.dart';
import 'landing_page.dart';

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

  Widget _buildEnhancedRequirementItem(bool isMet, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isMet ? AppColors.success.withOpacity(0.8) : AppColors.error.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMet ? Icons.check : Icons.close,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? AppColors.success : AppColors.error.withOpacity(0.7),
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
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

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
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
          child: SafeArea(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(Dimensions.paddingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          SizedBox(height: Dimensions.spacingXL),
                          _buildRegistrationForm(),
                          SizedBox(height: Dimensions.spacingL),
                          _buildLoginLink(),
                        ],
                      ),
                    ),
                    // Close Button
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(Dimensions.paddingXS),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: Dimensions.iconL,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LandingPage()),
                          );
                        },
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

  Widget _buildHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(Dimensions.paddingL),
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
              width: 30,
              height: 30,
            ),
          ),
        ),
        SizedBox(height: Dimensions.spacingL),
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

  Widget _buildRegistrationForm() {
    return Container(
      padding: EdgeInsets.all(Dimensions.paddingL),
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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              label: 'Full Name',
              icon: Icons.person_outline,
              isFocused: _isNameFocused,
            ),
            SizedBox(height: Dimensions.spacingL),
            _buildTextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              label: 'Email Address',
              icon: Icons.email_outlined,
              isFocused: _isEmailFocused,
            ),
            SizedBox(height: Dimensions.spacingL),
            _buildPasswordField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'Password',
              isVisible: _isPasswordVisible,
              onVisibilityChanged: (value) => setState(() => _isPasswordVisible = value),
              isFocused: _isPasswordFocused,
            ),
            SizedBox(height: Dimensions.spacingM),
            _buildPasswordRequirements(),
            SizedBox(height: Dimensions.spacingL),
            _buildPasswordField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              label: 'Confirm Password',
              isVisible: _isConfirmPasswordVisible,
              onVisibilityChanged: (value) => setState(() => _isConfirmPasswordVisible = value),
              isFocused: _isConfirmPasswordFocused,
            ),
            SizedBox(height: Dimensions.spacingXL),
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required bool isFocused,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isFocused ? AppColors.primary : Colors.white70,
        ),
        prefixIcon: Icon(
          icon,
          color: isFocused ? AppColors.primary : Colors.white70,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface.withOpacity(0.5),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        if (label == 'Email Address' && !value.contains('@')) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool isVisible,
    required Function(bool) onVisibilityChanged,
    required bool isFocused,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !isVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isFocused ? AppColors.primary : Colors.white70,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: isFocused ? AppColors.primary : Colors.white70,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: isFocused ? AppColors.primary : Colors.white70,
          ),
          onPressed: () => onVisibilityChanged(!isVisible),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface.withOpacity(0.5),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        if (label == 'Password' && (!_hasMinLength || !_hasNumber || !_hasSymbol)) {
          return 'Password does not meet requirements';
        }
        if (label == 'Confirm Password' && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: EdgeInsets.all(Dimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        border: Border.all(color: Colors.white10),
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
          SizedBox(height: Dimensions.spacingS),
          _buildEnhancedRequirementItem(_hasMinLength, 'At least 8 characters'),
          _buildEnhancedRequirementItem(_hasNumber, 'Contains a number'),
          _buildEnhancedRequirementItem(_hasSymbol, 'Contains a symbol'),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
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
        onPressed: _isLoading ? null : _register,
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
                  'Create Account',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context, FontSizes.button),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: Colors.white70,
            fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          child: Text(
            'Login',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
            ),
          ),
        ),
      ],
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