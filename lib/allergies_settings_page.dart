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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                MaterialPageRoute(builder: (context) => const PreferencePage()),
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
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1)),
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
                              'Allergies',
                              style: TextStyle(
                                fontSize: FontSizes.heading1,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            SizedBox(height: Dimensions.spacingM),
                            Text(
                              'Manage your food allergies and restrictions',
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
                                    'Allergies',
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
                                          margin: EdgeInsets.only(bottom: Dimensions.paddingL),
                                          padding: EdgeInsets.all(isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(isWeb ? Dimensions.paddingM : Dimensions.paddingS),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.info_outline,
                                                  color: AppColors.primary,
                                                  size: isWeb ? Dimensions.iconL : Dimensions.iconM,
                                                ),
                                              ),
                                              SizedBox(width: isWeb ? Dimensions.paddingL : Dimensions.spacingM),
                                              Expanded(
                                                child: Text(
                                                  'Select any food allergies you have to help us customize your experience',
                                                  style: TextStyle(
                                                    color: AppColors.text,
                                                    fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
                                                  ),
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
                                            children: allergies.map((allergy) {
                                              final isSelected = selectedAllergies.contains(allergy);
                                              return Column(
                                                children: [
                                                  ListTile(
                                                    contentPadding: EdgeInsets.symmetric(
                                                      horizontal: isWeb ? Dimensions.paddingL : Dimensions.paddingM,
                                                      vertical: isWeb ? Dimensions.paddingM : Dimensions.paddingS,
                                                    ),
                                                    leading: Container(
                                                      padding: EdgeInsets.all(isWeb ? Dimensions.paddingM : Dimensions.paddingS),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? AppColors.success.withOpacity(0.1)
                                                            : AppColors.primary.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                                      ),
                                                      child: Icon(
                                                        _getAllergyIcon(allergy),
                                                        color: isSelected ? AppColors.success : AppColors.primary,
                                                        size: isWeb ? Dimensions.iconL : Dimensions.iconM,
                                                      ),
                                                    ),
                                                    title: Text(
                                                      allergy,
                                                      style: TextStyle(
                                                        color: AppColors.text,
                                                        fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
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
                                                        size: isWeb ? Dimensions.iconL : Dimensions.iconM,
                                                      ),
                                                    ),
                                                    onTap: isEditing
                                                        ? () {
                                                            setState(() {
                                                              if (isSelected) {
                                                                selectedAllergies.remove(allergy);
                                                              } else {
                                                                selectedAllergies.add(allergy);
                                                              }
                                                              _hasChanges = true;
                                                            });
                                                          }
                                                        : null,
                                                  ),
                                                  if (allergy != allergies.last)
                                                    Divider(
                                                      color: AppColors.divider.withOpacity(0.5),
                                                      height: 1,
                                                      indent: isWeb ? Dimensions.paddingXL : Dimensions.paddingM,
                                                      endIndent: isWeb ? Dimensions.paddingXL : Dimensions.paddingM,
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
                                                    fontSize: isWeb ? FontSizes.heading3 : FontSizes.button,
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
                                                    fontSize: isWeb ? FontSizes.heading3 : FontSizes.button,
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
}
