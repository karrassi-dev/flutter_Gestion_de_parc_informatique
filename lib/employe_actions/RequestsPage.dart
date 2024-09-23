import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestsPage extends StatefulWidget {
  @override
  _RequestsPageState createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final String? adminEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment Requests"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('equipment_requests')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No requests available"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final request = snapshot.data!.docs[index];
              final isAccepted = request['status'] == 'accepted';
              final requestData = request.data() as Map<String, dynamic>?; 

              return Card(
                elevation: 3,
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Equipment: ${request['equipmentName']}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Requested by: ${request['requester']}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Timestamp: ${request['timestamp'].toDate().toLocal().toString()}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: isAccepted
                                ? null
                                : () async {
                                    try {
                                      // Accept request and store admin email
                                      await FirebaseFirestore.instance
                                          .collection('equipment_requests')
                                          .doc(request.id)
                                          .update({
                                        'status': 'accepted',
                                        'acceptedBy': adminEmail,
                                        'isRead': true,
                                      });

                                      setState(() {}); 

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Request accepted successfully!"),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              "Failed to accept request: $e"),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                            child: Text(isAccepted ? "Accepted" : "Accept"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAccepted
                                  ? Colors.green
                                  : Colors.white, 
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              // Delete the request from Firestore
                              await FirebaseFirestore.instance
                                  .collection('equipment_requests')
                                  .doc(request.id)
                                  .delete(); // Delete from Firestore
                            },
                            child: const Text("Delete"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Show details in a dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Request Details"),
                                  content: SingleChildScrollView(
                                    child: ListBody(
                                      children: [
                                        Text(
                                            "Equipment: ${request['equipmentName']}"),
                                        Text(
                                            "Requested by: ${request['requester']}"),
                                        Text(
                                            "Timestamp: ${request['timestamp'].toDate().toLocal().toString()}"),
                                        Text(
                                            "Status: ${request['status'] ?? 'Pending'}"),
                                        Text(
                                            "Accepted By: ${requestData != null && requestData.containsKey('acceptedBy') ? request['acceptedBy'] : 'N/A'}"), 
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text("Close"),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text("Show Details"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
