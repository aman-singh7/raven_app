import 'package:permission_handler/permission_handler.dart';

class RequestPermissionUtils {
  static Future<bool> requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    }
    final result = await permission.request();
    if (result == PermissionStatus.granted) {
      return true;
    }
    return false;
  }
}