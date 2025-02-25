import 'package:flutter/material.dart';

class MealTime {
  final TimeOfDay start;
  final TimeOfDay end;

  const MealTime({required this.start, required this.end});
}

class MealTimes {
  static const Map<String, MealTime> ranges = {
    'Breakfast': MealTime(
      start: TimeOfDay(hour: 6, minute: 0),
      end: TimeOfDay(hour: 9, minute: 0),
    ),
    'Lunch': MealTime(
      start: TimeOfDay(hour: 12, minute: 0),
      end: TimeOfDay(hour: 14, minute: 0),
    ),
    'Dinner': MealTime(
      start: TimeOfDay(hour: 18, minute: 0),
      end: TimeOfDay(hour: 20, minute: 0),
    ),
    'Supper': MealTime(
      start: TimeOfDay(hour: 20, minute: 0),
      end: TimeOfDay(hour: 22, minute: 0),
    ),
  };
} 