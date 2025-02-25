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
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: const Text(
                          'Any unsaved data\nwill be lost',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.linear(1.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 21.5),
                    const Text(
                      'Are you sure you want leave this page\nbefore you save your data changes?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textScaler: TextScaler.linear(1.0),
                    ),
                    const SizedBox(height: 37),
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Leave Page',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textScaler: TextScaler.linear(1.0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textScaler: TextScaler.linear(1.0),
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: AppText(
            'Health Data',
            fontSize: FontSizes.heading3,
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () => _onBackPressed(context),
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                child: Padding(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(Dimensions.paddingM),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                  ),
                                  child: Icon(
                                    Icons.person_outline,
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
                                        'Personal Information',
                                        fontSize: FontSizes.heading3,
                                        color: AppColors.text,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      SizedBox(height: Dimensions.paddingXS),
                                      AppText(
                                        'Your basic health information',
                                        fontSize: FontSizes.caption,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: Dimensions.paddingL),
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
                      ),
                      SizedBox(height: Dimensions.paddingL),
                      if (!isLoading)
                        ElevatedButton(
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
                          child: AppText(
                            'Save Changes',
                            fontSize: FontSizes.body,
                            color: _hasChanges ? AppColors.text : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHealthDataCard(String label, String value, IconData icon, VoidCallback onEdit) {
    final bool isNotSet = value == 'Not Set';

    return Container(
      margin: EdgeInsets.only(bottom: Dimensions.paddingM),
      padding: EdgeInsets.all(Dimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Dimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusS),
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
                  label,
                  fontSize: FontSizes.caption,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: Dimensions.paddingXS),
                AppText(
                  value,
                  fontSize: FontSizes.body,
                  color: isNotSet ? AppColors.error : AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: AppColors.primary,
              size: Dimensions.iconM,
            ),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(String label, String value, VoidCallback onEdit) {
    final bool isNotSet = value == 'Not Set';

    return Column(
      children: [
        ListTile(
          title: AppText(
            label,
            fontSize: FontSizes.body,
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
          trailing: Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: AppText(
                    value,
                    fontSize: FontSizes.body,
                    color: isNotSet ? AppColors.error : AppColors.text,
                  ),
                ),
                SizedBox(width: Dimensions.paddingS),
                Transform.translate(
                  offset: const Offset(16, 0),
                  child: IconButton(
                    icon: Icon(Icons.edit, color: AppColors.text, size: Dimensions.iconM),
                    onPressed: onEdit,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingM),
          child: Divider(
            color: AppColors.border,
            height: 1,
          ),
        ),
      ],
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
