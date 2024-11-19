import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart'; // Add this for date formatting


class ViewEquipmentDetailsPage extends StatefulWidget {
  final QueryDocumentSnapshot equipment;

  const ViewEquipmentDetailsPage(this.equipment, {Key? key}) : super(key: key);

  @override
  _ViewEquipmentDetailsPageState createState() => _ViewEquipmentDetailsPageState();
}

class _ViewEquipmentDetailsPageState extends State<ViewEquipmentDetailsPage> {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _checkBluetooth();
    _getBluetoothDevices();
  }

  Future<void> _checkBluetooth() async {
    bool? isOn = await printer.isOn;
    if (isOn != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable Bluetooth to use the printer")),
      );
    }
  }

  Future<void> _getBluetoothDevices() async {
    bool? isConnected = await printer.isConnected;
    if (!isConnected!) {
      _devices = await printer.getBondedDevices();
      setState(() {});
    }
  }

  Future<void> _printEquipmentDetails() async {
    if (_selectedDevice == null) {
      await _selectBluetoothDevice();
    }
    if (_selectedDevice != null) {
      await printer.connect(_selectedDevice!);

      final Map<String, dynamic>? equipmentData = widget.equipment.data() as Map<String, dynamic>?;

      printer.printCustom("Equipment Details", 1, 1);
      printer.printNewLine();
      printer.printCustom("Name: ${equipmentData?['name'] ?? 'N/A'}", 0, 0);
      printer.printCustom("Email: ${equipmentData?['email'] ?? 'N/A'}", 0, 0);
      printer.printCustom("Type: ${equipmentData?['type'] ?? 'N/A'}", 0, 0);
      printer.printCustom("Brand: ${equipmentData?['brand'] ?? 'N/A'}", 0, 0);
      printer.printCustom("Serial Number: ${equipmentData?['serial_number'] ?? 'N/A'}", 0, 0);
      printer.printNewLine();
      printer.printQRcode(equipmentData?['qr_data'] ?? "No QR data", 200, 200, 1);
      printer.printNewLine();
      printer.disconnect();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please connect to a Bluetooth printer first.")),
      );
    }
  }

  Future<void> _selectBluetoothDevice() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Bluetooth Device"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_devices[index].name ?? "Unknown device"),
                  subtitle: Text(_devices[index].address ?? "No address"),
                  onTap: () {
                    setState(() {
                      _selectedDevice = _devices[index];
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Truncate processor information based on pattern
  String _getTruncatedProcessor(String? processor) {
    if (processor == null) return 'N/A';
    final RegExp regex = RegExp(r'i\d-\d+HQ.*'); // Example regex pattern for processor type
    final match = regex.firstMatch(processor);
    return match != null ? match.group(0)! : processor;
  }

  Future<void> _downloadQRCode(String? qrData, BuildContext context) async {
  if (qrData == null || qrData.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("QR code data is not available")),
    );
    return;
  }

  final status = await Permission.storage.request();
  if (status.isGranted) {
    try {
      final qrValidationResult = QrValidator.validate(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrPainter = QrPainter.withQr(
          qr: qrValidationResult.qrCode!,
          color: const Color(0xFF000000),
          gapless: true,
          emptyColor: Colors.white,
        );

        // Generate the QR code image without padding
        const double qrImageSize = 400.0; // Larger QR code for better readability
        final ui.Image qrImage = await qrPainter.toImage(qrImageSize.toDouble());

        // Define the padding
        const int padding = 20;
        final int paddedWidth = qrImage.width + padding * 2;
        final int paddedHeight = qrImage.height + padding * 2;

        // Add padding around the QR code
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder, Rect.fromPoints(
          const Offset(0, 0),
          Offset(paddedWidth.toDouble(), paddedHeight.toDouble()),
        ));
        
        // Fill background with white
        canvas.drawRect(
          Rect.fromLTWH(0, 0, paddedWidth.toDouble(), paddedHeight.toDouble()),
          Paint()..color = Colors.white,
        );
        
        // Draw the QR code centered with padding
        canvas.drawImage(qrImage, Offset(padding.toDouble(), padding.toDouble()), Paint());

        // Convert the canvas with padding to an image
        final ui.Image finalImage = await recorder.endRecording().toImage(paddedWidth, paddedHeight);
        final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List pngBytes = byteData!.buffer.asUint8List();

        // Save the image
        final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final directory = await getExternalStorageDirectory();
        final file = File('${directory!.path}/qr_code_$timestamp.png');
        await file.writeAsBytes(pngBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("QR Code saved to ${file.path}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to generate QR Code")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving QR code: $e")),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Storage permission denied")),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? equipmentData = widget.equipment.data() as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment Details"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailCard("Nom", equipmentData?['name']),
              _buildDetailCard("Address de messagerie", equipmentData?['email']),
              _buildDetailCard("Type", equipmentData?['type']),
              _buildDetailCard("marque", equipmentData?['brand']),
              _buildDetailCard("N.Serie", equipmentData?['serial_number']),
              _buildDetailCard("Processor", _getTruncatedProcessor(equipmentData?['processor'])),
              _buildDetailCard("Os", equipmentData?['os']),
              _buildDetailCard("RAM(Gb)", equipmentData?['ram']),
              _buildDetailCard("souris sans fil", equipmentData?['wireless_mouse']),
              _buildDetailCard("ecran extern", equipmentData?['external_screen']),
              _buildDetailCard("marque d'ecran", equipmentData?['screen_brand']),
              _buildDetailCard("S.N d'ecran", equipmentData?['screen_serial_number']),
              _buildDetailCard("numero d'inventaire ECR", equipmentData?['inventory_number_ecr']),
              _buildDetailCard("Departement/Service", equipmentData?['department']),
              _buildDetailCard("numero d'inventaire LPT", equipmentData?['inventory_number_lpt']),
              const SizedBox(height: 20),
              _buildQRCode(equipmentData?['qr_data']),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _downloadQRCode(equipmentData?['qr_data'], context),
                child: const Text("Download QR Code"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _printEquipmentDetails,
                child: const Text("Print qr code"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String? value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Flexible(
              child: Text(
                value ?? 'N/A',
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCode(String? qrData) {
    if (qrData == null || qrData.isEmpty) {
      return const Center(
        child: Text(
          'QR Code data is not available',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }
    return Center(
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: 200.0,
      ),
    );
  }
}


