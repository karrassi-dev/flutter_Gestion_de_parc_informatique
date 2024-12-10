import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestsPage extends StatefulWidget {
  @override
  _RequestsPageState createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final String? adminEmail = FirebaseAuth.instance.currentUser?.email;
  List<DocumentSnapshot> availableEquipment = [];
  String? selectedType;
  String? selectedEquipment;
  bool? isReadFilter;
  bool? isAssignedFilter;
  bool dateDescending = true;
  String? equipmentTypeFilter;

  final List<String> equipmentTypes = [
    'Imprimante',
    'Avaya',
    'Point d’access',
    'Switch',
    'DVR',
    'TV',
    'Scanner',
    'Routeur',
    'Balanceur',
    'Standard Téléphonique',
    'Data Show',
    'Desktop',
    'Laptop',
    'Notebook'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAvailableEquipment(); // Initial load without type filter
  }

  /// Fetch available equipment of a specific type with status "Available"
  Future<void> _fetchAvailableEquipment({String? type}) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('equipment')
          .where('status', isEqualTo: 'Available'); // Filter by status

      if (type != null) {
        query =
            query.where('type', isEqualTo: type); // Filter by type if provided
      }

      QuerySnapshot equipmentSnapshot = await query.get();

      setState(() {
        availableEquipment = equipmentSnapshot.docs;
        selectedEquipment = null;
      });
    } catch (e) {
      print("Error fetching equipment: $e");
    }
  }

  void _showCompleteMaintenanceDialog(String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Completion"),
          content: const Text(
            "Are you sure you want to mark this maintenance request as completed?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _completeMaintenance(requestId);
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeMaintenance(String requestId) async {
    try {
      // Update the request status in Firebase
      await FirebaseFirestore.instance
          .collection('equipmentRequests')
          .doc(requestId)
          .update({
        'status': 'Available',
        'maintenanceType': false, // Reset maintenanceType if needed
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maintenance marked as completed!")),
      );

      setState(() {}); // Refresh the UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error completing maintenance: $e")),
      );
    }
  }

  /// Show a dialog to assign equipment to a request
  void _showAssignEquipmentDialog(
      String requestId, String utilisateur, String department) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Assign Equipment",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      Text("Utilisateur: $utilisateur"),
                      const SizedBox(height: 10),
                      const Text("Select equipment to assign:"),
                      const SizedBox(height: 10),
                      // Equipment Type Dropdown
                      DropdownButtonFormField<String>(
                        hint: const Text("Select Equipment Type"),
                        value: selectedType,
                        onChanged: (value) async {
                          setState(() {
                            selectedType = value;
                          });
                          await _fetchAvailableEquipment(type: value);
                          setDialogState(() {
                            selectedEquipment =
                                null; // Reset selected equipment
                          });
                        },
                        items: equipmentTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      // Select Equipment Dropdown
                      DropdownButtonFormField<String>(
                        hint: const Text("Select Equipment"),
                        value: selectedEquipment,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedEquipment = value;
                          });
                        },
                        items: availableEquipment.map((document) {
                          final equipmentData =
                              document.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: document.id,
                            child: Text(
                              "${equipmentData['brand']} - (${equipmentData['type']})",
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          ElevatedButton(
                            child: const Text("Assign"),
                            onPressed: selectedEquipment != null
                                ? () async {
                                    Navigator.of(context).pop();
                                    await _assignEquipmentToRequest(
                                        requestId, utilisateur, department);
                                    await FirebaseFirestore.instance
                                        .collection('equipmentRequests')
                                        .doc(requestId)
                                        .update({
                                      'isRead': true,
                                      'status': 'Approved',
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Assign equipment to the request
  Future<void> _assignEquipmentToRequest(
      String requestId, String utilisateur, String department) async {
    if (selectedEquipment == null) return;

    try {
      final DocumentSnapshot equipmentDoc = await FirebaseFirestore.instance
          .collection('equipment')
          .doc(selectedEquipment)
          .get();

      final equipmentData = equipmentDoc.data() as Map<String, dynamic>;
      final String previousUser = equipmentData['user'] ?? 'No previous user';
      final Timestamp? lastAssignedDate = equipmentData['lastAssignedDate'];
      final String? previousAdmin = equipmentData['assignedBy'];

      final DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection('equipmentRequests')
          .doc(requestId)
          .get();

      final requestData = requestDoc.data() as Map<String, dynamic>;
      final String site = requestData['site'];

      Timestamp now = Timestamp.now();

      // Update equipmentRequests with assignment details
      await FirebaseFirestore.instance
          .collection('equipmentRequests')
          .doc(requestId)
          .update({
        'assignedEquipment': selectedEquipment,
        'assignedEquipmentDetails': {
          'brand': equipmentData['brand'],
          'reference': equipmentData['reference'],
          'serial_number': equipmentData['serial_number'],
        },
        'isAssigned': true,
        'assignedBy': adminEmail,
        'assignedByEmail': FirebaseAuth.instance.currentUser?.email,
        'assignedDate': now,
      });

      // Update equipment collection
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(selectedEquipment)
          .update({
        'user': utilisateur,
        'department': department,
        'site': site,
        'assignedBy': adminEmail,
        'lastAssignedDate': now,
        'status': 'Assigned', 
      });

      
      if (lastAssignedDate != null) {
        final int durationInDays =
            now.toDate().difference(lastAssignedDate.toDate()).inDays;

        await FirebaseFirestore.instance
            .collection('HistoryOfEquipment')
            .doc(equipmentData['serial_number'])
            .set({
          'assignments': FieldValue.arrayUnion([
            {
              'user': previousUser,
              'department': equipmentData['department'],
              'admin': previousAdmin ?? 'Unknown',
              'assignmentDate': lastAssignedDate,
              'durationInDays': durationInDays,
            }
          ])
        }, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Equipment assigned successfully!")),
      );

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

  /// Filters are applied here
  void _applyFilters() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment Requests"),
        backgroundColor: Color(0xFF467F67),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                DropdownButton<bool?>(
                  value: isReadFilter,
                  hint: const Text("Filter by Read"),
                  onChanged: (value) {
                    setState(() {
                      isReadFilter = value;
                    });
                  },
                  items: const [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text("All"),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Text("Read"),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Text("Unread"),
                    ),
                  ],
                ),
                DropdownButton<bool?>(
                  value: isAssignedFilter,
                  hint: const Text("Filter by Assigned"),
                  onChanged: (value) {
                    setState(() {
                      isAssignedFilter = value;
                    });
                  },
                  items: const [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text("All"),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Text("Assigned"),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Text("Unassigned"),
                    ),
                  ],
                ),
                DropdownButton<String?>(
                  hint: const Text("Equipment Type"),
                  value: equipmentTypeFilter,
                  onChanged: (value) {
                    setState(() {
                      equipmentTypeFilter = value;
                    });
                  },
                  items: equipmentTypes
                      .map((type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                ),
                IconButton(
                  icon: Icon(
                    dateDescending ? Icons.arrow_downward : Icons.arrow_upward,
                  ),
                  onPressed: () {
                    setState(() {
                      dateDescending = !dateDescending;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text("Apply Filters"),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('equipmentRequests')
                  .orderBy('requestDate', descending: dateDescending)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No requests available"));
                }

                List<DocumentSnapshot> filteredRequests = snapshot.data!.docs;

                if (isReadFilter != null) {
                  filteredRequests = filteredRequests.where((doc) {
                    return (doc.data() as Map<String, dynamic>)
                            .containsKey('isRead') &&
                        (doc['isRead'] == isReadFilter);
                  }).toList();
                }

                if (isAssignedFilter != null) {
                  filteredRequests = filteredRequests.where((doc) {
                    return (doc.data() as Map<String, dynamic>)
                            .containsKey('isAssigned') &&
                        (doc['isAssigned'] == isAssignedFilter);
                  }).toList();
                }

                if (equipmentTypeFilter != null) {
                  filteredRequests = filteredRequests.where((doc) {
                    return (doc.data() as Map<String, dynamic>)
                            .containsKey('equipmentType') &&
                        (doc['equipmentType'] == equipmentTypeFilter);
                  }).toList();
                }

                return ListView.builder(
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final request = filteredRequests[index];
                    final requestData = request.data() as Map<String, dynamic>;

                    final bool isMaintenance =
                        requestData['maintenanceType'] == true;
                    final bool isAvailable =
                        requestData['status'] == 'Available';

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: isAvailable
                          ? Colors.green
                              .shade100 // Different color for completed requests
                          : isMaintenance
                              ? Colors.orange
                                  .shade100 // Different color for maintenance
                              : Colors.white,
                      child: ListTile(
                        leading: isMaintenance
                            ? const Icon(Icons.build, color: Colors.orange)
                            : const Icon(Icons.device_unknown,
                                color: Colors.blue),
                        title: Text(
                          requestData['name'] ?? '',
                          style: TextStyle(
                            fontWeight: isAvailable || isMaintenance
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isAvailable
                                ? Colors.green.shade800
                                : isMaintenance
                                    ? Colors.orange.shade800
                                    : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Status: ${requestData['status']}"),
                            Text(
                                "Requested on: ${requestData['requestDate'].toDate()}"),
                            if (isMaintenance)
                              Text(
                                "Maintenance Type: ${requestData['equipmentType']}",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            if (!isMaintenance)
                              Text("Type: ${requestData['equipmentType']}"),
                          ],
                        ),
                        trailing: isAvailable
                            ? const Text(
                                "Completed",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : isMaintenance
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    onPressed: () =>
                                        _showCompleteMaintenanceDialog(
                                            request.id),
                                    child: const Text("Complete Maintenance"),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          requestData['isAssigned'] == true
                                              ? Colors.green
                                              : Colors.blue,
                                    ),
                                    onPressed: requestData['isAssigned'] == true
                                        ? null
                                        : () => _showAssignEquipmentDialog(
                                            request.id,
                                            requestData['utilisateur'],
                                            requestData['department']),
                                    child: Text(
                                        requestData['isAssigned'] == true
                                            ? "Assigned"
                                            : "Assign Equipment"),
                                  ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

