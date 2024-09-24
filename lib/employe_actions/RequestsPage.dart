import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestsPage extends StatefulWidget {
  @override
  _RequestsPageState createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final String? adminEmail = FirebaseAuth.instance.currentUser?.email;
  List<DocumentSnapshot> availableEquipment = [];
  String? selectedEquipment;

  @override
  void initState() {
    super.initState();
    _fetchAvailableEquipment();
  }

  Future<void> _fetchAvailableEquipment() async {
    try {
      final QuerySnapshot equipmentSnapshot =
          await FirebaseFirestore.instance.collection('equipment').get();

      setState(() {
        availableEquipment = equipmentSnapshot.docs;
      });
    } catch (e) {
      print("Error fetching equipment: $e");
    }
  }

  void _showAssignEquipmentDialog(String requestId, String utilisateur) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Assign Equipment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select equipment to assign:"),
              const SizedBox(height: 10),
              DropdownButton<String>(
                hint: const Text("Select Equipment"),
                value: selectedEquipment,
                items: availableEquipment.map((DocumentSnapshot document) {
                  final equipmentData = document.data() as Map<String, dynamic>;
                  return DropdownMenuItem<String>(
                    value: document.id, // The equipment ID
                    child: Text(
                      "${equipmentData['brand']} - ${equipmentData['reference']} (${equipmentData['type']})",
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEquipment = value; // Set the selected equipment
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Assign"),
              onPressed: () {
                Navigator.of(context).pop();
                _assignEquipmentToRequest(requestId, utilisateur); // Assign the equipment
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _assignEquipmentToRequest(
      String requestId, String utilisateur) async {
    if (selectedEquipment == null) return; // Ensure an equipment is selected

    try {
      final DocumentSnapshot equipmentDoc = await FirebaseFirestore.instance
          .collection('equipment')
          .doc(selectedEquipment)
          .get();

      final equipmentData = equipmentDoc.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance
          .collection('equipmentRequests')
          .doc(requestId)
          .update({
        'assignedEquipment': selectedEquipment, // Store the selected equipment ID
        'assignedEquipmentDetails': {
          'brand': equipmentData['brand'],
          'reference': equipmentData['reference'],
          'serial_number': equipmentData['serial_number'],
        },
        'isAssigned': true, // Mark the request as assigned
      });

      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(selectedEquipment)
          .update({
        'user': utilisateur,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Equipment assigned successfully!")),
      );

      // Clear the selected equipment after assignment
      setState(() {
        selectedEquipment = null;
      });
    } catch (e) {
      print("Error assigning equipment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error assigning equipment: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment Requests"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('equipmentRequests')
            .orderBy('requestDate', descending: true)
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
              final requestData = request.data() as Map<String, dynamic>;

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
                        "Equipment Type: ${requestData['equipmentType']}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Requested by: ${requestData['requester']}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Department: ${requestData['department']}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Request Date: ${requestData['requestDate'].toDate().toLocal().toString()}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: requestData['isAssigned'] == true
                                ? null // Disable if already assigned
                                : () {
                                    _showAssignEquipmentDialog(
                                      request.id,
                                      requestData['utilisateur'],
                                    );
                                  },
                            child: const Text("Affecter Equipment"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('equipmentRequests')
                                  .doc(request.id)
                                  .update({
                                'isRead': true,
                              });

                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Request Details"),
                                  content: SingleChildScrollView(
                                    child: ListBody(
                                      children: [
                                        Text(
                                            "Equipment: ${requestData['equipmentType']}"),
                                        Text(
                                            "Requested by: ${requestData['requester']}"),
                                        Text(
                                            "Department: ${requestData['department']}"),
                                        Text(
                                            "Request Date: ${requestData['requestDate'].toDate().toLocal().toString()}"),
                                        Text(
                                            "Status: ${requestData['status'] ?? 'Pending'}"),
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