import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'recipe_detail_page.dart';
import 'services/firestore_service.dart';
import 'package:intl/intl.dart';

class AllRecipesPage extends StatefulWidget {
  final String title;
  final List<Recipe> recipes;

  const AllRecipesPage({super.key, required this.title, required this.recipes});

  @override
  _AllRecipesPageState createState() => _AllRecipesPageState();
}

class SlideLeftRoute extends PageRouteBuilder {
  final Widget page;

  SlideLeftRoute({required this.page})
      : super(
    pageBuilder: (
        BuildContext context,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
        ) =>
    page,
    transitionsBuilder: (
        BuildContext context,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
        Widget child,
        ) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.easeOutQuad,
        )),
        child: child,
      );
    },
  );
}

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
      : super(
    pageBuilder: (
        BuildContext context,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
        ) =>
    page,
    transitionsBuilder: (
        BuildContext context,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
        Widget child,
        ) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.easeOutQuad,
        )),
        child: child,
      );
    },
  );
}

class SlideUpRoute extends PageRouteBuilder {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
    pageBuilder: (
        BuildContext context,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
        ) =>
    page,
    transitionsBuilder: (
        BuildContext context,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
        Widget child,
        ) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),  // Start from bottom
          end: Offset.zero,  // End at the center
        ).animate(CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.easeOutQuad,
        )),
        child: child,
      );
    },
  );
}

class _AllRecipesPageState extends State<AllRecipesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool isSaved = false;
  bool isLoading = false;
  Map<String, bool> savedStatus = {};
  Map<String, bool> plannedStatus = {};

  DateTime _selectedDate = DateTime.now();
  String _selectedMeal = 'Dinner';
  List<bool> _daysSelected = List.generate(7, (index) => false);

  @override
  void initState() {
    super.initState();
    // Inisialisasi status untuk setiap resep
    for (var recipe in widget.recipes) {
      _checkIfSaved(recipe);
      _checkIfPlanned(recipe);
    }
  }

  Color _getHealthScoreColor(double healthScore) {
    if (healthScore < 6) {
      return Colors.red;
    } else if (healthScore <= 7.5) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  Future<void> _checkIfSaved(Recipe recipe) async {
    final saved = await _firestoreService.isRecipeSaved(recipe.id);
    setState(() {
      savedStatus[recipe.id] = saved;
    });
  }

  Future<void> _checkIfPlanned(Recipe recipe) async {
    final planned = await _firestoreService.isRecipePlanned(recipe.id);
    setState(() {
      plannedStatus[recipe.id] = planned;
    });
  }

  Future<void> _toggleSave(Recipe recipe) async {
    try {
      final bool currentStatus = savedStatus[recipe.id] ?? false;

      if (savedStatus[recipe.id] == true) {
        await _firestoreService.unsaveRecipe(recipe.id);
      } else {
        await _firestoreService.saveRecipe(recipe);
      }
      setState(() {
        savedStatus[recipe.id] = !currentStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                  savedStatus[recipe.id] == true
                      ? Icons.bookmark_added
                      : Icons.delete_rounded,
                  color: savedStatus[recipe.id] == true
                      ? Colors.white
                      : Colors.red
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  savedStatus[recipe.id] == true
                      ? 'Recipe: "${recipe.title}" saved'
                      : 'Recipe: "${recipe.title}" removed from saved',
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
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Error plan recipe: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
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

  void _saveSelectedPlan(Recipe recipe) async {
    try {
      List<DateTime> selectedDates = [];
      List<DateTime> successfullyPlannedDates = []; // Untuk menyimpan tanggal yang berhasil direncanakan

      for (int i = 0; i < _daysSelected.length; i++) {
        if (_daysSelected[i]) {
          // Normalize the date
          DateTime selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day + i,
          );
          print('Selected date: $selectedDate');
          selectedDates.add(selectedDate);
        }
      }

      for (DateTime date in selectedDates) {
        // Periksa apakah rencana dengan tanggal ini sudah ada
        bool exists = await _firestoreService.checkIfPlanExists(
          recipe.id,
          _selectedMeal,
          date,
        );

        if (exists) {
          print('Duplicate plan detected for date: $date');
          continue; // Lewati tanggal yang sudah direncanakan
        }

        // Simpan rencana baru
        print('Saving recipe for date: $date');
        await _firestoreService.addPlannedRecipe(
          recipe,
          _selectedMeal,
          date,
        );

        successfullyPlannedDates.add(date); // Tambahkan tanggal yang berhasil direncanakan
      }

      if (mounted) {
        if (successfullyPlannedDates.isNotEmpty) {
          // Tampilkan SnackBar untuk tanggal yang berhasil direncanakan
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
          // Tampilkan SnackBar jika semua tanggal adalah duplikat
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 8),
                  Text('No new plans were added. All selected plans already exist.', style: TextStyle(fontSize: 13),),
                ],
              ),
              backgroundColor: Colors.blue,
            ),
          );
        }

        // Perbarui status rencana di UI
        setState(() {
          plannedStatus[recipe.id] = true; // Tandai sebagai direncanakan
        });
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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: 1.0, // Mengunci skala teks menjadi 1.0
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(SlideRightRoute);
            },
          ),
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: widget.recipes.length,
          itemBuilder: (context, index) {
            final recipe = widget.recipes[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  SlideUpRoute(
                    page: RecipeDetailPage(recipe: recipe),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                  image: DecorationImage(
                    image: NetworkImage(recipe.image),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              recipe.area ?? 'International',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Container(
                            width: 32.5,
                            height: 32.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              iconSize: 24,
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                              ),
                              onSelected: (String value) {
                                if (value == 'Save Recipe') {
                                  _toggleSave(recipe);
                                } else if (value == 'Plan Meal') {
                                  _togglePlan(recipe);
                                }
                              },
                              color: Colors.grey[900],
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              offset: const Offset(0, 45),
                              constraints: const BoxConstraints(
                                minWidth: 175,
                                maxWidth: 175,
                              ),
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  height: 60,
                                  value: 'Save Recipe',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Icon(
                                          savedStatus[recipe.id] == true
                                              ? Icons.bookmark
                                              : Icons.bookmark_border_rounded,
                                          size: 22,
                                          color: savedStatus[recipe.id] == true
                                              ? Colors.deepOrange
                                              : Colors.white,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          savedStatus[recipe.id] == true
                                              ? 'Saved'
                                              : 'Save Recipe',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: savedStatus[recipe.id] == true
                                                ? Colors.deepOrange
                                                : Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  height: 60,
                                  value: 'Plan Meal',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Plan Meal',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          Text(
                            recipe.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timer,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${recipe.preparationTime} min',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    color: _getHealthScoreColor(recipe.healthScore),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    recipe.healthScore.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: _getHealthScoreColor(recipe.healthScore),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}