import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'widgets/custom_number_picker.dart';
import 'widgets/custom_gender_picker.dart';
import 'widgets/custom_activitiyLevel_picker.dart';
import 'preference_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/widgets/app_text.dart';
import 'core/helpers/responsive_helper.dart';

class HealthDataPage extends StatefulWidget {
  const HealthDataPage({super.key});

  @override
  State<HealthDataPage> createState() => _HealthDataPageState();
}

class _HealthDataPageState extends State<HealthDataPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = true;

  // Original values from Firestore
  String? originalGender;
  int? originalBirthYear;
  double? originalHeight;
  double? originalWeight;
  String? originalActivityLevel;

  // Editable values
  String? gender;
  int? birthYear;
  String? heightUnit = 'cm';
  double? height;
  double? weight;
  String? activityLevel;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    try {
      final userData = await _firestoreService.getUserPersonalization();
      if (mounted) {
        setState(() {
          // Save original values
          originalGender = userData?['gender'];
          originalBirthYear = userData?['birthYear'];
          originalHeight = userData?['height'];
          originalWeight = userData?['weight'];
          originalActivityLevel = userData?['activityLevel'];

          // Set current values
          gender = originalGender;
          birthYear = originalBirthYear;
          height = originalHeight;
          weight = originalWeight;
          activityLevel = originalActivityLevel;

          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading health data: $e');
      if (mounted) {
        setState(() {
          gender = null;
          birthYear = null;
          height = null;
          weight = null;
          activityLevel = null;
          isLoading = false;
        });
      }
    }
  }

  bool get _hasChanges {
    return gender != originalGender ||
        birthYear != originalBirthYear ||
        height != originalHeight ||
        weight != originalWeight ||
        activityLevel != originalActivityLevel;
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      bool? shouldExit = await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Dismiss",
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          final isWeb = ResponsiveHelper.screenWidth(context) > 800;
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: isWeb ? 500 : MediaQuery.of(context).size.width * 0.9,
                padding: EdgeInsets.all(isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(isWeb ? Dimensions.radiusXL : Dimensions.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                      child: Column(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber,
                            size: isWeb ? Dimensions.iconXL : Dimensions.iconL,
                          ),
                          SizedBox(height: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                          Text(
                          'Any unsaved data\nwill be lost',
                          style: TextStyle(
                            color: Colors.white,
                              fontSize: isWeb ? FontSizes.heading2 : FontSizes.heading3,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                    ),
                          SizedBox(height: isWeb ? Dimensions.paddingM : Dimensions.paddingS),
                          Text(
                      'Are you sure you want leave this page\nbefore you save your data changes?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                              fontSize: isWeb ? FontSizes.body : FontSizes.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? Dimensions.paddingXL : Dimensions.paddingL,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PreferencePage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: isWeb ? Dimensions.paddingL : Dimensions.paddingM,
                        ),
                        shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isWeb ? Dimensions.radiusL : Dimensions.radiusM),
                        ),
                      ),
                            child: Text(
                        'Leave Page',
                        style: TextStyle(
                                fontSize: isWeb ? FontSizes.button : FontSizes.caption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                          SizedBox(height: isWeb ? Dimensions.paddingM : Dimensions.paddingS),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: isWeb ? Dimensions.paddingL : Dimensions.paddingM,
                              ),
                        shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isWeb ? Dimensions.radiusL : Dimensions.radiusM),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                            child: Text(
                        'Cancel',
                        style: TextStyle(
                                fontSize: isWeb ? FontSizes.button : FontSizes.caption,
                          fontWeight: FontWeight.w600,
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

      return shouldExit ?? false;
    } else {
      return true;
    }
  }

  void _onBackPressed(BuildContext context) {
    if (_hasChanges) {
      _onWillPop();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                              onPressed: () => _onBackPressed(context),
                            ),
                          ),
                          SizedBox(height: Dimensions.spacingL),
                          Text(
            'Health Data',
                            style: TextStyle(
                              fontSize: FontSizes.heading1,
                              fontWeight: FontWeight.bold,
            color: AppColors.text,
                            ),
                          ),
                          SizedBox(height: Dimensions.spacingM),
                          Text(
                            'Manage your personal health information',
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
            onPressed: () => _onBackPressed(context),
          ),
        ),
                                SizedBox(width: Dimensions.paddingM),
                                Text(
                                  'Health Data',
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
                          child: isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                                  padding: EdgeInsets.all(isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                  ),
                                  child: Icon(
                                    Icons.person_outline,
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
                                        'Personal Information',
                                                        style: TextStyle(
                                                          fontSize: isWeb ? FontSizes.heading2 : FontSizes.heading3,
                                        color: AppColors.text,
                                        fontWeight: FontWeight.bold,
                                                        ),
                                      ),
                                      SizedBox(height: Dimensions.paddingXS),
                                                      Text(
                                        'Your basic health information',
                                                        style: TextStyle(
                                                          fontSize: isWeb ? FontSizes.body : FontSizes.caption,
                                        color: AppColors.textSecondary,
                                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                                            SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
                                            if (isWeb)
                                              Wrap(
                                                spacing: Dimensions.paddingL,
                                                runSpacing: Dimensions.paddingL,
                                                children: [
                                                  SizedBox(
                                                    width: (MediaQuery.of(context).size.width - 600) / 2,
                                                    child: _buildHealthDataCard(
                                                      'Sex',
                                                      gender ?? 'Not Set',
                                                      Icons.wc,
                                                      _editSex,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: (MediaQuery.of(context).size.width - 600) / 2,
                                                    child: _buildHealthDataCard(
                                                      'Year of Birth',
                                                      birthYear?.toString() ?? 'Not Set',
                                                      Icons.cake,
                                                      _editYearOfBirth,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: (MediaQuery.of(context).size.width - 600) / 2,
                                                    child: _buildHealthDataCard(
                                                      'Height',
                                                      height != null ? '$height cm' : 'Not Set',
                                                      Icons.height,
                                                      _editHeight,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: (MediaQuery.of(context).size.width - 600) / 2,
                                                    child: _buildHealthDataCard(
                                                      'Weight',
                                                      weight != null ? '$weight kg' : 'Not Set',
                                                      Icons.monitor_weight_outlined,
                                                      _editWeight,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: (MediaQuery.of(context).size.width - 600) / 2,
                                                    child: _buildHealthDataCard(
                                                      'Activity Level',
                                                      activityLevel ?? 'Not Set',
                                                      Icons.directions_run,
                                                      _editActivityLevel,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else
                                              Column(
                                                children: [
                            _buildHealthDataCard(
                              'Sex',
                              gender ?? 'Not Set',
                              Icons.wc,
                              _editSex,
                            ),
                            _buildHealthDataCard(
                              'Year of Birth',
                              birthYear?.toString() ?? 'Not Set',
                              Icons.cake,
                              _editYearOfBirth,
                            ),
                            _buildHealthDataCard(
                              'Height',
                              height != null ? '$height cm' : 'Not Set',
                              Icons.height,
                              _editHeight,
                            ),
                            _buildHealthDataCard(
                              'Weight',
                              weight != null ? '$weight kg' : 'Not Set',
                              Icons.monitor_weight_outlined,
                              _editWeight,
                            ),
                            _buildHealthDataCard(
                              'Activity Level',
                              activityLevel ?? 'Not Set',
                              Icons.directions_run,
                              _editActivityLevel,
                                                  ),
                                                ],
                            ),
                          ],
                        ),
                      ),
                                      SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
                      if (!isLoading)
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isWeb ? Dimensions.paddingXL : Dimensions.paddingM,
                                          ),
                                          child: ElevatedButton(
                          style: ButtonStyle(
                                              backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                                                if (states.contains(MaterialState.disabled)) {
                                return AppColors.surface;
                              }
                              return AppColors.primary;
                            }),
                                              minimumSize: MaterialStateProperty.all(Size(double.infinity, 56)),
                                              shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                              ),
                            ),
                          ),
                          onPressed: _hasChanges ? _saveHealthData : null,
                                            child: Text(
                            'Save Changes',
                                              style: TextStyle(
                                                fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
                            color: _hasChanges ? AppColors.text : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                                              ),
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
                ),
              ),
      ),
    );
  }

  Widget _buildHealthDataCard(String label, String value, IconData icon, VoidCallback onEdit) {
    final bool isNotSet = value == 'Not Set';
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return Container(
      margin: EdgeInsets.only(bottom: isWeb ? 0 : Dimensions.paddingM),
      padding: EdgeInsets.all(isWeb ? Dimensions.paddingL : Dimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isWeb ? Dimensions.paddingM : Dimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusS),
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
                  label,
                  style: TextStyle(
                    fontSize: isWeb ? FontSizes.body : FontSizes.caption,
                  color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: Dimensions.paddingXS),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
                  color: isNotSet ? AppColors.error : AppColors.text,
                  fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusM),
            ),
            child: IconButton(
            icon: Icon(
              Icons.edit,
              color: AppColors.primary,
                size: isWeb ? Dimensions.iconM : Dimensions.iconS,
              ),
              onPressed: onEdit,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveHealthData() async {
    setState(() => isLoading = true);
    try {
      await _firestoreService.saveUserPersonalization({
        'gender': gender,
        'birthYear': birthYear,
        'height': height,
        'weight': weight,
        'activityLevel': activityLevel,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Health data saved successfully'),
            ],
          ),
        ),
      );

      setState(() {
        originalGender = gender;
        originalBirthYear = birthYear;
        originalHeight = height;
        originalWeight = weight;
        originalActivityLevel = activityLevel;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving health data: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _editSex() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomGenderPicker(
          initialValue: gender,
        ),
      ),
    ).then((selectedGender) {
      if (selectedGender != null) {
        setState(() {
          gender = selectedGender;
        });
      }
    });
  }

  void _editYearOfBirth() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'What year were you born in?',
          unit: '',
          initialValue: birthYear?.toDouble(),
          minValue: 1900,
          maxValue: 2045,
          onValueChanged: (value) {
            setState(() => birthYear = value.toInt());
          },
        ),
      ),
    );
  }

  void _editHeight() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'Your height',
          unit: 'cm',
          initialValue: height,
          minValue: 0,
          maxValue: 999,
          showDecimals: true,
          onValueChanged: (value) {
            setState(() => height = value);
          },
        ),
      ),
    );
  }

  void _editWeight() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'Your weight',
          unit: 'kg',
          initialValue: weight,
          minValue: 0,
          maxValue: 999,
          showDecimals: true,
          onValueChanged: (value) {
            setState(() => weight = value);
          },
        ),
      ),
    );
  }

  void _editActivityLevel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomActivityLevelPicker(
          initialValue: activityLevel,
        ),
      ),
    ).then((selectedActivityLevel) {
      if (selectedActivityLevel != null) {
        setState(() {
          activityLevel = selectedActivityLevel;
        });
      }
    });
  }
}
