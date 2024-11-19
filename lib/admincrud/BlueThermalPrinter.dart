import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class MockBluetoothPrinter {
  Future<bool?> isOn() async {
    return true; // Simulate that Bluetooth is on
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    return []; // Simulate no devices found
  }

  Future<void> connect(BluetoothDevice device) async {
    // Simulate successful connection
  }

  Future<void> disconnect() async {
    // Simulate successful disconnection
  }

  Future<void> printCustom(String text, int size, int alignment) async {
    print("Print Custom: $text"); // Output to console
  }

  Future<void> printQRcode(String data, double width, double height, int module) async {
    print("Print QR Code with data: $data"); // Output to console
  }

  Future<bool?> get isConnected async => true; // Simulate connection status
}
