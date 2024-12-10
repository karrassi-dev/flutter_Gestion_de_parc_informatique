import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRequestsPage extends StatefulWidget {
  @override
  _MyRequestsPageState createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  final String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
  String filterStatus = 'all'; // Filter: all, assigned, not_assigned
  List<DocumentSnapshot> filteredRequests = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Demandes"),
        backgroundColor: Color(0xFF467F67),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                filterStatus = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(value: 'all', child: Text("Tous")),
                const PopupMenuItem(value: "assigned", child: Text("Assigné")),
                const PopupMenuItem(value: "not_assigned", child: Text("Non Assigné")),
              ];
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('equipmentRequests')
            .where('requester', isEqualTo: userEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Aucune demande trouvée.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final requests = snapshot.data!.docs;

          // Apply filter based on assigned status
          filteredRequests = requests.where((request) {
            final requestData = request.data() as Map<String, dynamic>?;
            bool isAssigned = requestData?['isAssigned'] ?? false;

            if (filterStatus == 'all') return true;
            if (filterStatus == "assigned") return isAssigned;
            if (filterStatus == "not_assigned") return !isAssigned;
            return true;
          }).toList();

          // Sort requests by request date (newest first)
          filteredRequests.sort((a, b) {
            final dateA = (a.data() as Map<String, dynamic>)['requestDate'] as Timestamp;
            final dateB = (b.data() as Map<String, dynamic>)['requestDate'] as Timestamp;
            return dateB.compareTo(dateA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final request = filteredRequests[index];
              final requestData = request.data() as Map<String, dynamic>?;

              // Determine request type and status
              String status = requestData?['status'] ?? 'unknown';

              if (status == 'en_maintenance') {
                // Maintenance request design
                return _buildMaintenanceCard(requestData);
              } else if (status == 'Available') {
                // Available status design
                return _buildAvailableCard(requestData);
              } else if (status == 'Approved') {
                // Approved status design
                return _buildApprovedCard(requestData);
              } else {
                // Pending or default status design
                return _buildPendingCard(requestData, status);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMaintenanceCard(Map<String, dynamic>? requestData) {
    return Card(
      color: Colors.lightBlue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: const Icon(Icons.build, color: Colors.white),
        ),
        title: Text(
          requestData?['equipmentType'] ?? "Équipement inconnu",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Status: En maintenance"),
            Text("Site: ${requestData?['site'] ?? "Inconnu"}"),
            Text("Département: ${requestData?['department'] ?? "Inconnu"}"),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCard(Map<String, dynamic>? requestData) {
    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: const Icon(Icons.done, color: Colors.white),
        ),
        title: Text(
          requestData?['equipmentType'] ?? "Équipement inconnu",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Status: Maintenance terminée"),
            Text("Site: ${requestData?['site'] ?? "Inconnu"}"),
            Text("Département: ${requestData?['department'] ?? "Inconnu"}"),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedCard(Map<String, dynamic>? requestData) {
    return Card(
      color: Colors.lightGreen.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.lightGreen,
          child: const Icon(Icons.check_circle, color: Colors.white),
        ),
        title: Text(
          requestData?['equipmentType'] ?? "Équipement inconnu",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Status: Approved"),
            Text("Site: ${requestData?['site'] ?? "Inconnu"}"),
            Text("Département: ${requestData?['department'] ?? "Inconnu"}"),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic>? requestData, String status) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: const Icon(Icons.hourglass_empty, color: Colors.white),
        ),
        title: Text(
          requestData?['equipmentType'] ?? "Équipement inconnu",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status: ${status.capitalize()}"),
            Text("Site: ${requestData?['site'] ?? "Inconnu"}"),
            Text("Département: ${requestData?['department'] ?? "Inconnu"}"),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return '${this[0].toUpperCase()}${this.substring(1)}';
  }
}
