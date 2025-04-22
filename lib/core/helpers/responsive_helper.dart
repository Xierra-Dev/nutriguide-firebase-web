import 'package:flutter/material.dart';
import '../constants/font_sizes.dart';

class ResponsiveHelper {
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  static double getAdaptiveTextSize(BuildContext context, double value) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = (screenWidth / FontSizes.baseWidth).clamp(
      FontSizes.minScale,
      FontSizes.maxScale
    );
    return value * scaleFactor;
  }

  static EdgeInsets getAdaptivePadding(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = screenWidth * 0.05;
    return EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16);
  }

  static double getAdaptiveDialogWidth(BuildContext context) {
    return screenWidth(context) * 0.9;
  }
}