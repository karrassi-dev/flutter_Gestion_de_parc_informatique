import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'EditEquipmentPage.dart'; // Import the edit page
import 'package:firebase_auth/firebase_auth.dart';

class QrDataDisplayPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const QrDataDisplayPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // List of fields to display
    final List<String> displayedFields = [
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scanned Data"),
        backgroundColor: Colors.deepPurple,
        actions: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users') // Ensure this is the correct collection
                .doc(FirebaseAuth.instance.currentUser?.uid) // Get the current user's UID
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                ); // Show loading indicator while fetching user data
              }

              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox.shrink(); // Hide the icon if there's an error or no data
              }

              // Safely retrieve role
              final String? userRole = snapshot.data!.get('role');

              // Show edit icon only if user is admin
              if (userRole == "Admin") {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    final String? serialNumber = data['serial_number']; // Use serial_number
                    if (serialNumber == null) {
                      // Show error message if serial_number is missing
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Error: Serial number is missing.")),
                      );
                      return;
                    }

                    // Navigate to the edit page with serial_number
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEquipmentPage(
                          data: data,
                          documentId: serialNumber, // Pass serial_number as document ID
                        ),
                      ),
                    );
                  },
                );
              }

              return const SizedBox.shrink(); // Do not show icon for non-admin users
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: displayedFields
                .where((field) => data.containsKey(field)) // Only include specified fields
                .map((field) => _buildDetailCard(field, data[field]?.toString() ?? 'N/A'))
                .toList(),
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
