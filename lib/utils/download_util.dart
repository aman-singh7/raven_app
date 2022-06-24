import 'dart:io';

import 'package:cheap_share/utils/request_permission_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadUtil {
  static Future download({
    required List<int> bytes,
    String? name,
  }) async {
    try {
      if (await RequestPermissionUtils.requestPermission(
          Permission.storage)){
        var path = await FilePicker.platform.getDirectoryPath();
        path ??= (await getTemporaryDirectory()).path;
        debugPrint('Path: $path');
        final file = await File('$path/$name').writeAsBytes(bytes);

        await OpenFile.open(file.path);
      }
    } catch (err) {
      debugPrint('Error occured while parsing file. ${err.toString()}');
    }
  }
}


