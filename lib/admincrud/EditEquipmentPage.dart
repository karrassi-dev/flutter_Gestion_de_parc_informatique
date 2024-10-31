import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class EditEquipmentPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String documentId;

  const EditEquipmentPage({Key? key, required this.data, required this.documentId}) : super(key: key);

  @override
  _EditEquipmentPageState createState() => _EditEquipmentPageState();
}

class _EditEquipmentPageState extends State<EditEquipmentPage> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    widget.data.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value.toString());
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

    // Include the document ID in the updated data
    updatedData['document_id'] = widget.documentId;

    // Generate new QR data with the updated values
    String generatedQRData = jsonEncode(updatedData);

    try {
      // Update the Firestore document with the new data
      await FirebaseFirestore.instance.collection('equipment').doc(widget.documentId).update(updatedData);

      // Also update the QR data field with the new QR string
      await FirebaseFirestore.instance.collection('equipment').doc(widget.documentId).update({'qr_data': generatedQRData});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data updated successfully!")),
      );
      Navigator.pop(context, updatedData);
    } catch (e) {
      // Catch specific exceptions
      print("Error updating document: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update data: $e")),
      );
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
              // Build text fields for each entry except document_id
              for (var entry in widget.data.entries)
                if (entry.key != 'document_id') // Skip the document_id field
                  buildTextField(entry.key, _controllers[entry.key]!),
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
}
