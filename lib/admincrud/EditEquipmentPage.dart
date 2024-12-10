import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

// Encryption helper class
class EncryptionHelper {
  final encrypt.Key key;
  final encrypt.IV iv;

  EncryptionHelper(String password)
      : key = encrypt.Key.fromUtf8(md5.convert(utf8.encode(password)).toString()),
        iv = encrypt.IV.fromUtf8('16-Bytes---IVKey'); // Fixed IV for consistency

  String encryptText(String text) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(text, iv: iv);
    return encrypted.base64;
  }
}

class EditEquipmentPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String documentId;

  const EditEquipmentPage({Key? key, required this.data, required this.documentId}) : super(key: key);

  @override
  _EditEquipmentPageState createState() => _EditEquipmentPageState();
}

class _EditEquipmentPageState extends State<EditEquipmentPage> {
  late Map<String, TextEditingController> _controllers;
  final encryptionHelper = EncryptionHelper('S3cur3P@ssw0rd123!'); // Encryption password

  final List<String> allowedFields = [
    'start_time',
    'end_time',
    'site',
    'name',
    'location',
    'user',
    'processor',
    'os',
    'ram',
    'email',
    'brand',
    'department',
    'model',
    'reference',
    'storage',
    'wireless_mouse',
  ]; 

  @override
  void initState() {
    super.initState();
    _controllers = {};
    widget.data.forEach((key, value) {
      if (allowedFields.contains(key)) {
        _controllers[key] = TextEditingController(text: value.toString());
      }
    });
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  Future<void> _saveData() async {
    Map<String, dynamic> updatedData = {};
    _controllers.forEach((key, controller) {
      updatedData[key] = controller.text;
    });

    try {

      await FirebaseFirestore.instance.collection('equipment').doc(widget.documentId).update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data updated successfully!")),
      );
      Navigator.pop(context, updatedData);
    } catch (e) {
      print("Error updating document: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update data: $e")),
      );
    }
  }

  Future<void> _selectDateTime(
      BuildContext context, TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty
          ? DateTime.parse(controller.text)
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            controller.text.isNotEmpty
                ? DateTime.parse(controller.text)
                : DateTime.now()),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        controller.text = fullDateTime.toIso8601String();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Equipment Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              for (var field in allowedFields)
                if (_controllers.containsKey(field))
                  buildTextField(field, _controllers[field]!, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      String label, TextEditingController controller, BuildContext context) {


    if (label == 'start_time' || label == 'end_time') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: GestureDetector(
          onTap: () => _selectDateTime(context, controller),
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label.replaceAll('_', ' ').toUpperCase(),
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today), // Calendar icon
              ),
            ),
          ),
        ),
      );
    }

    // Default text field for other fields
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label.replaceAll('_', ' ').toUpperCase(),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
