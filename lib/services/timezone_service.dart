import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimezoneService {
  static Future<void> initializeTimeZones() async {
    // Initialize the timezone database
    tz.initializeTimeZones();
    
    // Set local location to device's local timezone
    final String timeZoneName = DateTime.now().timeZoneName;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }
}