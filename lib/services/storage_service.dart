import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class StorageService {
  final cloudinary = CloudinaryPublic(
    'dwbii43dk',  // Ganti dengan cloud name Anda
    'impalkeun',  // Ganti dengan unsigned upload preset
    cache: false,
  );

  Future<String> uploadProfilePicture(File imageFile, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniquePublicId = '${userId}_$timestamp';
      
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'profile_pictures',
          publicId: uniquePublicId,  // Gunakan publicId yang unik
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }
} 