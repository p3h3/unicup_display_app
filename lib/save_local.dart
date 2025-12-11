import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
    try {
      status = await Permission.storage.request();
    } catch (e) {
      // Another request is already running – ignore or just log it
      debugPrint('Storage permission request already in progress: $e');

      // Optionally, just re-check the status instead of crashing
      status = await Permission.storage.status;
    }
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
    String json, String fileName) async {
  final hasPermission = await ensureStoragePermission();
  if (!hasPermission) {
    Fluttertoast.showToast(
          msg: "No File Permission!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 5,
          backgroundColor: Colors.white,
          textColor: Colors.red,
          fontSize: 20.0,
        );
    return null;
  }

  final dir = await getDownloadsDirectory();
  if (dir == null){

    Fluttertoast.showToast(
          msg: "No Download Dir!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 5,
          backgroundColor: Colors.white,
          textColor: Colors.red,
          fontSize: 20.0,
        );

    return null;
  } 
  print(dir);

  final file = File(p.join(dir.path, fileName));
  return file.writeAsString(json, flush: true);
}






Future<List<String>> listDownloadFiles() async {
  final hasPermission = await ensureStoragePermission();
  if (!hasPermission) return [];

  final dir = await getDownloadsDirectory();
  if (dir == null) return [];

  final downloadsDir = Directory(dir.path);

  if (!await downloadsDir.exists()) return [];

  final entities = downloadsDir.listSync();

  // return only file names, filter out subdirectories
  return entities
      .whereType<File>()
      .map((file) => p.basename(file.path))
      .toList();
}

Future<List<String>> listDownloadFilesByExtension(String extension) async {
  final files = await listDownloadFiles();
  return files.where((f) => f.toLowerCase().endsWith(extension.toLowerCase())).toList();
}






Future<Map<String, dynamic>?> getJsonFromDownloads(String fileName) async {
  final hasPermission = await ensureStoragePermission();
  if (!hasPermission) {
    Fluttertoast.showToast(
      msg: "No File Permission!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 5,
      backgroundColor: Colors.white,
      textColor: Colors.red,
      fontSize: 20.0,
    );
    return null;
  }

  final dir = await getDownloadsDirectory();
  if (dir == null) {
    Fluttertoast.showToast(
      msg: "No Download Dir!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 5,
      backgroundColor: Colors.white,
      textColor: Colors.red,
      fontSize: 20.0,
    );
    return null;
  }

  final file = File(p.join(dir.path, fileName));

  if (!await file.exists()) {
    Fluttertoast.showToast(
      msg: "File does not exist!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 5,
      backgroundColor: Colors.white,
      textColor: Colors.red,
      fontSize: 20.0,
    );
    return null;
  }

  try {
    final content = await file.readAsString();
    final decoded = json.decode(content);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    } else {
      Fluttertoast.showToast(
        msg: "JSON is not an object!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 5,
        backgroundColor: Colors.white,
        textColor: Colors.red,
        fontSize: 20.0,
      );
      return null;
    }
  } catch (e) {
    Fluttertoast.showToast(
      msg: "Invalid JSON file!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 5,
      backgroundColor: Colors.white,
      textColor: Colors.red,
      fontSize: 20.0,
    );
    return null;
  }
}
