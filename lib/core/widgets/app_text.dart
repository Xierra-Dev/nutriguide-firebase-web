// lib/core/widgets/app_text.dart
import 'package:flutter/material.dart';
import '../helpers/responsive_helper.dart';

class AppText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontStyle? fontStyle; // Add this parameter

  const AppText(
      this.text, {
        super.key,
        required this.fontSize,
        this.color,
        this.fontWeight,
        this.textAlign,
        this.maxLines,
        this.overflow,
        this.fontStyle, // Add this parameter
      });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: ResponsiveHelper.getAdaptiveTextSize(context, fontSize),
          color: color,
          fontWeight: fontWeight,
          fontStyle: fontStyle, // Add this parameter
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}