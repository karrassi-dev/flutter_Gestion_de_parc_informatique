import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoUtil {
  Future<Map<String, String>> getDeviceDetails() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return {
        "deviceName": androidInfo.model,
        "serialNumber": androidInfo.id
      };
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return {
        "deviceName": iosInfo.name,
        "serialNumber": iosInfo.identifierForVendor ?? 'unknown',
      };
    } else {
      return {
        "deviceName": "Unknown",
        "serialNumber": "Unknown"
      };
    }
  }
}
