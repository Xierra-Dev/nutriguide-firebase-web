import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'services/firestore_service.dart';
import 'package:intl/intl.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailPage({super.key, required this.recipe});

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  bool isSaved = false;
  bool isPlanned = false;
  bool isLoadingSave = false;
  bool isLoadingPlan = false;
  bool showTitle = false;
  bool _isScrolledToThreshold = false;
  bool _isTemporarilyPlanned = false;

  DateTime _selectedDate = DateTime.now();
  String _selectedMeal = 'Dinner';
  List<bool> _daysSelected = List.generate(7, (index) => false);

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _addToRecentlyViewed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Color _getHealthScoreColor(double? healthScore) {
    if (healthScore == null) return Colors.grey;

    if (healthScore < 6) {
      return Colors.red;
    } else if (healthScore <= 7.5) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }
  
  void _onScroll() {
    // You can adjust this value (100) to control when the title appears
    if (_scrollController.offset > 100 && !showTitle) {
      setState(() {
        showTitle = true;
      });
    } else if (_scrollController.offset <= 100 && showTitle) {
      setState(() {
        showTitle = false;
      });
    }
  }

  Future<void> _checkIfSaved() async {
    final saved = await _firestoreService.isRecipeSaved(widget.recipe.id);
    setState(() {
      isSaved = saved;
    });
  }

  Future<void> _addToRecentlyViewed() async {
    try {
      await _firestoreService.addToRecentlyViewed(widget.recipe);
    } catch (e) {
      print('Error adding to recently viewed: $e');
    }
  }

  Future<void> _toggleSave(Recipe recipe) async {
    setState(() {
      isLoadingSave = true;
    });
    try {
      if (isSaved) {
        await _firestoreService.unsaveRecipe(widget.recipe.id);
      } else {
        await _firestoreService.saveRecipe(widget.recipe);
      }
      setState(() {
        isSaved = !isSaved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSaved ? Icons.bookmark_added_rounded : Icons.delete,
                color: isSaved ? Colors.white : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSaved ? 'Recipe saved: ${recipe.title}' : 'Recipe: "${recipe.title}" removed from saved',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(
                Icons.error,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text('Error saving recipe'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoadingSave = false;
      });
    }
  }

  Future<void> _togglePlan(Recipe recipe) async {
    try {
      // Show the planning dialog without changing the planned status yet
      _showPlannedDialog(recipe);
    } catch (e) {
      // Handle error and show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Error planning recipe: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMealSelectionDialog(BuildContext context, StateSetter setDialogState, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter mealSetState) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 20
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Meal Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ListView(
                      shrinkWrap: true,
                      children: ['Breakfast', 'Lunch', 'Dinner', 'Supper', 'Snacks'].map((String mealType) {
                        return ListTile(
                          title: Text(
                            mealType,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          onTap: () {
                            setDialogState(() {
                              _selectedMeal = mealType;
                            });
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            _showPlannedDialog(recipe);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showPlannedDialog(Recipe recipe) {
    // Reset selected days
    _daysSelected = List.generate(7, (index) => false);

    // Get the start of week (Sunday)
    DateTime now = DateTime.now();
    _selectedDate = now.subtract(Duration(days: now.weekday % 7));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900], // Background untuk dark mode
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header dengan navigasi antar minggu
                    const Text(
                      'Choose Day',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            // Pindah ke minggu sebelumnya
                            setDialogState(() {
                              _selectedDate =
                                  _selectedDate.subtract(const Duration(days: 7));
                            });
                          },
                          icon: const Icon(
                            Icons.arrow_left_rounded,
                            size: 40,
                          ),
                          color: Colors.white,
                        ),
                        Text(
                          // Menampilkan rentang tanggal minggu
                          '${DateFormat('MMM dd').format(_selectedDate)} - '
                              '${DateFormat('MMM dd').format(_selectedDate.add(const Duration(days: 6)))}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Pindah ke minggu berikutnya
                            setDialogState(() {
                              _selectedDate =
                                  _selectedDate.add(const Duration(days: 7));
                            });
                          },
                          icon: const Icon(
                            Icons.arrow_right_rounded,
                            size: 40,
                          ),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 60,
                      child: Center(
                        child: InkWell(
                          onTap: () {
                            // Open meal selection dialog
                            _showMealSelectionDialog(context, setDialogState, recipe);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedMeal.isEmpty ? 'Select Meal' : _selectedMeal,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Pilihan hari menggunakan ChoiceChip (dimulai dari Sunday)
                    Wrap(
                      spacing: 8,
                      children: [
                        for (int i = 0; i < 7; i++)
                          ChoiceChip(
                            label: Text(
                              DateFormat('EEE').format(
                                _selectedDate.add(Duration(
                                    days: i - _selectedDate.weekday % 7)),
                              ), // Menampilkan hari dimulai dari Sunday
                            ),
                            selected: _daysSelected[i],
                            onSelected: (bool selected) {
                              setDialogState(() {
                                _daysSelected[i] = selected;
                              });
                            },
                            selectedColor: Colors.blue,
                            backgroundColor: Colors.grey[800],
                            labelStyle: TextStyle(
                              color:
                              _daysSelected[i] ? Colors.white : Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tombol aksi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        ElevatedButton(
                          // Inside dialog's ElevatedButton onPressed
                          onPressed: () {
                            if (_selectedMeal.isEmpty || !_daysSelected.contains(true)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select at least one day and a meal type!')),
                              );
                              return;
                            }
                            _saveSelectedPlan(recipe); // Pass the recipe
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white
                          ),
                          child: const Text('Done', style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ) ,),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

// Fungsi untuk menyimpan pilihan (sesuaikan dengan logika aplikasi Anda)
  void _saveSelectedPlan(Recipe recipe) async {
    try {
      List<DateTime> selectedDates = [];
      List<DateTime> successfullyPlannedDates = []; // Menyimpan tanggal yang berhasil disimpan

      for (int i = 0; i < _daysSelected.length; i++) {
        if (_daysSelected[i]) {
          DateTime selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day + i,
          );
          selectedDates.add(selectedDate);
        }
      }

      for (DateTime date in selectedDates) {
        bool exists = await _firestoreService.checkIfPlanExists(
          recipe.id,
          _selectedMeal,
          date,
        );

        if (exists) {
          print('Duplicate plan detected for date: $date');
          continue; // Lewati tanggal yang sudah direncanakan
        }

        print('Saving recipe for date: $date');
        await _firestoreService.addPlannedRecipe(
          recipe,
          _selectedMeal,
          date,
        );

        successfullyPlannedDates.add(date); // Tambahkan tanggal yang berhasil direncanakan
      }

      if (mounted) {
        setState(() {
          isPlanned = true;
          _isTemporarilyPlanned = false;
        });

        if (successfullyPlannedDates.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.add_task_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Recipe planned for ${successfullyPlannedDates.length} day(s)'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 8),
                  Text('No new plans were added. All selected plans already exist.', style: TextStyle(fontSize: 13.25),),
                ],
              ),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Failed to save plan: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Force text scale factor to 1.0 to prevent system font size affecting the UI
    final mediaQueryData = MediaQuery.of(context);
    final standardScaleFactor = MediaQuery(
      data: mediaQueryData.copyWith(textScaleFactor: 1.0),
      child: Container(),
    );

    double appBarHeight = MediaQuery.of(context).size.height * 0.375;
    double threshold = appBarHeight * 0.75;

    return MediaQuery(
      data: mediaQueryData.copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            setState(() {
              _isScrolledToThreshold = scrollInfo.metrics.pixels >= threshold;
            });
            return true;
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.black,
                surfaceTintColor: Colors.transparent,
                expandedHeight: appBarHeight,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    _isScrolledToThreshold
                        ? (widget.recipe.title.length > 15
                        ? '${widget.recipe.title.substring(0, 15)}...'
                        : widget.recipe.title)
                        : widget.recipe.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.recipe.image,
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.45),
                                Colors.transparent,
                                Colors.black.withOpacity(0.45),
                              ],
                              stops: const [0.0, 0.35, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () async {
                    await _firestoreService.addToRecentlyViewed(widget.recipe);
                    Navigator.pop(context);
                  },
                ),
                actions: [
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        padding: const EdgeInsets.only(bottom: 2),
                        child: IconButton(
                          icon: const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: isLoadingPlan ? null : () => _togglePlan(widget.recipe),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 5, right: 10),
                        child: IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved ? Colors.deepOrange : Colors.white,
                            size: 22.5,
                          ),
                          onPressed: isLoadingSave ? null : () => _toggleSave(widget.recipe),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildInfoSection(),
                      const SizedBox(height: 24),
                      _buildIngredientsList(),
                      const SizedBox(height: 24),
                      _buildInstructions(),
                      const SizedBox(height: 24),
                      _buildHealthScore(),
                      const SizedBox(height: 24),
                      _buildNutritionInfo(widget.recipe.nutritionInfo),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: MediaQuery(
          data: mediaQueryData.copyWith(textScaleFactor: 1.0),
          child: Container(
            padding: const EdgeInsets.only(
              top: 18,
              bottom: 15,
              right: 18,
              left: 18,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoadingSave ? null : () => _toggleSave(widget.recipe),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSaved ? Colors.deepOrange : Colors.white,
                      foregroundColor: isSaved ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: isLoadingSave
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                      ),
                    )
                        : Text(
                      isSaved ? 'Saved' : 'Save',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _togglePlan(widget.recipe),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: isLoadingPlan
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                      ),
                    )
                        : const Text(
                      'Plan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoButton(
            'Time',
            '${widget.recipe.preparationTime} min',
            Icons.timer,
          ),
          _buildInfoButton(
            'Servings',
            '4',
            Icons.people,
          ),
          _buildInfoButton(
            'Calories',
            '${widget.recipe.nutritionInfo.calories}',
            Icons.local_fire_department,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoButton(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsList() {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Column(
        children: [
          const Text(
            'Ingredients',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.recipe.ingredients.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record, color: Colors.deepOrange, size: 8),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.recipe.measurements[index]} ${widget.recipe.ingredients[index]}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Column(
        children: [
          const Text(
            'Instructions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.recipe.instructionSteps.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ',
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.recipe.instructionSteps[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore() {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Score',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: widget.recipe.healthScore / 10,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(_getHealthScoreColor(widget.recipe.healthScore)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.recipe.healthScore.toStringAsFixed(1)} / 10',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionInfo(NutritionInfo nutritionInfo) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Column(
        children: [
          const Text(
            'Nutrition Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildNutritionRow('Calories', '${nutritionInfo.calories} kcal'),
          _buildNutritionRow('Total Fat', '${nutritionInfo.totalFat.toStringAsFixed(1)}g'),
          _buildNutritionRow('Saturated Fat', '${nutritionInfo.saturatedFat.toStringAsFixed(1)}g'),
          _buildNutritionRow('Carbs', '${nutritionInfo.carbs.toStringAsFixed(1)}g'),
          _buildNutritionRow('Sugars', '${nutritionInfo.sugars.toStringAsFixed(1)}g'),
          _buildNutritionRow('Protein', '${nutritionInfo.protein.toStringAsFixed(1)}g'),
          _buildNutritionRow('Sodium', '${nutritionInfo.sodium}mg'),
          _buildNutritionRow('Fiber', '${nutritionInfo.fiber.toStringAsFixed(1)}g'),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}