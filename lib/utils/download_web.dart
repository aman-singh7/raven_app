import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:flutter/widgets.dart';

class DownloadUtil {
  static Future webDownload({
    required List<int> bytes,
    String? name,
  }) async {
    // Encode our file in base64
    final base64 = base64Encode(bytes);
    // Create the link with the file
    final anchor =
        AnchorElement(href: 'data:application/octet-stream;base64,$base64')
          ..target = 'blank';
    // add the name
    if (name != null) {
      anchor.download = name;
    }
    // trigger download
    debugPrint('body is: ${document.body != null}');
    document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  }
}
