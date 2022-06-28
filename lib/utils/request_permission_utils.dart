import 'package:permission_handler/permission_handler.dart';

class RequestPermissionUtils {
  static Future<void> requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      print('true, permission granted');
    }
    final result = await permission.request();
    if (result == PermissionStatus.granted) {
      print('true, permission granted');
    }
    print('false, permission not granted');
  }
}