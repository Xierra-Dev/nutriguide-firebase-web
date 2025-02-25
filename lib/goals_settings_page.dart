import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'preference_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/widgets/app_text.dart';

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
      // Jika ada perubahan, tampilkan dialog konfirmasi
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
                width: MediaQuery.of(context).size.width * 0.9, // Lebar 90% dari layar
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E), // Warna latar belakang gelap
                  borderRadius: BorderRadius.circular(28), // Sudut yang lebih bulat
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min ,
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
                    ),
                    const SizedBox(height: 37),
                    // Tombol disusun secara vertikal
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      return shouldExit ?? false; // Pastikan selalu mengembalikan bool
    } else {
      // Jika tidak ada perubahan, langsung keluar
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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: AppText(
              'Personalized Goals',
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
              : Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Dimensions.paddingL),
                      margin: EdgeInsets.all(Dimensions.paddingM),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(Dimensions.radiusL),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(Dimensions.paddingM),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(Dimensions.radiusM),
                            ),
                            child: Icon(
                              Icons.flag_outlined,
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
                                  'Set Your Goals',
                                  fontSize: FontSizes.heading3,
                                  color: AppColors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                                SizedBox(height: Dimensions.paddingXS),
                                AppText(
                                  'Choose what you want to achieve',
                                  fontSize: FontSizes.caption,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingM),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(Dimensions.radiusL),
                        ),
                        child: ListView.builder(
                          itemCount: goals.length,
                          itemBuilder: (context, index) {
                            final goal = goals[index];
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
                                if (index < goals.length - 1)
                                  Divider(
                                    color: AppColors.border,
                                    height: 1,
                                    indent: Dimensions.paddingL,
                                    endIndent: Dimensions.paddingL,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(Dimensions.paddingM),
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
                            child: AppText(
                              'Save Changes',
                              fontSize: FontSizes.body,
                              color: _hasChanges ? AppColors.text : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
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
                            child: AppText(
                              isEditing ? 'Cancel' : 'Edit Goals',
                              fontSize: FontSizes.body,
                              color: isEditing ? AppColors.error : AppColors.text,
                              fontWeight: FontWeight.bold,
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
  }

  Widget _buildGoalItem({
    required String goal,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingM),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Dimensions.paddingS),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.success.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Icon(
                  _getGoalIcon(goal),
                  color: isSelected ? AppColors.success : AppColors.primary,
                  size: Dimensions.iconM,
                ),
              ),
              SizedBox(width: Dimensions.paddingM),
              Expanded(
                child: AppText(
                  goal,
                  fontSize: FontSizes.body,
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppColors.success : AppColors.textSecondary,
                size: Dimensions.iconM,
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
