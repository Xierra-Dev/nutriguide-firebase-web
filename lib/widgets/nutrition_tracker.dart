import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/nutrition_goals.dart';
import 'package:intl/intl.dart';

class NutritionTracker extends StatefulWidget {
  final NutritionGoals nutritionGoals;

  const NutritionTracker({
    super.key,
    required this.nutritionGoals,
  });

  @override
  _NutritionTrackerState createState() => _NutritionTrackerState();
}

class _NutritionTrackerState extends State<NutritionTracker> {
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = true;
  Map<String, double> todayNutrition = {
    'calories': 0,
    'carbs': 0,
    'fiber': 0,
    'protein': 0,
    'fat': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadTodayNutrition();
  }

  Future<void> _loadTodayNutrition() async {
    setState(() => isLoading = true);
    try {
      final data = await _firestoreService.getTodayNutrition();
      setState(() {
        todayNutrition = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading nutrition: $e');
      setState(() => isLoading = false);
    }
  }

  Widget _buildNutrientProgress(String label, String nutrient, Color color) {
    final current = todayNutrition[nutrient] ?? 0;
    final goal = switch (nutrient) {
      'calories' => widget.nutritionGoals.calories,
      'carbs' => widget.nutritionGoals.carbs,
      'fiber' => widget.nutritionGoals.fiber,
      'protein' => widget.nutritionGoals.protein,
      'fat' => widget.nutritionGoals.fat,
      _ => 0.0,
    };

    final progress = (current / goal).clamp(0.0, 1.0);
    final unit = nutrient == 'calories' ? 'kcal' : 'g';
    final isExceeded = current > goal;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                if (isExceeded)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.warning_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                Text(
                  '${current.toStringAsFixed(1)}/$goal$unit',
                  style: TextStyle(
                    color: isExceeded ? Colors.red : Colors.grey[400],
                    fontSize: 14,
                    fontWeight:
                        isExceeded ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Progress bar
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isExceeded ? Colors.red : color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: (isExceeded ? Colors.red : color).withOpacity(0.5),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            // Exceeded indicator
            if (isExceeded)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.red,
                      width: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (isExceeded)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Exceeded by ${(current - goal).toStringAsFixed(1)}$unit',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    bool hasExceededLimits = false;
    if (!isLoading) {
      hasExceededLimits = (todayNutrition['calories'] ?? 0) >
              widget.nutritionGoals.calories ||
          (todayNutrition['carbs'] ?? 0) > widget.nutritionGoals.carbs ||
          (todayNutrition['fiber'] ?? 0) > widget.nutritionGoals.fiber ||
          (todayNutrition['protein'] ?? 0) > widget.nutritionGoals.protein ||
          (todayNutrition['fat'] ?? 0) > widget.nutritionGoals.fat;
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine whether the layout is compact or wide
          bool isCompact = constraints.maxWidth < 600;
          double padding = isCompact ? 16 : 32;

          return Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: hasExceededLimits
                  ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: hasExceededLimits
                      ? Colors.red.withOpacity(0.2)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        "Today's Nutrition",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        if (hasExceededLimits)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_rounded,
                                      color: Colors.red, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Limit Exceeded',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: isCompact ? 10 : 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.white),
                          onPressed: _loadTodayNutrition,
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  DateFormat('EEEE, MMMM dd').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: isCompact ? 12 : 14,
                  ),
                ),
                const SizedBox(height: 24),
                if (isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepOrange,
                    ),
                  )
                else
                  Column(
                    children: [
                      _buildNutrientProgress(
                          'Calories', 'calories', Colors.blue),
                      const SizedBox(height: 16),
                      _buildNutrientProgress('Carbs', 'carbs', Colors.orange),
                      const SizedBox(height: 16),
                      _buildNutrientProgress('Fiber', 'fiber', Colors.green),
                      const SizedBox(height: 16),
                      _buildNutrientProgress('Protein', 'protein', Colors.pink),
                      const SizedBox(height: 16),
                      _buildNutrientProgress('Fat', 'fat', Colors.purple),
                    ],
                  ),
                if (hasExceededLimits)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You have exceeded your daily nutrition limits. Consider adjusting your meal plan.',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: isCompact ? 11 : 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
