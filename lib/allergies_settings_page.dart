import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'preference_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';

class AllergiesSettingsPage extends StatefulWidget {
  const AllergiesSettingsPage({super.key});

  @override
  State<AllergiesSettingsPage> createState() => _AllergiesSettingsPageState();
}

class _AllergiesSettingsPageState extends State<AllergiesSettingsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = true;
  Set<String> selectedAllergies = {};
  bool isEditing = false;
  bool _hasChanges = false;

  final List<String> allergies = [
    'Dairy',
    'Eggs',
    'Fish',
    'Shellfish',
    'Tree nuts (e.g., almonds, walnuts, cashews)',
    'Peanuts',
    'Wheat',
    'Soy',
    'Glutten',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllergies();
  }

  Future<void> _loadAllergies() async {
    try {
      final userAllergies = await _firestoreService.getUserAllergies();
      setState(() {
        selectedAllergies = Set.from(userAllergies);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading allergies: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveAllergies() async {
    setState(() => isLoading = true);
    try {
      await _firestoreService.saveUserAllergies(selectedAllergies.toList());
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
        SnackBar(content: Text('Error saving allergies: $e')),
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
        pageBuilder: (context, animation, secondaryAnimation) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: EdgeInsets.all(Dimensions.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Any unsaved data\nwill be lost',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading3),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: Dimensions.spacingM),
                    Text(
                      'Are you sure you want leave this page\nbefore you save your data changes?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingL),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PreferencePage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.text,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: Dimensions.paddingM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusL),
                        ),
                      ),
                      child: Text(
                        'Leave Page',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingM),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.text,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: Dimensions.paddingM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusL),
                          side: BorderSide(color: AppColors.border.withOpacity(0.2)),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
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
      return shouldExit ?? false;
    }
    return true;
  }

  void _onBackPressed(BuildContext context) {
    if (_hasChanges) {
      // Jika ada perubahan yang belum disimpan, panggil _onWillPop
      _onWillPop();
    } else {
      Navigator.pop(context); // Jika tidak ada perubahan, cukup navigasi kembali
    }
  }

  // Add this helper method to your class
  IconData _getAllergyIcon(String allergy) {
    switch (allergy.toLowerCase()) {
      case 'dairy':
        return Icons.water_drop;
      case 'eggs':
        return Icons.egg;
      case 'fish':
        return Icons.set_meal;
      case 'shellfish':
        return Icons.cruelty_free;
      case 'tree nuts (e.g., almonds, walnuts, cashews)':
        return Icons.grass;
      case 'peanuts':
        return Icons.grain;
      case 'wheat':
        return Icons.grass;
      case 'soy':
        return Icons.spa;
      case 'glutten':
        return Icons.breakfast_dining;
      default:
        return Icons.warning_amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            elevation: 0,
            title: Text(
              'Allergies',
              style: TextStyle(
                color: AppColors.text,
                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading2),
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(Dimensions.paddingXS),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Icon(Icons.arrow_back, color: AppColors.primary, size: Dimensions.iconM),
              ),
              onPressed: () => _onBackPressed(context),
            ),
          ),
          body: isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Column(
                  children: [
                    // Info Card
                    Container(
                      margin: EdgeInsets.all(Dimensions.paddingM),
                      padding: EdgeInsets.all(Dimensions.paddingM),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusL),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(Dimensions.paddingS),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: Dimensions.iconM,
                            ),
                          ),
                          SizedBox(width: Dimensions.spacingM),
                          Expanded(
                            child: Text(
                              'Select any food allergies you have to help us customize your experience',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Allergies List
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingM),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(Dimensions.radiusL),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          itemCount: allergies.length,
                          itemBuilder: (context, index) {
                            final allergy = allergies[index];
                            final isSelected = selectedAllergies.contains(allergy);
                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingM,
                                    vertical: Dimensions.paddingS,
                                  ),
                                  leading: Container(
                                    padding: EdgeInsets.all(Dimensions.paddingS),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? AppColors.success.withOpacity(0.1)
                                          : AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                    ),
                                    child: Icon(
                                      _getAllergyIcon(allergy),  // Add this helper method
                                      color: isSelected ? AppColors.success : AppColors.primary,
                                      size: Dimensions.iconM,
                                    ),
                                  ),
                                  title: Text(
                                    allergy,
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected 
                                          ? AppColors.success.withOpacity(0.1)
                                          : Colors.transparent,
                                    ),
                                    child: Icon(
                                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                                      color: isSelected ? AppColors.success : AppColors.textSecondary,
                                      size: Dimensions.iconM,
                                    ),
                                  ),
                                  onTap: isEditing ? () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedAllergies.remove(allergy);
                                      } else {
                                        selectedAllergies.add(allergy);
                                      }
                                      _hasChanges = true;
                                    });
                                  } : null,
                                ),
                                if (index < allergies.length - 1)
                                  Divider(
                                    color: AppColors.divider.withOpacity(0.5),
                                    height: 1,
                                    indent: Dimensions.paddingM,
                                    endIndent: Dimensions.paddingM,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Bottom Buttons
                    Container(
                      padding: EdgeInsets.all(Dimensions.paddingM),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: _hasChanges ? _saveAllergies : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasChanges ? AppColors.primary : AppColors.disabled,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                              ),
                              padding: EdgeInsets.symmetric(vertical: Dimensions.paddingM),
                            ),
                            child: Text(
                              'SAVE CHANGES',
                              style: TextStyle(
                                color: _hasChanges ? Colors.white : AppColors.textSecondary,
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: Dimensions.spacingM),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEditing ? AppColors.surface : AppColors.text,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                side: isEditing 
                                    ? BorderSide(color: AppColors.error)
                                    : BorderSide.none,
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
                              isEditing ? 'CANCEL' : 'EDIT',
                              style: TextStyle(
                                color: isEditing ? AppColors.error : AppColors.background,
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
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
    );
  }
}
