import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/firestore_service.dart';
import 'models/recipe.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EditRecipePage extends StatefulWidget {
  final Recipe recipe;
  
  const EditRecipePage({super.key, required this.recipe});

  @override
  _EditRecipePageState createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late List<TextEditingController> _ingredientControllers;
  late List<TextEditingController> _instructionControllers;
  late TextEditingController _prepTimeController;
  File? recipeImage;
  String? currentImageUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _prepTimeController = TextEditingController(text: widget.recipe.preparationTime.toString());
    currentImageUrl = widget.recipe.image;
    
    // Initialize ingredient controllers
    _ingredientControllers = widget.recipe.ingredients.map((ingredient) {
      return TextEditingController(text: ingredient);
    }).toList();
    
    // Initialize instruction controllers
    _instructionControllers = widget.recipe.instructionSteps.map((step) {
      return TextEditingController(text: step);
    }).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _prepTimeController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _instructionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          recipeImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _addIngredient() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientControllers[index].dispose();
      _ingredientControllers.removeAt(index);
    });
  }

  void _addInstruction() {
    setState(() {
      _instructionControllers.add(TextEditingController());
    });
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructionControllers[index].dispose();
      _instructionControllers.removeAt(index);
    });
  }

  Future<Map<String, dynamic>> _uploadToCloudinary(File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dwbii43dk/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'impalkeun'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      
      if (response.statusCode == 200) {
        return json.decode(responseString);
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }

  Future<void> _updateRecipe() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        String imageUrl = currentImageUrl!;
        if (recipeImage != null) {
          final cloudinaryResponse = await _uploadToCloudinary(recipeImage!);
          imageUrl = cloudinaryResponse['secure_url'];
        }

        final updatedRecipe = Recipe(
          id: widget.recipe.id,
          title: _titleController.text,
          image: imageUrl,
          category: widget.recipe.category,
          area: widget.recipe.area,
          instructions: _instructionControllers.map((c) => c.text).join('\n'),
          ingredients: _ingredientControllers.map((c) => c.text).where((text) => text.isNotEmpty).toList(),
          measurements: _ingredientControllers.map((_) => '1 portion').toList(),
          preparationTime: int.parse(_prepTimeController.text),
          healthScore: widget.recipe.healthScore,
          instructionSteps: _instructionControllers.map((c) => c.text).where((text) => text.isNotEmpty).toList(),
          nutritionInfo: widget.recipe.nutritionInfo,
        );

        await _firestoreService.updateUserRecipe(updatedRecipe);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe updated successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error updating recipe: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating recipe: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Recipe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  image: recipeImage != null
                      ? DecorationImage(
                          image: FileImage(recipeImage!),
                          fit: BoxFit.cover,
                        )
                      : currentImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(currentImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: recipeImage == null && currentImageUrl == null
                    ? const Icon(Icons.add_photo_alternate, size: 50, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Recipe Title',
                labelStyle: const TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _prepTimeController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Preparation Time (minutes)',
                labelStyle: const TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter preparation time';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Ingredients',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredientControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ingredientControllers[index],
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter ingredient',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeIngredient(index),
                      ),
                    ],
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add),
              label: const Text('Add Ingredient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Instructions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _instructionControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _instructionControllers[index],
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Enter instruction step',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeInstruction(index),
                      ),
                    ],
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              onPressed: _addInstruction,
              icon: const Icon(Icons.add),
              label: const Text('Add Instruction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: isLoading ? null : _updateRecipe,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16),
                ),
        ),
      ),
    );
  }
} 