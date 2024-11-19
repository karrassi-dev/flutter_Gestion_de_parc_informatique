import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';

// Encryption helper class
class EncryptionHelper {
  final encrypt.Key key;
  final encrypt.IV iv;

  EncryptionHelper(String password)
      : key = encrypt.Key.fromUtf8(md5.convert(utf8.encode(password)).toString()),
        iv = encrypt.IV.fromUtf8('16-Bytes---IVKey'); // Fixed IV for consistent encryption/decryption

  String encryptText(String text) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(text, iv: iv);
    return encrypted.base64;
  }
}

class UpdateSpecificEquipmentPage extends StatelessWidget {
  final QueryDocumentSnapshot equipment;

  const UpdateSpecificEquipmentPage(this.equipment, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final equipmentData = equipment.data() as Map<String, dynamic>?;
    final encryptionHelper = EncryptionHelper('S3cur3P@ssw0rd123!');

    // Controllers for form fields
    final TextEditingController startTimeController = TextEditingController(text: equipmentData?['start_time'] ?? '');
    final TextEditingController endTimeController = TextEditingController(text: equipmentData?['end_time'] ?? '');
    final TextEditingController emailController = TextEditingController(text: equipmentData?['email'] ?? '');
    final TextEditingController nameController = TextEditingController(text: equipmentData?['name'] ?? '');
    final TextEditingController siteController = TextEditingController(text: equipmentData?['site'] ?? '');
    final TextEditingController typeController = TextEditingController(text: equipmentData?['type'] ?? '');
    final TextEditingController userController = TextEditingController(text: equipmentData?['user'] ?? '');
    final TextEditingController brandController = TextEditingController(text: equipmentData?['brand'] ?? '');
    final TextEditingController referenceController = TextEditingController(text: equipmentData?['reference'] ?? '');
    final TextEditingController serialNumberController = TextEditingController(text: equipmentData?['serial_number'] ?? '');
    final TextEditingController processorController = TextEditingController(text: equipmentData?['processor'] ?? '');
    final TextEditingController osController = TextEditingController(text: equipmentData?['os'] ?? '');
    final TextEditingController ramController = TextEditingController(text: equipmentData?['ram'] ?? '');
    final TextEditingController storageController = TextEditingController(text: equipmentData?['storage'] ?? '');
    final TextEditingController wirelessMouseController = TextEditingController(text: equipmentData?['wireless_mouse'] ?? '');
    final TextEditingController externalScreenController = TextEditingController(text: equipmentData?['external_screen'] ?? '');
    final TextEditingController screenBrandController = TextEditingController(text: equipmentData?['screen_brand'] ?? '');
    final TextEditingController screenSerialNumberController = TextEditingController(text: equipmentData?['screen_serial_number'] ?? '');
    final TextEditingController inventoryNumberEcrController = TextEditingController(text: equipmentData?['inventory_number_ecr'] ?? '');
    final TextEditingController departmentController = TextEditingController(text: equipmentData?['department'] ?? '');
    final TextEditingController statusController = TextEditingController(text: equipmentData?['status'] ?? '');
    final TextEditingController inventoryNumberLptController = TextEditingController(text: equipmentData?['inventory_number_lpt'] ?? '');

    // Track original storage value for change detection
    final String originalStorage = equipmentData?['storage'] ?? '';

    final List<String> typeOptions = [
      'imprimante', 'avaya', 'point d’access', 'switch', 'DVR', 'TV', 'scanner', 'routeur',
      'balanceur', 'standard téléphonique', 'data show', 'desktop', 'laptop'
    ];
    final List<String> departmentOptions = [
      'maintenance', 'qualité', 'administration', 'commercial', 'caisse', 'chef d’agence', 
      'ADV', 'DOSI', 'DRH', 'logistique', 'contrôle de gestion', 'moyens généraux', 
      'GRC', 'production', 'comptabilité', 'achat', 'audit'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Equipment"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildTextField("Date de debut", startTimeController),
              buildTextField("Date de fin", endTimeController),
              buildTextField("Address de messagerie", emailController),
              buildTextField("Name", nameController),
              buildTextField("Site", siteController),
              buildDropdownField("Type", typeController, typeOptions),
              buildTextField("User", userController),
              buildTextField("Brand", brandController),
              buildTextField("Reference", referenceController),
              buildTextField("Serial Number", serialNumberController),
              buildTextField("Processor", processorController),
              buildTextField("Operating System", osController),
              buildTextField("RAM", ramController),
              buildTextField("STORAGE", storageController),
              buildTextField("Wireless Mouse", wirelessMouseController),
              buildTextField("External Screen", externalScreenController),
              buildTextField("Screen Brand", screenBrandController),
              buildTextField("Screen Serial Number", screenSerialNumberController),
              buildTextField("Inventory Number ECR", inventoryNumberEcrController),
              buildDropdownField("Department", departmentController, departmentOptions),
              buildTextField("Status", statusController),
              buildTextField("Inventory Number LPT", inventoryNumberLptController),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  Map<String, dynamic> updatedData = {
                    'start_time': startTimeController.text,
                    'end_time': endTimeController.text,
                    'email': emailController.text,
                    'name': nameController.text,
                    'site': siteController.text,
                    'type': typeController.text,
                    'user': userController.text,
                    'brand': brandController.text,
                    'reference': referenceController.text,
                    'serial_number': serialNumberController.text,
                    'processor': processorController.text,
                    'os': osController.text,
                    'ram': ramController.text,
                    'wireless_mouse': wirelessMouseController.text,
                    'external_screen': externalScreenController.text,
                    'screen_brand': screenBrandController.text,
                    'screen_serial_number': screenSerialNumberController.text,
                    'inventory_number_ecr': inventoryNumberEcrController.text,
                    'department': departmentController.text,
                    'status': statusController.text,
                    'inventory_number_lpt': inventoryNumberLptController.text,
                  };

                  // Check if storage has changed
                  if (storageController.text != originalStorage) {
                    updatedData['storage'] = storageController.text;

                    // Only re-generate encrypted QR data if storage has changed
                    Map<String, dynamic> qrData = {
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
                      'wireless_mouse': wirelessMouseController.text,
                      'document_id': equipment.id,
                      'storage': storageController.text,
                    };

                    // Encrypt QR data
                    String qrDataPlain = jsonEncode(qrData);
                    String encryptedQRData = encryptionHelper.encryptText(qrDataPlain);

                    // Add encrypted QR data to Firestore update
                    updatedData['qr_data'] = encryptedQRData;
                  }

                  FirebaseFirestore.instance.collection('equipment').doc(equipment.id).update(updatedData).then((value) {
                    Navigator.pop(context); // Go back after saving
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Equipment updated successfully!")),
                    );
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to update equipment: $error")),
                    );
                  });
                },
                child: const Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildDropdownField(String label, TextEditingController controller, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: options.contains(controller.text) ? controller.text : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (newValue) {
          controller.text = newValue ?? '';
        },
      ),
    );
  }
}
