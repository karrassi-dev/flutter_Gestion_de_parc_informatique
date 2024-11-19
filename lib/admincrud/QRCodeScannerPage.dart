import 'package:flutter/material.dart';
import 'package:my_flutter_app/admincrud/qr_data_display_page.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class EncryptionHelper {
  final encrypt.Key key;
  final encrypt.IV iv;

  EncryptionHelper(String password)
      : key = encrypt.Key.fromUtf8(md5.convert(utf8.encode(password)).toString()),
        iv = encrypt.IV.fromUtf8('16-Bytes---IVKey'); // Consistent IV for decryption

  String decryptText(String encryptedText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
    return decrypted;
  }
}

class QRCodeScannerPage extends StatefulWidget {
  const QRCodeScannerPage({Key? key}) : super(key: key);

  @override
  _QRCodeScannerPageState createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scanResult;
  final encryptionHelper = EncryptionHelper('S3cur3P@ssw0rd123!'); // Encryption password

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
                  ? Text('Scan a QR code')
                  : Container(),
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
          _showScannedData(context, scanResult!);
        }
      });
    });
  }

  void _showScannedData(BuildContext context, String encryptedData) {
    try {
      // Decrypt the scanned QR data
      final decryptedData = encryptionHelper.decryptText(encryptedData);
      // Parse the decrypted JSON string into a map
      final decodedData = _parseQrData(decryptedData);

      // Navigate to QrDataDisplayPage with decrypted and decoded data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrDataDisplayPage(data: decodedData),
        ),
      ).then((_) {
        // Reset scan result and resume camera after returning from QrDataDisplayPage
        setState(() {
          scanResult = null;
        });
        controller?.resumeCamera();
      });
    } catch (e) {
      // Show an error if decryption fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to decrypt QR data: $e")),
      );
      controller?.resumeCamera();
    }
  }

  Map<String, dynamic> _parseQrData(String data) {
    return Map<String, dynamic>.from(jsonDecode(data));
  }
}
