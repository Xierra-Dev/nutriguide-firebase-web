import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'preference_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/widgets/app_text.dart';
import 'core/helpers/responsive_helper.dart';

class GoalsSettingsPage extends StatefulWidget {
  const GoalsSettingsPage({super.key});

  @override
  State<GoalsSettingsPage> createState() => _GoalsSettingsPageState();
}

class _GoalsSettingsPageState extends State<GoalsSettingsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = true;
  Set<String> selectedGoals = {};
  bool isEditing = false;
  bool _hasChanges = false;

  final List<String> goals = [
    'Weight Less',
    'Get Healthier',
    'Look Better',
    'Reduce Stress',
    'Sleep Better',
  ];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final userGoals = await _firestoreService.getUserGoals();
      setState(() {
        selectedGoals = Set.from(userGoals);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading goals: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveGoals() async {
    setState(() => isLoading = true);
    try {
      await _firestoreService.saveUserGoals(selectedGoals.toList());
      setState(() {
        isEditing = false;
        _hasChanges = false; // Reset perubahan setelah disimpan
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10), // Add some spacing between icon and text
              Text('Health data saved successfully'),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goals: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
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
      // Jika ada perubahan yang belum disimpan, panggil _onWillPop
      _onWillPop();
    } else {
      Navigator.pop(context); // Jika tidak ada perubahan, cukup navigasi kembali
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: WillPopScope(
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
                              'Personalized Goals',
                              style: TextStyle(
                                fontSize: FontSizes.heading1,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            SizedBox(height: Dimensions.spacingM),
                            Text(
                              'Choose what you want to achieve',
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
                                    'Personalized Goals',
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
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
                                          margin: EdgeInsets.only(bottom: Dimensions.paddingL),
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
                                                  Icons.flag_outlined,
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
                                                      'Set Your Goals',
                                                      style: TextStyle(
                                                        fontSize: isWeb ? FontSizes.heading2 : FontSizes.heading3,
                                                        color: AppColors.text,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: Dimensions.paddingXS),
                                                    Text(
                                                      'Choose what you want to achieve',
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
                                        ),
                                        Container(
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
                                            children: goals.map((goal) {
                                              final isSelected = selectedGoals.contains(goal);
                                              return Column(
                                                children: [
                                                  _buildGoalItem(
                                                    goal: goal,
                                                    isSelected: isSelected,
                                                    onTap: isEditing
                                                        ? () {
                                                            setState(() {
                                                              if (isSelected) {
                                                                selectedGoals.remove(goal);
                                                              } else {
                                                                selectedGoals.add(goal);
                                                              }
                                                              _hasChanges = true;
                                                            });
                                                          }
                                                        : null,
                                                  ),
                                                  if (goal != goals.last)
                                                    Divider(
                                                      color: AppColors.border,
                                                      height: 1,
                                                      indent: Dimensions.paddingL,
                                                      endIndent: Dimensions.paddingL,
                                                    ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                        SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isWeb ? Dimensions.paddingXL : Dimensions.paddingM,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              ElevatedButton(
                                                style: ButtonStyle(
                                                  backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                                                    if (states.contains(MaterialState.disabled)) {
                                                      return AppColors.surface;
                                                    }
                                                    return AppColors.primary;
                                                  }),
                                                  shape: MaterialStateProperty.all(
                                                    RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                                    ),
                                                  ),
                                                  padding: MaterialStateProperty.all(
                                                    EdgeInsets.symmetric(vertical: Dimensions.paddingM),
                                                  ),
                                                ),
                                                onPressed: _hasChanges ? _saveGoals : null,
                                                child: Text(
                                                  'Save Changes',
                                                  style: TextStyle(
                                                    fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
                                                    color: _hasChanges ? AppColors.text : AppColors.textSecondary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: Dimensions.paddingM),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isEditing ? AppColors.surface : AppColors.background,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                                    side: BorderSide(
                                                      color: isEditing ? AppColors.error : AppColors.border,
                                                    ),
                                                  ),
                                                  padding: EdgeInsets.symmetric(vertical: Dimensions.paddingM),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    isEditing = !isEditing;
                                                    if (!isEditing) {
                                                      _hasChanges = false;
                                                    }
                                                  });
                                                },
                                                child: Text(
                                                  isEditing ? 'Cancel' : 'Edit Goals',
                                                  style: TextStyle(
                                                    fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
                                                    color: isEditing ? AppColors.error : AppColors.text,
                                                    fontWeight: FontWeight.bold,
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

  Widget _buildGoalItem({
    required String goal,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(isWeb ? Dimensions.paddingL : Dimensions.paddingM),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isWeb ? Dimensions.paddingM : Dimensions.paddingS),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.success.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Icon(
                  _getGoalIcon(goal),
                  color: isSelected ? AppColors.success : AppColors.primary,
                  size: isWeb ? Dimensions.iconL : Dimensions.iconM,
                ),
              ),
              SizedBox(width: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
              Expanded(
                child: Text(
                  goal,
                  style: TextStyle(
                    fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
                    color: AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppColors.success : AppColors.textSecondary,
                size: isWeb ? Dimensions.iconL : Dimensions.iconM,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGoalIcon(String goal) {
    switch (goal) {
      case 'Weight Less':
        return Icons.monitor_weight_outlined;
      case 'Get Healthier':
        return Icons.favorite_outline;
      case 'Look Better':
        return Icons.face_outlined;
      case 'Reduce Stress':
        return Icons.spa_outlined;
      case 'Sleep Better':
        return Icons.bedtime_outlined;
      default:
        return Icons.flag_outlined;
    }
  }
}
