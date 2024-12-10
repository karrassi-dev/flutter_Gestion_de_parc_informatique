import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'qr_data_display_page.dart'; // Ensure this import is correct

class QRCodeScannerPage extends StatefulWidget {
  const QRCodeScannerPage({Key? key}) : super(key: key);

  @override
  _QRCodeScannerPageState createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scanResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller != null) {
      if (state == AppLifecycleState.resumed) {
        controller!.resumeCamera();
      } else if (state == AppLifecycleState.paused) {
        controller!.pauseCamera();
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: scanResult == null
                  ? const Text('Scan a QR code')
                  : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Scanned Serial Number: $scanResult',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View Details'),
                    onPressed: () => _fetchEquipmentDetails(context, scanResult!),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        scanResult = scanData.code;
        if (scanResult != null) {
          controller.pauseCamera();
        }
      });
    });
  }

  void _fetchEquipmentDetails(BuildContext context, String serialNumber) async {
    try {
      // Query Firestore to find the equipment with the scanned serial number
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('equipment')
          .where('serial_number', isEqualTo: serialNumber)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Get the first matching document
        final document = snapshot.docs.first;

        // Pass the equipment data to QrDataDisplayPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QrDataDisplayPage(data: document.data() as Map<String, dynamic>),
          ),
        ).then((_) {
          // Resume camera after returning
          controller?.resumeCamera();
        });
      } else {
        // Show a message if no equipment is found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No equipment found for this serial number.')),
        );
        controller?.resumeCamera();
      }
    } catch (e) {
      // Handle any errors during the query
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching equipment details: $e')),
      );
      controller?.resumeCamera();
    }
  }
}
