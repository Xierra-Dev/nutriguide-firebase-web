import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'home_page.dart';
import 'goals_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';

class AllergiesPage extends StatefulWidget {
  const AllergiesPage({super.key});

  @override
  _AllergiesPageState createState() => _AllergiesPageState();
}

class _AllergiesPageState extends State<AllergiesPage> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  Set<String> selectedAllergies = {};
  bool _isLoading = false;
  int currentStep = 3;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Improved allergy data structure with icons and descriptions
  final List<Map<String, dynamic>> allergies = [
    {
      'name': 'Dairy',
      'icon': Icons.egg_outlined,
      'description': 'Milk and dairy products',
    },
    {
      'name': 'Eggs',
      'icon': Icons.egg_alt_outlined,
      'description': 'Chicken eggs and egg products',
    },
    {
      'name': 'Fish',
      'icon': Icons.set_meal_outlined,
      'description': 'All types of fish',
    },
    {
      'name': 'Shellfish',
      'icon': Icons.water_outlined,
      'description': 'Crustaceans and mollusks',
    },
    {
      'name': 'Tree nuts',
      'icon': Icons.nature_outlined,
      'description': 'Almonds, cashews, walnuts, etc.',
    },
    {
      'name': 'Peanuts',
      'icon': Icons.grass_outlined,
      'description': 'Peanuts and peanut products',
    },
    {
      'name': 'Wheat',
      'icon': Icons.grass,
      'description': 'Wheat and wheat products',
    },
    {
      'name': 'Soy',
      'icon': Icons.eco_outlined,
      'description': 'Soybeans and soy products',
    },
    {
      'name': 'Gluten',
      'icon': Icons.bakery_dining_outlined,
      'description': 'Found in wheat, barley, and rye',
    },
    {
      'name': 'Sesame',
      'icon': Icons.grain_outlined,
      'description': 'Sesame seeds and oil',
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [

            Container(
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
              ),
            
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingL),
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildAllergiesGrid(),
                      _buildBottomButtons(),
                    ],
                  ),
                ),
              ),
            ),

            // Back button
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(Dimensions.paddingXL),
      child: Column(
        children: [
          // Animated logo container
          TweenAnimationBuilder(
            duration: Duration(milliseconds: 1500),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Container(
                padding: EdgeInsets.all(Dimensions.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1 * value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2 * value),
                      blurRadius: 30 * value,
                      spreadRadius: 5 * value,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.no_food_outlined,
                  size: 60,
                  color: AppColors.primary.withOpacity(value),
                ),
              );
            },
          ),
          SizedBox(height: Dimensions.spacingL),
          
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: index + 1 == currentStep ? 24 : 12,
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: index + 1 == currentStep ? AppColors.primary : Colors.white24,
                ),
              ),
            ),
          ),
          SizedBox(height: Dimensions.spacingXL),
          
          // Title and subtitle with animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Text(
                  'Any Food Allergies?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading2),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Dimensions.spacingM),
                Text(
                  'Select all that apply to you',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergiesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingM),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: Dimensions.spacingM,
        mainAxisSpacing: Dimensions.spacingM,
      ),
      itemCount: allergies.length,
      itemBuilder: (context, index) {
        final allergy = allergies[index];
        final isSelected = selectedAllergies.contains(allergy['name']);
        
        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedAllergies.remove(allergy['name']);
                  } else {
                    selectedAllergies.add(allergy['name']);
                  }
                });
              },
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              child: Container(
                padding: EdgeInsets.all(Dimensions.paddingM),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSelected
                        ? [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.3)]
                        : [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.08)],
                  ),
                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      allergy['icon'],
                      color: isSelected ? AppColors.primary : Colors.white70,
                      size: 28,
                    ),
                    SizedBox(height: Dimensions.spacingS),
                    Text(
                      allergy['name'],
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.white,
                        fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.all(Dimensions.paddingL),
      child: Column(
        children: [
          // Continue Button with gradient and animation
          Container(
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
              onPressed: _isLoading ? null : _saveAllergies,
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Complete Setup',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveTextSize(
                                  context, FontSizes.button),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
              ),
            ),
          ),
          SizedBox(height: Dimensions.spacingL),
          
          // Set Up Later Button with hover effect
          TextButton(
            onPressed: _showSetUpLaterDialog,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: Dimensions.paddingM,
                horizontal: Dimensions.paddingXL,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                side: BorderSide(color: Colors.white24),
              ),
            ),
            child: Text(
              'Set Up Later',
              style: TextStyle(
                color: Colors.white70,
                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetUpLaterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 10.0),
            backgroundColor: Color.fromARGB(255, 91, 91, 91),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Don't Want Our Health\nFeatures?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22.5,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          "To receive personalized meal and recipe recommendations, you need to complete the questionnaire to use Health Features.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          "You can set up later in Settings > Preferences.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(
                      bottom: 30,
                      left: 30,
                      right: 30,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                          ),
                          child: Text(
                            "Skip Questionnaire",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                        ),
                        SizedBox(height: 17.5),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                          ),
                          child: Text(
                            "Return to Questionnaire",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
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
        );
      },
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + Dimensions.paddingM,
      left: Dimensions.paddingL,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const GoalsPage()),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveAllergies() async {
    // Show confirmation dialog with enhanced design
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 300),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: 0.95 + (0.05 * value),
              child: Opacity(
                opacity: value,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 400),
                    padding: EdgeInsets.all(Dimensions.paddingL),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.surface.withOpacity(0.95),
                          AppColors.surface,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated success icon
                        TweenAnimationBuilder(
                          duration: Duration(milliseconds: 600),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: EdgeInsets.all(Dimensions.paddingL),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      blurRadius: 20 * value,
                                      spreadRadius: 5 * value,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_circle_outline,
                                  color: AppColors.primary,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: Dimensions.spacingXL),
                        
                        // Title with shimmer effect
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.9),
                              Colors.white,
                            ],
                            stops: [0.0, 0.5, 1.0],
                            transform: GradientRotation(value * 3.14 * 2),
                          ).createShader(bounds),
                          child: Text(
                            'Ready to Start?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveHelper.getAdaptiveTextSize(
                                  context, FontSizes.heading3),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: Dimensions.spacingM),
                        
                        // Message
                        Text(
                          'We\'ll personalize your experience based on your preferences.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: ResponsiveHelper.getAdaptiveTextSize(
                                context, FontSizes.body),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: Dimensions.spacingXL),
                        
                        // Buttons with hover effect
                        Row(
                          children: [
                            // Cancel Button
                            Expanded(
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: TweenAnimationBuilder(
                                  duration: Duration(milliseconds: 200),
                                  tween: Tween<double>(begin: 0, end: 1),
                                  builder: (context, double value, child) {
                                    return TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            vertical: Dimensions.paddingM),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(Dimensions.radiusL),
                                          side: BorderSide(color: Colors.white24),
                                        ),
                                      ),
                                      child: Text(
                                        'Review Changes',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: ResponsiveHelper.getAdaptiveTextSize(
                                              context, FontSizes.button),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: Dimensions.spacingM),
                            
                            // Confirm Button
                            Expanded(
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        Color(0xFFFF6E40),
                                      ],
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(Dimensions.radiusL),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: EdgeInsets.symmetric(
                                          vertical: Dimensions.paddingM),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(Dimensions.radiusL),
                                      ),
                                    ),
                                    child: Text(
                                      'Let\'s Begin!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: ResponsiveHelper.getAdaptiveTextSize(
                                            context, FontSizes.button),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Proceed only if confirmed
    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.saveUserAllergies(selectedAllergies.toList());
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving allergies: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}