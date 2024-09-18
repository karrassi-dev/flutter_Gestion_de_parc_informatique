import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UpdaterEquipment extends StatefulWidget {
  @override
  _UpdaterEquipmentState createState() => _UpdaterEquipmentState();
}

class _UpdaterEquipmentState extends State<UpdaterEquipment> {
  final CollectionReference equipmentCollection = FirebaseFirestore.instance.collection('equipment');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Update Equipment",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: equipmentCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No equipment found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final equipment = snapshot.data!.docs[index];
              return EquipmentCard(
                equipment: equipment,
                onUpdatePressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateSpecificEquipmentPage(equipment),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class EquipmentCard extends StatelessWidget {
  final QueryDocumentSnapshot equipment;
  final VoidCallback onUpdatePressed;

  const EquipmentCard({
    Key? key,
    required this.equipment,
    required this.onUpdatePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safely check if the 'status' field exists
    final Map<String, dynamic>? equipmentData = equipment.data() as Map<String, dynamic>?;
    final String status = equipmentData != null && equipmentData.containsKey('status')
        ? equipmentData['status']
        : 'Unknown';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Model: ${equipment['model']}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Serial Number: ${equipment['serial_number']}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Type: ${equipment['type']}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Location: ${equipment['location']}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Status: $status", // Display the status with a fallback
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: onUpdatePressed,
                  icon: const Icon(Icons.edit),
                  label: const Text("Update"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UpdateSpecificEquipmentPage extends StatelessWidget {
  final QueryDocumentSnapshot equipment;

  const UpdateSpecificEquipmentPage(this.equipment, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController modelController = TextEditingController(text: equipment['model']);
    final TextEditingController serialNumberController = TextEditingController(text: equipment['serial_number']);
    final TextEditingController locationController = TextEditingController(text: equipment['location']);
    
    final List<String> statusOptions = ['En cours d\'utilisation', 'En réparation', 'disponible'];
    
    // Safely check if the 'status' field exists
    final Map<String, dynamic>? equipmentData = equipment.data() as Map<String, dynamic>?;
    String? selectedStatus = equipmentData != null && equipmentData.containsKey('status')
        ? equipmentData['status']
        : statusOptions[0];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Equipment"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: modelController,
              decoration: const InputDecoration(
                labelText: "Model",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: serialNumberController,
              decoration: const InputDecoration(
                labelText: "Serial Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: "Location",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: "Status",
                border: OutlineInputBorder(),
              ),
              items: statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (newValue) {
                selectedStatus = newValue;
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('equipment')
                    .doc(equipment.id)
                    .update({
                      'model': modelController.text,
                      'serial_number': serialNumberController.text,
                      'location': locationController.text,
                      'status': selectedStatus,
                    })
                    .then((value) {
                      Navigator.pop(context); // Return to the previous screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Equipment updated successfully!")),
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
    );
  }
}
