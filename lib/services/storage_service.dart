import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageService {
  late final CloudinaryPublic cloudinary;

  StorageService() {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

    if (cloudName == null || uploadPreset == null) {
      throw Exception('Cloudinary credentials not found in environment variables');
    }

    cloudinary = CloudinaryPublic(
      cloudName,
      uploadPreset,
      cache: false,
    );
  }

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
      rethrow;
    }
  }
} 