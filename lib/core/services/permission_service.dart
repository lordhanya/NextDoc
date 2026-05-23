import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

final class PermissionService {
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;
    return false;
  }

  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;
    return await Permission.manageExternalStorage.isGranted;
  }
}
