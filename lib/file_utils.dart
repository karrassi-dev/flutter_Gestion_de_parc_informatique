import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

Future<void> requestStoragePermission(BuildContext context) async {
  if (Platform.isAndroid && await Permission.storage.isDenied) {
    final storageStatus = await Permission.storage.request();
    if (!storageStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission is required to save files.")),
      );
      return;
    }
  }

  if (Platform.isAndroid && 
      (Platform.operatingSystemVersion.contains("Android 11") ||
       Platform.operatingSystemVersion.contains("Android 12") ||
       Platform.operatingSystemVersion.contains("Android 13"))) {
    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Manage external storage permission is required.")),
      );
      return;
    }
  }

  // Android 14 and above: use app-specific storage only
}

Future<void> saveFileInAppDirectory(String fileName, List<int> fileBytes) async {
  final directory = await getExternalStorageDirectory();
  final path = '${directory?.path}/$fileName';
  final file = File(path);
  await file.writeAsBytes(fileBytes);
}
