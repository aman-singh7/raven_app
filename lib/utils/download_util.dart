import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DownloadUtil {
  static Future download({
    required List<int> bytes,
    String? name,
  }) async {
    try {
      final path = await getTemporaryDirectory();
      debugPrint('Path: $path');
      await File('$path/$name').writeAsBytes(bytes);
    } catch (err) {
      debugPrint('Error occured while parsing file. ${err.toString()}');
    }
  }
}
