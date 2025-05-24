import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/dimensions.dart';
import '../core/constants/font_sizes.dart';
import '../core/helpers/responsive_helper.dart';

class CustomGenderPicker extends StatefulWidget {
  final String? initialValue;

  const CustomGenderPicker({
    Key? key,
    this.initialValue,
  }) : super(key: key);

  @override
  State<CustomGenderPicker> createState() => _CustomGenderPickerState();
}

class _CustomGenderPickerState extends State<CustomGenderPicker> {
  String? selectedGender;

  @override
  void initState() {
    super.initState();
    selectedGender = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isWeb ? 800 : double.infinity,
              ),
              child: Column(
                children: [
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
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        SizedBox(width: Dimensions.paddingM),
                        Text(
                          'Select Sex',
                          style: TextStyle(
                            fontSize: isWeb ? FontSizes.heading2 : FontSizes.heading3,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isWeb ? Dimensions.paddingXL : Dimensions.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isWeb ? Dimensions.paddingL : Dimensions.paddingM),
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
                              children: [
                                _buildGenderOption(
                                  'Male',
                                  Icons.male,
                                  selectedGender == 'Male',
                                ),
                                Divider(
                                  color: AppColors.divider.withOpacity(0.5),
                                  height: 1,
                                  indent: isWeb ? Dimensions.paddingXL : Dimensions.paddingM,
                                  endIndent: isWeb ? Dimensions.paddingXL : Dimensions.paddingM,
                                ),
                                _buildGenderOption(
                                  'Female',
                                  Icons.female,
                                  selectedGender == 'Female',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: isWeb ? Dimensions.paddingXL : Dimensions.paddingM,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedGender != null ? AppColors.primary : AppColors.disabled,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: isWeb ? Dimensions.paddingL : Dimensions.paddingM,
                                ),
                              ),
                              onPressed: selectedGender != null
                                  ? () => Navigator.pop(context, selectedGender)
                                  : null,
                              child: Text(
                                'Confirm',
                                style: TextStyle(
                                  fontSize: isWeb ? FontSizes.heading3 : FontSizes.button,
                                  color: selectedGender != null ? Colors.white : AppColors.textSecondary,
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
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon, bool isSelected) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedGender = gender;
          });
        },
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
                  icon,
                  color: isSelected ? AppColors.success : AppColors.primary,
                  size: isWeb ? Dimensions.iconL : Dimensions.iconM,
                ),
              ),
              SizedBox(width: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
              Expanded(
                child: Text(
                  gender,
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
}
