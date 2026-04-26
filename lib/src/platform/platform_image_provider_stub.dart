import 'package:flutter/painting.dart';

ImageProvider<Object>? imageProviderForPath(String? path) {
  if (path == null || path.isEmpty) {
    return null;
  }
  return NetworkImage(path);
}
