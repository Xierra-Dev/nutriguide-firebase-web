import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutriguide/landing_page.dart';
import 'package:nutriguide/login_page.dart';
import 'services/auth_service.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  final User? user;

  const EmailVerificationPage({
    super.key,
    required this.email,
    this.user
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
      : super(
    pageBuilder: (
        BuildContext context,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
        ) => page,
    transitionsBuilder: (
        BuildContext context,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
        Widget child,
        ) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.easeOutQuad,
        ),),
        child: child,
      );
    },
  );
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final AuthService _authService = AuthService();
  bool isEmailVerified = false;
  Timer? timer;
  bool canResendEmail = true;
  int resendTimeout = 30;
  Timer? resendTimer;

  // New timer-related variables
  late Timer _verificationTimer;
  int _remainingSeconds = 180; // 3 minutes

  @override
  void initState() {
    super.initState();
    isEmailVerified = _authService.isEmailVerified();

    if (!isEmailVerified) {
      _startVerificationTimer();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    resendTimer?.cancel();
    _verificationTimer.cancel();
    super.dispose();
  }

  void _startVerificationTimer() {
    _verificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        // Periodically check verification status
        await FirebaseAuth.instance.currentUser?.reload();

        setState(() {
          isEmailVerified = _authService.isEmailVerified();
        });

        if (isEmailVerified) {
          timer.cancel();

          // Update Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({
            'emailVerified': true
          });

          // Show success dialog
          _showVerificationSuccessDialog();  // Tambahkan ini
        }
      } else {
        timer.cancel();
        // Handle timeout - maybe show a dialog or option to resend
      }
    });
  }

  void _showVerificationSuccessDialog() {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
            ),
            child: Container(
              width: isWeb ? 500 : null,
              padding: EdgeInsets.all(isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon with Animation
                  TweenAnimationBuilder(
                    duration: Duration(milliseconds: 800),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: isWeb ? 140 : 100,
                          height: isWeb ? 140 : 100,
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: isWeb ? 80 : Dimensions.iconXL,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.spacingL),

                  // Success Title with Animation
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: ModalRoute.of(context)!.animation!,
                      curve: Interval(0.5, 1.0),
                    ),
                    child: Text(
                      'Email Verified!',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: ResponsiveHelper.getAdaptiveTextSize(
                          context, 
                          isWeb ? FontSizes.heading2 : FontSizes.heading3
                        ),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: isWeb ? Dimensions.spacingL : Dimensions.spacingM),

                  // Success Message
                  Text(
                    'Your email has been successfully verified.\nYou can now login to your account.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context, 
                        isWeb ? FontSizes.heading3 : FontSizes.body
                      ),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: isWeb ? Dimensions.paddingXL * 2 : Dimensions.spacingXL),

                  // Login Button with Animation
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: ModalRoute.of(context)!.animation!,
                      curve: Interval(0.5, 1.0, curve: Curves.easeOut),
                    )),
                    child: Container(
                      width: isWeb ? 300 : double.infinity,
                      height: isWeb ? 60 : 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(Dimensions.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radiusL),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? Dimensions.paddingXL : Dimensions.paddingL,
                            vertical: isWeb ? Dimensions.paddingM : Dimensions.paddingS,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.login_rounded,
                              color: Colors.white,
                              size: isWeb ? 24 : 20,
                            ),
                            SizedBox(width: Dimensions.paddingM),
                            Text(
                              'Login Now',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(
                                  context, 
                                  isWeb ? FontSizes.heading3 : FontSizes.button
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isWeb ? Dimensions.spacingM : Dimensions.spacingS),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _authService.resendVerificationEmail();

      setState(() {
        canResendEmail = false;
        _remainingSeconds = 180; // Reset timer
      });

      resendTimer = Timer.periodic(
        const Duration(seconds: 1),
            (timer) {
          if (resendTimeout > 0) {
            setState(() {
              resendTimeout--;
            });
          } else {
            setState(() {
              canResendEmail = true;
              resendTimeout = 30;
            });
            timer.cancel();
          }
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email has been sent'),
          backgroundColor: Colors.green,
        ),
      );

      // Restart the verification timer
      _startVerificationTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error sending verification email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {
      isEmailVerified = _authService.isEmailVerified();
    });
    
    if (isEmailVerified) {
      timer?.cancel();
      
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'emailVerified': true
      });

      // Show success dialog
      _showVerificationSuccessDialog();
    }
  }

  Future<bool> _onWillPop() async {
    return false; // Prevents dialog from being dismissed with back button
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)), // Lock text scale factor
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Email Verification',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 100,
                  color: Colors.deepOrange,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Verify your email address',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We\'ve sent a verification email to:\n${widget.email}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Time remaining: ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: canResendEmail ? resendVerificationEmail : () {},
                  child: Text(
                    canResendEmail
                        ? 'Resend Email'
                        : 'Resend in ${resendTimeout}s',
                    style: const TextStyle(
                      fontSize: 16.5,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Sign out if the user chooses to cancel
                    FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LandingPage()),
                    );
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 20),
                isEmailVerified
                    ? const Text(
                  'Email Verified!',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                )
                    : const Text(
                  'Waiting for verification...',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}