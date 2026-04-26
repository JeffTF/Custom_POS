import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
    final dir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(dir.path, 'product_images'));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = p.join(imageDir.path, fileName);
    await File(sourcePath).copy(savedPath);
    return savedPath;
  }

 
  static Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
