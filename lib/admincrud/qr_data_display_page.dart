import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'EditEquipmentPage.dart'; // Import the edit page
import 'package:firebase_auth/firebase_auth.dart';

class QrDataDisplayPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const QrDataDisplayPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scanned Data"),
        backgroundColor: Colors.deepPurple,
        actions: [
          // Check the user's role
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users') // Ensure this is the correct collection
                .doc(FirebaseAuth.instance.currentUser?.uid) // Get the current user's UID
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(); // Show loading indicator while fetching user data
              }

              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return SizedBox.shrink(); // Hide the icon if there's an error or no data
              }

              // Safely retrieve role
              String? userRole = snapshot.data!.get('role');

              // Show edit icon only if user is admin
              if (userRole == "Admin") {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Navigate to the edit page with document ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEquipmentPage(
                          data: data,
                          documentId: data['document_id'], // Pass the document ID
                        ),
                      ),
                    );
                  },
                );
              }

              return SizedBox.shrink(); // Do not show icon for non-admin users
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.entries.map((entry) {
              // Skip displaying document_id
              if (entry.key == 'document_id') return SizedBox.shrink(); // Do not display

              return _buildDetailCard(entry.key, entry.value.toString());
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
