import 'dart:io';

import 'package:flutter/painting.dart';

ImageProvider<Object>? imageProviderForPath(String? path) {
  if (path == null || path.isEmpty) {
    return null;
  }
  if (!File(path).existsSync()) {
    return null;
  }
  return FileImage(File(path));
}
