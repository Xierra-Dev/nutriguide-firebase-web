import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/dimensions.dart';
import '../core/constants/font_sizes.dart';
import '../core/helpers/responsive_helper.dart';

class CustomNumberPicker extends StatefulWidget {
  final String title;
  final String unit;
  final double? initialValue;
  final double minValue;
  final double maxValue;
  final bool showDecimals;
  final Function(double) onValueChanged;

  const CustomNumberPicker({
    Key? key,
    required this.title,
    required this.unit,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    this.showDecimals = false,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  State<CustomNumberPicker> createState() => _CustomNumberPickerState();
}

class _CustomNumberPickerState extends State<CustomNumberPicker> {
  late double currentValue;
  late double tempValue; // Temporary value for tracking changes without saving
  late FixedExtentScrollController _mainController;
  late FixedExtentScrollController _decimalController;
  double startDragY = 0;
  double currentDragValue = 0;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue ?? widget.minValue;
    tempValue = currentValue;
    _mainController = FixedExtentScrollController(
      initialItem: _getInitialMainIndex(),
    );
    if (widget.showDecimals) {
      _decimalController = FixedExtentScrollController(
        initialItem: ((tempValue - tempValue.floor()) * 10).round(),
      );
    }
  }

  int _getInitialMainIndex() {
    if (widget.title == 'What year were you born in?') {
      return 2000 - widget.minValue.toInt();
    } else if (widget.unit == 'kg') {
      return 50 - widget.minValue.toInt();
    } else if (widget.unit == 'cm') {
      return 170 - widget.minValue.toInt();
    }
    return (tempValue - widget.minValue).floor();
  }

  void _handleDragUpdate(DragUpdateDetails details, bool isMain) {
    final controller = isMain ? _mainController : _decimalController;
    final sensitivity = isMain ? 1.0 : 0.1;
    
    setState(() {
      currentDragValue -= details.primaryDelta! * sensitivity;
      final targetItem = (currentDragValue / 40).round();
      
      if (isMain) {
        final minItem = 0;
        final maxItem = (widget.maxValue - widget.minValue).floor();
        final boundedItem = targetItem.clamp(minItem, maxItem);
        controller.jumpToItem(boundedItem);
        tempValue = (widget.minValue + boundedItem).toDouble();
        if (widget.showDecimals) {
          tempValue += _decimalController.selectedItem / 10;
        }
      } else {
        final boundedItem = targetItem.clamp(0, 9);
        controller.jumpToItem(boundedItem);
        tempValue = tempValue.floor() + (boundedItem / 10);
      }
    });
  }

  void _handleDragStart(DragStartDetails details) {
    startDragY = details.globalPosition.dy;
    currentDragValue = _mainController.selectedItem * 40.0;
  }

  void _handleDragEnd(DragEndDetails details) {
    currentDragValue = _mainController.selectedItem * 40.0;
  }

  @override
  void dispose() {
    _mainController.dispose();
    if (widget.showDecimals) {
      _decimalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveHelper.screenWidth(context) > 800;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: MediaQuery(
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
                            widget.title,
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
                                children: [
                                  Container(
                                    height: isWeb ? 300 : 200,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: isWeb ? 200 : 120,
                                          child: GestureDetector(
                                            onVerticalDragStart: _handleDragStart,
                                            onVerticalDragUpdate: (details) => _handleDragUpdate(details, true),
                                            onVerticalDragEnd: _handleDragEnd,
                                            child: ListWheelScrollView.useDelegate(
                                              controller: _mainController,
                                              itemExtent: isWeb ? 60 : 40,
                                              perspective: 0.005,
                                              diameterRatio: 1.2,
                                              physics: const FixedExtentScrollPhysics(),
                                              childDelegate: ListWheelChildBuilderDelegate(
                                                childCount: (widget.maxValue - widget.minValue).floor() + 1,
                                                builder: (context, index) {
                                                  final value = widget.minValue.floor() + index;
                                                  return _buildNumberItem(
                                                    value.toString(),
                                                    value == tempValue.floor(),
                                                    isWeb,
                                                  );
                                                },
                                              ),
                                              onSelectedItemChanged: (index) {
                                                setState(() {
                                                  if (widget.showDecimals) {
                                                    tempValue = (widget.minValue + index) +
                                                        (_decimalController.selectedItem / 10);
                                                  } else {
                                                    tempValue = (widget.minValue + index).toDouble();
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        if (widget.showDecimals) ...[
                                          Text(
                                            '.',
                                            style: TextStyle(
                                              color: AppColors.text,
                                              fontSize: isWeb ? FontSizes.heading1 : FontSizes.heading2,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            width: isWeb ? 100 : 60,
                                            child: GestureDetector(
                                              onVerticalDragUpdate: (details) => _handleDragUpdate(details, false),
                                              child: ListWheelScrollView.useDelegate(
                                                controller: _decimalController,
                                                itemExtent: isWeb ? 60 : 40,
                                                perspective: 0.005,
                                                diameterRatio: 1.2,
                                                physics: const FixedExtentScrollPhysics(),
                                                childDelegate: ListWheelChildBuilderDelegate(
                                                  childCount: 10,
                                                  builder: (context, index) {
                                                    return _buildNumberItem(
                                                      index.toString(),
                                                      index == ((tempValue - tempValue.floor()) * 10).round(),
                                                      isWeb,
                                                    );
                                                  },
                                                ),
                                                onSelectedItemChanged: (index) {
                                                  setState(() {
                                                    tempValue = tempValue.floor() + (index / 10);
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                        SizedBox(width: isWeb ? Dimensions.paddingL : Dimensions.paddingM),
                                        Text(
                                          widget.unit,
                                          style: TextStyle(
                                            fontSize: isWeb ? FontSizes.heading3 : FontSizes.body,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isWeb ? Dimensions.paddingXL : Dimensions.paddingL),
                                  Text(
                                    'Value must be between ${widget.minValue.toInt()} and ${widget.maxValue.toInt()} ${widget.unit}',
                                    style: TextStyle(
                                      fontSize: isWeb ? FontSizes.body : FontSizes.caption,
                                      color: AppColors.textSecondary,
                                    ),
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
                                  backgroundColor: AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: isWeb ? Dimensions.paddingL : Dimensions.paddingM,
                                  ),
                                ),
                                onPressed: () {
                                  currentValue = tempValue;
                                  widget.onValueChanged(currentValue);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Confirm',
                                  style: TextStyle(
                                    fontSize: isWeb ? FontSizes.heading3 : FontSizes.button,
                                    color: Colors.white,
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
      ),
    );
  }

  Widget _buildNumberItem(String text, bool isSelected, bool isWeb) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? AppColors.text : AppColors.textSecondary,
          fontSize: isSelected 
              ? (isWeb ? FontSizes.heading1 : FontSizes.heading2)
              : (isWeb ? FontSizes.heading2 : FontSizes.heading3),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
