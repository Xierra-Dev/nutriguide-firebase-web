// lib/core/widgets/responsive_text_wrapper.dart
import 'package:flutter/material.dart';

class ResponsiveTextWrapper extends StatelessWidget {
  final Widget child;
  
  const ResponsiveTextWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0), // Using textScaler instead of textScaleFactor for newer Flutter versions
      ),
      child: child,
    );
  }
}