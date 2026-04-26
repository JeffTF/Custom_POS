import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../platform/platform_storage.dart';

class ImageService {
  ImageService(this._picker);

  final ImagePicker _picker;

  Future<String?> pickAndSaveFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) {
      return null;
    }
    return saveImage(file.path);
  }

  Future<String?> pickAndSaveFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null) {
      return null;
    }
    return saveImage(file.path);
  }

  static Future<String> saveImage(String sourcePath) async {
    if (kIsWeb) {
      return sourcePath;
    }
    return saveImageToAppStorage(sourcePath);
  }

  static Future<void> deleteImage(String imagePath) async {
    await deleteStoredFile(imagePath);
  }
}
