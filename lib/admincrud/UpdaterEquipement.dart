import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'UpdateSpecificEquipmentPage.dart';
import 'ViewEquipmentDetailsPage.dart';

class UpdaterEquipment extends StatefulWidget {
  @override
  _UpdaterEquipmentState createState() => _UpdaterEquipmentState();
}

class _UpdaterEquipmentState extends State<UpdaterEquipment> {
  final CollectionReference equipmentCollection = FirebaseFirestore.instance.collection('equipment');
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text(
        //   "Update Equipment",
        //   style: TextStyle(fontWeight: FontWeight.bold),
        // ),
        backgroundColor: Colors.deepPurple,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search equipment...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
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

          final filteredDocs = snapshot.data!.docs.where((doc) {
  final equipmentData = doc.data() as Map<String, dynamic>;
  final name = equipmentData['name']?.toLowerCase() ?? '';
  final email = equipmentData['email']?.toLowerCase() ?? '';
  final type = equipmentData['type']?.toLowerCase() ?? '';
  final brand = equipmentData['brand']?.toLowerCase() ?? '';
  final serialNumber = equipmentData['serial_number']?.toLowerCase() ?? '';

  return name.contains(searchQuery) ||
         email.contains(searchQuery) ||
         type.contains(searchQuery) ||
         brand.contains(searchQuery) ||
         serialNumber.contains(searchQuery);
}).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final equipment = filteredDocs[index];
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
                onDeletePressed: () {
                  _showDeleteConfirmation(context, equipment.id);
                },
                onViewDetailsPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewEquipmentDetailsPage(equipment),
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

  void _showDeleteConfirmation(BuildContext context, String equipmentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this equipment?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('equipment').doc(equipmentId).delete().then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Equipment deleted successfully!")),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}

class EquipmentCard extends StatelessWidget {
  final QueryDocumentSnapshot equipment;
  final VoidCallback onUpdatePressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onViewDetailsPressed;

  const EquipmentCard({
    Key? key,
    required this.equipment,
    required this.onUpdatePressed,
    required this.onDeletePressed,
    required this.onViewDetailsPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? equipmentData = equipment.data() as Map<String, dynamic>?;

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
              "Name: ${equipmentData?['name'] ?? ''}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              "Email: ${equipmentData?['email'] ?? ''}",
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              "Type: ${equipmentData?['type'] ?? ''}",
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              "Brand: ${equipmentData?['brand'] ?? ''}",
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              "Serial Number: ${equipmentData?['serial_number'] ?? ''}",
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ElevatedButton.icon(
                  onPressed: onViewDetailsPressed,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text("Details"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onUpdatePressed,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Modifier"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onDeletePressed,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text("Supp"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
