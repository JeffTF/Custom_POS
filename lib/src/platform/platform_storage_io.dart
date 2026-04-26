import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> saveImageToAppStorage(String sourcePath) async {
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

Future<void> deleteStoredFile(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

Future<String> writeCsvToAppStorage(String fileName, String contents) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, fileName));
  await file.writeAsString(contents);
  return file.path;
}
