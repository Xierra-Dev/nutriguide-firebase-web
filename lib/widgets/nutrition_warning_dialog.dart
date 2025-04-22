import 'package:flutter/material.dart';

class NutritionWarningDialog extends StatelessWidget {
  final Map<String, double> nutritionPercentages;
  final VoidCallback onProceed;

  const NutritionWarningDialog({
    super.key,
    required this.nutritionPercentages,
    required this.onProceed,
  });

  Widget _buildNutrientWarning(String nutrient, double percentage) {
    final isHighRisk = percentage >= 100;
    final isWarning = percentage >= 80;

    Color getColor() {
      if (isHighRisk) return Colors.red;
      if (isWarning) return Colors.orange;
      return Colors.green;
    }

    String getMessage() {
      if (isHighRisk) return 'Exceeded';
      if (isWarning) return 'Near limit';
      return 'Safe';
    }

    String getNutrientLabel() {
      switch (nutrient) {
        case 'calories':
          return 'Calories';
        case 'carbs':
          return 'Carbohydrates';
        case 'fiber':
          return 'Fiber';
        case 'protein':
          return 'Protein';
        case 'fat':
          return 'Fat';
        default:
          return nutrient;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: getColor().withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            getNutrientLabel(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: getColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: getColor()),
                ),
                child: Text(
                  getMessage(),
                  style: TextStyle(
                    color: getColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasExceeded = nutritionPercentages.values.any((value) => value >= 100);

    return MediaQuery.withNoTextScaling(
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasExceeded
                  ? Colors.red.withOpacity(0.5)
                  : Colors.orange.withOpacity(0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (hasExceeded ? Colors.red : Colors.orange)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasExceeded ? Icons.error : Icons.warning,
                      color: hasExceeded ? Colors.red : Colors.orange,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hasExceeded
                            ? 'Nutrition Limit Exceeded'
                            : 'Nutrition Warning',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasExceeded
                          ? 'Adding this recipe will exceed your daily nutrition limits:'
                          : 'Adding this recipe will bring you close to your daily limits:',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 16),
                    ...nutritionPercentages.entries
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildNutrientWarning(e.key, e.value),
                            ))
                        ,
                    SizedBox(height: 16),
                    Text(
                      'Are you sure you want to proceed?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            hasExceeded ? Colors.red : Colors.orange,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Proceed Anyway',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
