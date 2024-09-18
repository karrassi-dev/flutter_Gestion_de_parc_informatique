import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date

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

  final List<String> equipmentTypes = ['ordinateurs', 'imprimantes', 'serveurs', 'routeurs', 'PDA'];

  final List<String> equipmentStatuses = ['En cours d\'utilisation', 'En réparation', 'disponible'];

  String? selectedEquipmentType;
  String? selectedEquipmentStatus;

  final CollectionReference equipmentCollection = FirebaseFirestore.instance.collection('equipment');

  Future<void> registerEquipment() async {
    if (_formKey.currentState!.validate()) {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && selectedEquipmentType != null && selectedEquipmentStatus != null) {

        Map<String, dynamic> equipmentData = {
          'serial_number': serialNumberController.text,
          'model': modelController.text,
          'purchase_date': purchaseDateController.text,
          'location': locationController.text,
          'type': selectedEquipmentType,
          'status': selectedEquipmentStatus,  
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

  Future<void> _selectPurchaseDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        purchaseDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register New Equipment"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); 
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

              // Purchase Date Field with Date Picker
              TextField(
                controller: purchaseDateController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: "Purchase Date",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.purple.withOpacity(0.1),
                  filled: true,
                  prefixIcon: const Icon(Icons.date_range),
                ),
                onTap: () => _selectPurchaseDate(context),
              ),
              const SizedBox(height: 20),

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
