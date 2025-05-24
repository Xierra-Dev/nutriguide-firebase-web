import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/dimensions.dart';
import '../core/constants/font_sizes.dart';
import '../core/helpers/responsive_helper.dart';

class CustomActivityLevelPicker extends StatefulWidget {
  final String? initialValue;

  const CustomActivityLevelPicker({
    Key? key,
    this.initialValue,
  }) : super(key: key);

  @override
  State<CustomActivityLevelPicker> createState() => _CustomActivityLevelPickerState();
}

class _CustomActivityLevelPickerState extends State<CustomActivityLevelPicker> {
  String? selectedActivityLevel;

  final List<Map<String, String>> activityLevels = [
    {
      'level': 'Sedentary',
      'description': 'Little or no exercise, desk job',
    },
    {
      'level': 'Lightly Active',
      'description': 'Light exercise 1-3 days/week',
    },
    {
      'level': 'Moderately Active',
      'description': 'Moderate exercise 3-5 days/week',
    },
    {
      'level': 'Very Active',
      'description': 'Hard exercise 6-7 days/week',
    },
    {
      'level': 'Extra Active',
      'description': 'Very hard exercise, physical job or training twice per day',
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedActivityLevel = widget.initialValue;
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
                          'Activity Level',
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
                              children: activityLevels.map((activity) {
                                final isSelected = selectedActivityLevel == activity['level'];
                                return Column(
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            selectedActivityLevel = activity['level'];
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(isWeb ? Dimensions.paddingM : Dimensions.paddingS),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppColors.success.withOpacity(0.1)
                                                      : AppColors.primary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                                ),
                                                child: Icon(
                                                  Icons.directions_run,
                                                  color: isSelected ? AppColors.success : AppColors.primary,
                                                  size: isWeb ? Dimensions.iconL : Dimensions.iconM,
                                                ),
                                              ),
                                              SizedBox(width: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      activity['level']!,
                                                      style: TextStyle(
                                                        fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
                                                        color: AppColors.text,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    SizedBox(height: Dimensions.paddingXS),
                                                    Text(
                                                      activity['description']!,
                                                      style: TextStyle(
                                                        fontSize: isWeb ? FontSizes.body : FontSizes.caption,
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                  ],
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
                                    ),
                                    if (activity != activityLevels.last)
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
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedActivityLevel != null
                                    ? AppColors.primary
                                    : AppColors.disabled,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: isWeb ? Dimensions.paddingL : Dimensions.paddingM,
                                ),
                              ),
                              onPressed: selectedActivityLevel != null
                                  ? () => Navigator.pop(context, selectedActivityLevel)
                                  : null,
                              child: Text(
                                'Confirm',
                                style: TextStyle(
                                  fontSize: isWeb ? FontSizes.heading3 : FontSizes.button,
                                  color: selectedActivityLevel != null
                                      ? Colors.white
                                      : AppColors.textSecondary,
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
}
