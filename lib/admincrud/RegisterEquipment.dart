import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterEquipment extends StatefulWidget {
  const RegisterEquipment({super.key});

  @override
  _RegisterEquipmentState createState() => _RegisterEquipmentState();
}

class _RegisterEquipmentState extends State<RegisterEquipment> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController serialNumberController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController purchaseDateController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  // List of equipment types for the dropdown
  final List<String> equipmentTypes = ['ordinateurs', 'imprimantes', 'serveurs', 'routeurs', 'PDA'];

  // List of status options
  final List<String> equipmentStatuses = ['En cours d\'utilisation', 'En réparation', 'disponible'];

  // Selected equipment type and status
  String? selectedEquipmentType;
  String? selectedEquipmentStatus;

  final CollectionReference equipmentCollection = FirebaseFirestore.instance.collection('equipment');

  Future<void> registerEquipment() async {
    if (_formKey.currentState!.validate()) {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && selectedEquipmentType != null && selectedEquipmentStatus != null) {
        // Gather data from the form
        Map<String, dynamic> equipmentData = {
          'serial_number': serialNumberController.text,
          'model': modelController.text,
          'purchase_date': purchaseDateController.text,
          'location': locationController.text,
          'type': selectedEquipmentType,
          'status': selectedEquipmentStatus,  // Include the selected equipment status
          'added_by': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        };

        try {
          await equipmentCollection.add(equipmentData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Equipment registered successfully!")),
          );
          _clearFields();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to register equipment: $e")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill out all fields.")),
        );
      }
    }
  }

  void _clearFields() {
    serialNumberController.clear();
    modelController.clear();
    purchaseDateController.clear();
    locationController.clear();
    setState(() {
      selectedEquipmentType = null;
      selectedEquipmentStatus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register New Equipment"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the Admin page
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60.0),
              const Text(
                "Register Equipment",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Enter equipment details",
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // Serial Number Field
              TextFormField(
                controller: serialNumberController,
                decoration: InputDecoration(
                  hintText: "Serial Number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.purple.withOpacity(0.1),
                  filled: true,
                  prefixIcon: const Icon(Icons.code),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Serial Number cannot be empty";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Model Field
              TextFormField(
                controller: modelController,
                decoration: InputDecoration(
                  hintText: "Model",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.purple.withOpacity(0.1),
                  filled: true,
                  prefixIcon: const Icon(Icons.computer),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Model cannot be empty";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Equipment Type Dropdown Field
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: "Select Equipment Type",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.purple.withOpacity(0.1),
                  filled: true,
                  prefixIcon: const Icon(Icons.category),
                ),
                value: selectedEquipmentType,
                items: equipmentTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedEquipmentType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return "Please select an equipment type";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Equipment Status Dropdown Field
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: "Select Equipment Status",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.purple.withOpacity(0.1),
                  filled: true,
                  prefixIcon: const Icon(Icons.info_outline),
                ),
                value: selectedEquipmentStatus,
                items: equipmentStatuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedEquipmentStatus = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return "Please select an equipment status";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Purchase Date Field
              TextFormField(
                controller: purchaseDateController,
                decoration: InputDecoration(
                  hintText: "Purchase Date (YYYY-MM-DD)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.purple.withOpacity(0.1),
                  filled: true,
                  prefixIcon: const Icon(Icons.date_range),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Purchase Date cannot be empty";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Location Field
              TextFormField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: "Location",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.purple.withOpacity(0.1),
                  filled: true,
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Location cannot be empty";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              // Submit Button
              ElevatedButton(
                onPressed: registerEquipment,
                child: const Text(
                  "Register Equipment",
                  style: TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.purple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    serialNumberController.dispose();
    modelController.dispose();
    purchaseDateController.dispose();
    locationController.dispose();
    super.dispose();
  }
}
