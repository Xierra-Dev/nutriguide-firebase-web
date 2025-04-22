import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'profile_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/widgets/app_text.dart';
import 'dart:io';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  File? _imageFile;
  String? _currentProfilePictureUrl;
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _profilePictureDeleted = false; // New flag to track if profile picture was deleted

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Add listeners to track changes
    _firstNameController.addListener(_checkChanges);
    _lastNameController.addListener(_checkChanges);
    _usernameController.addListener(_checkChanges);
    _bioController.addListener(_checkChanges);
  }

  void _checkChanges() {
    setState(() {
      _hasChanges =
          _firstNameController.text != (_currentUserData?['firstName'] ?? '') ||
              _lastNameController.text != (_currentUserData?['lastName'] ?? '') ||
              _usernameController.text != (_currentUserData?['username'] ?? '') ||
              _bioController.text != (_currentUserData?['bio'] ?? '') ||
              _imageFile != null ||
              _profilePictureDeleted;
    });
  }

  Map<String, dynamic>? _currentUserData;

  Future<void> _loadUserData() async {
    try {
      final userData = await _firestoreService.getUserPersonalization();
      if (userData != null) {
        setState(() {
          _currentUserData = userData;
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _usernameController.text = userData['username'] ?? '';
          _bioController.text = userData['bio'] ?? '';
          _currentProfilePictureUrl = userData['profilePictureUrl'];
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load user data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.0,
          child: Container(
            padding: EdgeInsets.all(Dimensions.paddingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 40,
                  margin: EdgeInsets.only(bottom: Dimensions.paddingM),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(Dimensions.radiusS),
                  ),
                ),
                // Delete option centered
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _deleteProfilePicture();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: Dimensions.paddingM,
                      horizontal: Dimensions.paddingL,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, color: Colors.red[800], size: 24,),
                        SizedBox(width: Dimensions.paddingM),
                        Text(
                          'Delete Photo Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.paddingS),
                // Change image option centered
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: Dimensions.paddingM,
                      horizontal: Dimensions.paddingL,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, color: Colors.grey),
                        SizedBox(width: Dimensions.paddingM),
                        Text(
                          'Change Image Photo Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteProfilePicture() async {
    setState(() {
      _imageFile = null;
      _profilePictureDeleted = true; // Set flag to true
      _hasChanges = true;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 100,
      );
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _profilePictureDeleted = false; // Reset delete flag when picking a new image
          _hasChanges = true;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check username uniqueness only if username is not empty and changed
      if (_usernameController.text.isNotEmpty &&
          _usernameController.text != _currentUserData?['username']) {
        bool isUsernameAvailable = await _authService.checkUsernameUniqueness(
            _usernameController.text
        );

        if (!isUsernameAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Username is already taken. Please choose another.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Sanitize and format names
      String firstName = _firstNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      // Username can be empty now
      String username = _usernameController.text.trim();

      // Prepare update data
      Map<String, dynamic> updateData = {
        'firstName': firstName,
        'lastName': lastName,
        'username': username, // Can be empty string now
        'bio': _bioController.text.trim(),
        'displayName': '$firstName ${lastName ?? ''}',
      };

      // If profile picture was deleted, explicitly set it to null in the update data
      if (_profilePictureDeleted) {
        updateData['profilePictureUrl'] = null;
        // Delete the image from storage if it exists
        if (_currentProfilePictureUrl != null) {
          await _firestoreService.deleteProfilePicture();
        }
      }

      // If there's a new profile picture, upload it
      if (_imageFile != null) {
        await _firestoreService.uploadProfilePicture(_imageFile!);
      }

      // Update profile data in Firestore
      await _firestoreService.updateUserProfile(updateData);

      // Update display name in Firebase Auth
      await _authService.updateDisplayName(
          '$firstName ${lastName ?? ''}'.trim()
      );

      // Navigate back to profile page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      // Jika ada perubahan, tampilkan dialog konfirmasi
      bool? shouldExit = await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Dismiss",
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return MediaQuery.withClampedTextScaling(
            minScaleFactor: 1.0,
            maxScaleFactor: 1.0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9, // Lebar 90% dari layar
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E), // Warna latar belakang gelap
                    borderRadius: BorderRadius.circular(28), // Sudut yang lebih bulat
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            'Leave This Page',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 21.5),
                      Text(
                        'Your Profile Changes won\'t be saved',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 37),
                      // Tombol disusun secara vertikal
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Leave Page',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      return shouldExit ?? false; // Pastikan selalu mengembalikan bool
    } else {
      // Jika tidak ada perubahan, langsung keluar
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.0,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.text),
              onPressed: () async {
                if (await _onWillPop()) {
                  Navigator.pop(context);
                }
              },
            ),
            title: AppText(
              'Edit Profile',
              fontSize: FontSizes.heading3,
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(Dimensions.paddingM),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                        ),
                        child: ClipOval(
                          child: _imageFile != null
                              ? Image.file(_imageFile!, fit: BoxFit.cover)
                              : (_currentProfilePictureUrl != null && !_profilePictureDeleted)
                              ? Image.network(
                            _currentProfilePictureUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: Dimensions.iconXL,
                                color: AppColors.text,
                              );
                            },
                          )
                              : Icon(
                            Icons.person,
                            size: Dimensions.iconXL,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: (_imageFile != null || (_currentProfilePictureUrl != null && !_profilePictureDeleted))
                            ? _showProfilePictureOptions
                            : _pickImage,
                        child: Container(
                          padding: EdgeInsets.all(Dimensions.paddingS),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: AppColors.text,
                            size: Dimensions.iconM,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Dimensions.paddingL),
                  _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    maxLength: 20,
                  ),
                  SizedBox(height: Dimensions.paddingM),
                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    maxLength: 20,
                  ),
                  SizedBox(height: Dimensions.paddingM),
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    maxLength: 15,
                    customValidator: (value) {
                      // Allow empty username (will pass validation)
                      if (value == null || value.isEmpty) {
                        return null;
                      }
                      // But if username has content, enforce length requirement
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters long';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: Dimensions.paddingM),
                  _buildTextField(
                    controller: _bioController,
                    label: 'Bio',
                    maxLines: 3,
                    maxLength: 200,
                  ),
                  SizedBox(height: Dimensions.paddingL),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_hasChanges) ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasChanges ? AppColors.primary : AppColors.surface,
                        padding: EdgeInsets.symmetric(vertical: Dimensions.paddingM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusL),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: AppColors.text)
                          : AppText(
                        'SAVE',
                        fontSize: FontSizes.body,
                        color: _hasChanges ? AppColors.text : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? customValidator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
          borderSide: BorderSide(color: AppColors.error),
        ),
        counterStyle: TextStyle(color: AppColors.textSecondary),
        errorStyle: TextStyle(color: AppColors.error),
      ),
      validator: customValidator ?? (value) {
        return null;
      },
      onChanged: (value) {
        _checkChanges();
      },
    );
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_checkChanges);
    _lastNameController.removeListener(_checkChanges);
    _usernameController.removeListener(_checkChanges);
    _bioController.removeListener(_checkChanges);

    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}