import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<void> ensureStoragePermission() async {
    await Permission.storage.request();
  }
}
