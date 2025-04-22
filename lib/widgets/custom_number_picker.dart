import 'package:flutter/material.dart';

class CustomNumberPicker extends StatefulWidget {
  final String title;
  final String unit;
  final double? initialValue;
  final double minValue;
  final double maxValue;
  final bool showDecimals;
  final Function(double) onValueChanged;

  const CustomNumberPicker({
    super.key,
    required this.title,
    required this.unit,
    this.initialValue,
    required this.minValue,
    required this.maxValue,
    this.showDecimals = false,
    required this.onValueChanged,
  });

  @override
  _CustomNumberPickerState createState() => _CustomNumberPickerState();
}

class _CustomNumberPickerState extends State<CustomNumberPicker> {
  late FixedExtentScrollController _mainController;
  late FixedExtentScrollController _decimalController;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue ?? widget.minValue;
    _mainController = FixedExtentScrollController(
      initialItem: _currentValue.floor() - widget.minValue.floor(),
    );
    if (widget.showDecimals) {
      _decimalController = FixedExtentScrollController(
        initialItem: ((_currentValue - _currentValue.floor()) * 10).round(),
      );
    }
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
    // Get screen size for responsive calculations
    final screenSize = MediaQuery.of(context).size;

    // Calculate responsive sizes
    final double titleFontSize = screenSize.width * 0.07;
    final double selectedNumberFontSize = screenSize.width * 0.1;
    final double unselectedNumberFontSize = screenSize.width * 0.075;
    final double unitFontSize = screenSize.width * 0.055;
    final double buttonFontSize = screenSize.width * 0.04;
    final double decimalPointFontSize = screenSize.width * 0.1;
    final double iconSize = screenSize.width * 0.06;

    // Calculate responsive dimensions
    final double numberPickerWidth = screenSize.width * 0.25;
    final double decimalPickerWidth = screenSize.width * 0.125;
    final double itemExtent = screenSize.height * 0.06;
    final double verticalPadding = screenSize.height * 0.02;

    return MediaQuery(
      // Prevent system font scaling
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                      left: screenSize.width * 0.025,
                      top: verticalPadding
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: iconSize,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              SizedBox(height: verticalPadding),
              Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: numberPickerWidth,
                      child: ListWheelScrollView.useDelegate(
                        controller: _mainController,
                        itemExtent: itemExtent,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: (widget.maxValue - widget.minValue).floor() + 1,
                          builder: (context, index) {
                            final value = widget.minValue.floor() + index;
                            return _buildNumberItem(
                              value.toString(),
                              value == _currentValue.floor(),
                              selectedNumberFontSize,
                              unselectedNumberFontSize,
                            );
                          },
                        ),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            if (widget.showDecimals) {
                              _currentValue = (widget.minValue + index) +
                                  (_decimalController.selectedItem / 10);
                            } else {
                              _currentValue = (widget.minValue + index).toDouble();
                            }
                            widget.onValueChanged(_currentValue);
                          });
                        },
                      ),
                    ),
                    if (widget.showDecimals) ...[
                      Text(
                        '.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: decimalPointFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: decimalPickerWidth,
                        child: ListWheelScrollView.useDelegate(
                          controller: _decimalController,
                          itemExtent: itemExtent,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 10,
                            builder: (context, index) {
                              return _buildNumberItem(
                                index.toString(),
                                index == (_currentValue - _currentValue.floor()) * 10,
                                selectedNumberFontSize,
                                unselectedNumberFontSize,
                              );
                            },
                          ),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _currentValue = _currentValue.floor() + (index / 10);
                              widget.onValueChanged(_currentValue);
                            });
                          },
                        ),
                      ),
                    ],
                    Padding(
                      padding: EdgeInsets.only(top: verticalPadding * 0.3),
                      child: Text(
                        widget.unit,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: unitFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(screenSize.width * 0.04),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, screenSize.height * 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenSize.width * 0.06),
                    ),
                  ),
                  child: Text(
                    'SAVE',
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberItem(
      String text,
      bool isSelected,
      double selectedSize,
      double unselectedSize,
      ) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white38,
          fontSize: isSelected ? selectedSize : unselectedSize,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
