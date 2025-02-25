import 'package:flutter/material.dart';

class CustomActivityLevelPicker extends StatefulWidget {
  final String? initialValue;

  const CustomActivityLevelPicker({
    super.key,
    this.initialValue,
  });

  @override
  _CustomActivityLevelPickerState createState() => _CustomActivityLevelPickerState();
}

class _CustomActivityLevelPickerState extends State<CustomActivityLevelPicker> {
  late String _selectedActivityLevel;

  final List<String> _activityLevels = [
    'Not active',
    'Lightly active',
    'Moderately active',
    'Very active',
    'Heavy active',
  ];

  @override
  void initState() {
    super.initState();
    _selectedActivityLevel = widget.initialValue ?? 'Not active';
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;

    // Calculate responsive sizes
    final double titleFontSize = screenSize.width * 0.06;
    final double optionFontSize = screenSize.width * 0.045;
    final double buttonFontSize = screenSize.width * 0.04;
    final double iconSize = screenSize.width * 0.06;
    final double verticalPadding = screenSize.height * 0.015;
    final double horizontalPadding = screenSize.width * 0.05;

    return MediaQuery(
      // Prevent system font scaling
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Back Button
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                      left: horizontalPadding * 0.5,
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
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    children: [
                      Text(
                        'Select Your Activity Level',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      SizedBox(height: verticalPadding),
                      ..._activityLevels.map((level) =>
                          _buildActivityLevelOption(
                              level,
                              optionFontSize,
                              iconSize
                          )
                      ),
                      const Spacer(),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: verticalPadding * 0.5,
                          left: horizontalPadding * 0.4,
                          right: horizontalPadding * 0.4,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(_selectedActivityLevel);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  vertical: verticalPadding * 0.8
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityLevelOption(
      String level,
      double fontSize,
      double iconSize
      ) {
    return Container(
      margin: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.01
      ),
      decoration: BoxDecoration(
        color: _selectedActivityLevel == level
            ? Colors.deepOrange.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          level,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
          ),
        ),
        trailing: Icon(
          _selectedActivityLevel == level
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: _selectedActivityLevel == level
              ? Colors.deepOrange
              : Colors.white70,
          size: iconSize,
        ),
        onTap: () {
          setState(() {
            _selectedActivityLevel = level;
          });
        },
      ),
    );
  }
}
