import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRequestsPage extends StatefulWidget {
  @override
  _MyRequestsPageState createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  final String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
  String filterStatus = 'all'; 
  List<DocumentSnapshot> filteredRequests = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Demandes"),
        backgroundColor: Colors.deepPurple,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                filterStatus = value; // Update the filter status
              });
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(value: 'all', child: Text("Tous")), // 'all' for "Tous" filter
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

            if (filterStatus == 'all') {
              return true; 
            } else if (filterStatus == "assigned") {
              return isAssigned; 
            } else if (filterStatus == "not_assigned") {
              return !isAssigned; 
            }
            return true;
          }).toList();

          // Sort  by request date (newest first)
          filteredRequests.sort((a, b) {
            final dateA = (a.data() as Map<String, dynamic>)['requestDate'] as Timestamp;
            final dateB = (b.data() as Map<String, dynamic>)['requestDate'] as Timestamp;
            return dateB.compareTo(dateA); // Sort by descending order
          });

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final request = filteredRequests[index];
              final requestData = request.data() as Map<String, dynamic>?;

              bool isAssigned = requestData?['isAssigned'] ?? false;

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('equipmentHistory')
                    .where('requestId', isEqualTo: request.id) // requestId to fetch history
                    .get(),
                builder: (context, historySnapshot) {
                  if (historySnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (historySnapshot.hasError) {
                    return const Text('Erreur lors de la récupération de l’historique des équipements');
                  }

                  final historyData = historySnapshot.data?.docs.isNotEmpty == true
    ? historySnapshot.data!.docs.first.data() as Map<String, dynamic>?
    : null;

// Access each field based on your document structure
String assignedBy = historyData?['assignedBy'] ?? 'N/A';
String utilisateur = historyData?['utilisateur'] ?? 'N/A';
Timestamp? assignmentTimestamp = historyData?['assignedDate'];
String assignmentDate = assignmentTimestamp != null
    ? "${assignmentTimestamp.toDate().day}/${assignmentTimestamp.toDate().month}/${assignmentTimestamp.toDate().year} à ${assignmentTimestamp.toDate().hour}:${assignmentTimestamp.toDate().minute}"
    : 'N/A';


                  // In ListView.builder, remove the FutureBuilder and directly access requestData fields
return Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15),
  ),
  elevation: 5,
  margin: const EdgeInsets.symmetric(vertical: 8.0),
  child: ListTile(
    leading: CircleAvatar(
      backgroundColor: isAssigned ? Colors.green : Colors.orange,
      child: Icon(
        isAssigned ? Icons.check_circle : Icons.pending,
        color: Colors.white,
      ),
    ),
    title: Text(
      requestData?['equipmentType'] ?? "Équipement non spécifié",
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Text(
          "Demandeur: ${requestData?['name'] ?? "Inconnu"}",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Text(
          "Département: ${requestData?['department'] ?? "Inconnu"}",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        if (isAssigned)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(
                "Assigné par: ${requestData?['assignedBy'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
              const SizedBox(height: 5),
              Text(
                "Assigné à: ${requestData?['utilisateur'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              Text(
                "Date d'assignation: ${requestData?['assignedDate'] != null ? "${(requestData?['assignedDate'] as Timestamp).toDate().day}/${(requestData?['assignedDate'] as Timestamp).toDate().month}/${(requestData?['assignedDate'] as Timestamp).toDate().year} à ${(requestData?['assignedDate'] as Timestamp).toDate().hour}:${(requestData?['assignedDate'] as Timestamp).toDate().minute}" : 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
      ],
    ),
    trailing: Icon(
      isAssigned ? Icons.done : Icons.hourglass_empty,
      color: isAssigned ? Colors.green : Colors.orange,
      size: 30,
    ),
    onTap: () {
      // Handle tap action, e.g., navigate to details page
    },
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
