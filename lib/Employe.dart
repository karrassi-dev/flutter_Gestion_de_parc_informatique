import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './employe_actions/ViewEquipmentDetailsPage.dart'; 
import './employe_actions/RequestsPage.dart'; 
import './employe_actions/EmployeRequestPage.dart'; 
import 'login.dart'; 

class Employe extends StatelessWidget {
  final CollectionReference equipmentCollection =
      FirebaseFirestore.instance.collection('equipment');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment List"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            onPressed: () => _logout(context), 
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployRequestsPage()
                ),
              );
            },
            icon: const Icon(Icons.list),
            tooltip: "View My Requests",
          ),
        ],
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
                _requestEquipment(equipment);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Request submitted!")),
                );
              },
              child: const Text("Request"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestEquipment(QueryDocumentSnapshot equipment) async {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;
    FirebaseFirestore.instance.collection('equipment_requests').add({
      'equipmentId': equipment.id,
      'equipmentName': equipment['name'],
      'requester': userEmail,
      'status': 'Pending',
      'isRead': false,  
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _sendNotificationToAdmin(equipment['name']);
  }

  Future<void> _sendNotificationToAdmin(String equipmentName) async {
    
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out successfully!")),
    );
  }
}

class EquipmentCard extends StatelessWidget {
  final QueryDocumentSnapshot equipment;
  final VoidCallback onRequestPressed;
  final VoidCallback onViewDetailsPressed;

  const EquipmentCard({
    Key? key,
    required this.equipment,
    required this.onRequestPressed,
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
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onViewDetailsPressed,
                  child: const Text("View Details"),
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
