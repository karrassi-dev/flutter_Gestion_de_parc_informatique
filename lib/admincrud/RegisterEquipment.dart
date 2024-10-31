import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart'; // Import screenshot package
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class RegisterEquipment extends StatefulWidget {
  const RegisterEquipment({super.key});

  @override
  _RegisterEquipmentState createState() => _RegisterEquipmentState();
}

class _RegisterEquipmentState extends State<RegisterEquipment> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Screenshot controller for QR code download
  final ScreenshotController _screenshotController = ScreenshotController();

  // Controllers for all fields
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController serialNumberController = TextEditingController();
  final TextEditingController processorController = TextEditingController();
  final TextEditingController osController = TextEditingController();
  final TextEditingController ramController = TextEditingController();
  final TextEditingController externalScreenController = TextEditingController();
  final TextEditingController screenBrandController = TextEditingController();
  final TextEditingController screenSerialNumberController = TextEditingController();
  final TextEditingController inventoryNumberEcrController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final TextEditingController inventoryNumberLptController = TextEditingController();

  int currentPageIndex = 0;
  bool _isWirelessMouse = false;
  bool _isAdditionalFieldsVisible = false;
  String? qrData; // Variable to store QR code data

  final CollectionReference equipmentCollection = FirebaseFirestore.instance.collection('equipment');

  final List<String> typeOptions = [
    'imprimante', 'avaya', 'point d’access', 'switch', 'DVR', 'TV',
    'scanner', 'routeur', 'balanceur', 'standard téléphonique',
    'data show', 'desktop', 'laptop'
  ];

  Future<void> registerEquipment() async {
    if (_formKey.currentState!.validate()) {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Create a map for the equipment data
        Map<String, dynamic> equipmentData = {
          'start_time': startTimeController.text,
          'end_time': endTimeController.text,
          'email': emailController.text,
          'name': nameController.text,
          'type': typeController.text,
          'user': userController.text,
          'brand': brandController.text,
          'reference': referenceController.text,
          'serial_number': serialNumberController.text,
          'processor': processorController.text,
          'os': osController.text,
          'ram': ramController.text,
          'wireless_mouse': _isWirelessMouse ? 'Oui' : 'Non',
          if (typeController.text == 'desktop' || typeController.text == 'laptop') ...{
            if (_isAdditionalFieldsVisible) ...{
              'external_screen': externalScreenController.text,
              'screen_brand': screenBrandController.text,
              'screen_serial_number': screenSerialNumberController.text,
              'inventory_number_ecr': inventoryNumberEcrController.text,
            }
          },
        };

        try {
          // Save equipment data in Firestore
          DocumentReference newDocRef = await equipmentCollection.add(equipmentData);

          // Add the document ID to the equipment data for QR code
          equipmentData['document_id'] = newDocRef.id; // Add the document ID

          // Generate QR Code with equipment data as JSON string including document ID
          String generatedQRData = jsonEncode(equipmentData);

          // Update the QR data to include the generated QR data
          await newDocRef.update({'qr_data': generatedQRData}); // Store the generated QR data in Firestore

          // Update local state for QR code display
          setState(() {
            qrData = generatedQRData;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Equipment registered successfully!")),
          );

          _clearFields();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to register equipment: $e")),
          );
        }
      }
    }
  }

  Future<void> _downloadQRCode() async {
    if (qrData == null) return;

    final Uint8List? imageBytes = await _screenshotController.capture();
    if (imageBytes != null) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/qr_code.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("QR Code downloaded to $filePath")),
      );
    }
  }

  void _clearFields() {
    startTimeController.clear();
    endTimeController.clear();
    emailController.clear();
    nameController.clear();
    typeController.clear();
    userController.clear();
    brandController.clear();
    referenceController.clear();
    serialNumberController.clear();
    processorController.clear();
    osController.clear();
    ramController.clear();
    externalScreenController.clear();
    screenBrandController.clear();
    screenSerialNumberController.clear();
    inventoryNumberEcrController.clear();
    statusController.clear();
    inventoryNumberLptController.clear();
  }

  void nextPage() {
    if (_formKey.currentState!.validate()) {
      if (currentPageIndex < 2) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          currentPageIndex++;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields.")),
      );
    }
  }

  void previousPage() {
    if (currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        currentPageIndex--;
      });
    }
  }

  Widget buildTextField(TextEditingController controller, String hintText, IconData icon, {bool required = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Please enter $hintText';
        }
        return null;
      },
    );
  }

  Widget buildDropdown(List<String> options, TextEditingController controller, String hintText) {
    return DropdownButtonFormField<String>(
      value: controller.text.isEmpty ? null : controller.text,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      items: options.map((String option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          controller.text = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select $hintText';
        }
        return null;
      },
    );
  }

  Widget buildCheckbox(String hintText, bool value, Function(bool?) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(hintText),
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Register Equipment", style: TextStyle(fontWeight: FontWeight.bold)),
      //   backgroundColor: Colors.deepPurple,
      //),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  buildTextField(startTimeController, "heure de debut", Icons.access_time),
                  const SizedBox(height: 20),
                  buildTextField(endTimeController, "heure de fin", Icons.access_time_filled),
                  const SizedBox(height: 20),
                  buildTextField(emailController, "Address de messagerie", Icons.email),
                  const SizedBox(height: 20),
                  buildTextField(nameController, "nom", Icons.person),
                  const SizedBox(height: 20),
                  buildDropdown(typeOptions, typeController, "Type"),
                ],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  buildTextField(userController, "utilisateur", Icons.person_outline),
                  const SizedBox(height: 20),
                  buildTextField(brandController, "marque", Icons.branding_watermark),
                  const SizedBox(height: 20),
                  buildTextField(referenceController, "Reference", Icons.book),
                  const SizedBox(height: 20),
                  buildTextField(serialNumberController, "numero de serie", Icons.confirmation_number),
                  const SizedBox(height: 20),
                  buildTextField(processorController, "composant - processeur", Icons.memory),
                  const SizedBox(height: 20),
                  buildTextField(osController, "system d'exploitation", Icons.computer),
                  const SizedBox(height: 20),
                  buildTextField(ramController, "RAM (en Go)", Icons.memory),
                  const SizedBox(height: 20),
                  buildCheckbox("Souris sans fil", _isWirelessMouse, (value) {
                    setState(() {
                      _isWirelessMouse = value!;
                    });
                  }),
                ],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  if (typeController.text == 'desktop' || typeController.text == 'laptop') ...[
                    buildCheckbox(
                      "have a screen",
                      _isAdditionalFieldsVisible,
                      (bool? value) {
                        setState(() {
                          _isAdditionalFieldsVisible = value!;
                        });
                      },
                    ),
                  ],
                  if (_isAdditionalFieldsVisible) ...[
                    buildTextField(externalScreenController, "Ecran externe", Icons.desktop_windows, required: true),
                    const SizedBox(height: 20),
                    buildTextField(screenBrandController, "Marque de l'ecran", Icons.tv, required: true),
                    const SizedBox(height: 20),
                    buildTextField(screenSerialNumberController, "Numéro de série de l'écran", Icons.confirmation_number, required: true),
                    const SizedBox(height: 20),
                    buildTextField(inventoryNumberEcrController, "N° inventaire ECR", Icons.category, required: true),
                    const SizedBox(height: 20),
                  ],
                  buildTextField(statusController, "État", Icons.assignment_turned_in),
                  const SizedBox(height: 20),
                  buildTextField(inventoryNumberLptController, "N° inventaire LPT", Icons.category),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentPageIndex > 0)
            Padding(
              padding: const EdgeInsets.only(left: 38.0),
              child: FloatingActionButton(
                onPressed: previousPage,
                child: const Icon(Icons.arrow_back),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 38.0),
            child: FloatingActionButton(
              onPressed: currentPageIndex == 2 ? registerEquipment : nextPage,
              child: currentPageIndex == 2 ? const Icon(Icons.save) : const Icon(Icons.arrow_forward),
            ),
          ),
        ],
      ),
      bottomNavigationBar: qrData != null
          ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Screenshot(
                    controller: _screenshotController,
                    child: QrImageView(
                      data: qrData!,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _downloadQRCode,
                    icon: const Icon(Icons.download),
                    label: const Text("Download QR Code"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

