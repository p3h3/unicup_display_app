import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';


Future<File?> saveToDownloads(Uint8List data, String fileName) async {
  final hasPermission = await ensureStoragePermission();
  if (!hasPermission) {
    // You might want to show a dialog here
    return null;
  }

  final dir = await getDownloadsDirectory();
  if (dir == null) return null;

  final file = File(p.join(dir.path, fileName));
  return file.writeAsBytes(data, flush: true);
}


Future<bool> ensureStoragePermission() async {
  if (!Platform.isAndroid) return true;

  // Try normal storage permission first
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }

  if (status.isGranted) {
    return true;
  }

  // Optional: try MANAGE_EXTERNAL_STORAGE for Android 11+ if needed
  var manageStatus = await Permission.manageExternalStorage.status;
  if (!manageStatus.isGranted && manageStatus.isDenied) {
    manageStatus = await Permission.manageExternalStorage.request();
  }

  return manageStatus.isGranted;
}




Future<Directory?> getDownloadsDirectory() async {
  if (!Platform.isAndroid) return null;

  final dirs = await getExternalStorageDirectories(
    type: StorageDirectory.downloads,
  );

  if (dirs == null || dirs.isEmpty) return null;

  // Usually this is the public "Downloads" folder
  return dirs.first;
}




Future<File?> saveJsonToDownloads(
    Map<String, dynamic> json, String fileName) async {
  final hasPermission = await ensureStoragePermission();
  if (!hasPermission) return null;

  final dir = await getDownloadsDirectory();
  if (dir == null) return null;

  final file = File(p.join(dir.path, fileName));
  return file.writeAsString(jsonEncode(json), flush: true);
}

