import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  final CollectionReference equipmentCollection =
      FirebaseFirestore.instance.collection('equipment');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment List"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: equipmentCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No equipment available"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final equipment = snapshot.data!.docs[index];
              return EquipmentCard(
                equipment: equipment,
                onRequestPressed: () {

                  _showRequestDialog(context, equipment);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showRequestDialog(BuildContext context, QueryDocumentSnapshot equipment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Request Equipment"),
          content: Text("Do you want to request ${equipment['name']}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Request submitted!")),
                );
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("Request"),
            ),
          ],
        );
      },
    );
  }
}

class EquipmentCard extends StatelessWidget {
  final QueryDocumentSnapshot equipment;
  final VoidCallback onRequestPressed;

  const EquipmentCard({
    Key? key,
    required this.equipment,
    required this.onRequestPressed,
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
              "Name: ${equipmentData?['name']}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Type: ${equipmentData?['type']}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Brand: ${equipmentData?['brand']}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: onRequestPressed,
                  child: const Text("Request"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
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
