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
    'laptop',
    'Notebook'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAvailableEquipment();
  }

  Future<void> _fetchAvailableEquipment({String? type}) async {
    try {
      QuerySnapshot equipmentSnapshot = await FirebaseFirestore.instance
          .collection('equipment')
          .where('type', isEqualTo: type)
          .get();

      setState(() {
        availableEquipment = equipmentSnapshot.docs;
        selectedEquipment = null;
      });
    } catch (e) {
      print("Error fetching equipment: $e");
    }
  }

  void _showAssignEquipmentDialog(
      String requestId, String utilisateur, String department) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
  builder: (context, setDialogState) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20), // Reduced horizontal padding to give more width
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.95, // Set dialog width to 95% of screen width
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Assign Equipment",
                  style: Theme.of(context).textTheme.titleLarge, // Updated to titleLarge
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
                      selectedEquipment = null; // Reset selected equipment
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
                    final equipmentData = document.data() as Map<String, dynamic>;
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
                              await _assignEquipmentToRequest(requestId, utilisateur, department);
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
      ),
    );
  },
);

      },
    );
  }

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
      });

      // Store previous user history if a previous assignment exists
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

  Future<void> _storeAssignmentInHistory(String serialNumber, String user,
      String department, String adminEmail) async {
    try {
      final documentRef = FirebaseFirestore.instance
          .collection('HistoryOfEquipment')
          .doc(serialNumber);

      final assignmentEntry = {
        'user': user,
        'department': department,
        'admin': adminEmail,
        'assignmentDate': Timestamp.now(),
        'durationInDays': null,
      };

      await documentRef.set({
        'assignments': FieldValue.arrayUnion([assignmentEntry]),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error storing assignment history: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error storing assignment history: $e")),
      );
    }
  }

  void _applyFilters() {
    setState(() {});
  }

  // Main widget build
  // ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment Requests"),
        backgroundColor: Colors.deepPurple,
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
                  items: [
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
                    'Laptop'
                  ]
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

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(requestData['name'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Status: ${requestData['status']}"),
                            Text(
                                "Requested on: ${requestData['requestDate'].toDate()}"),
                            Text("User: ${requestData['utilisateur']}"),
                            Text("Type: ${requestData['equipmentType']}"),
                            if (requestData['isAssigned'] == true) ...[
                              const Text("Assigned",
                                  style: TextStyle(color: Colors.green)),
                              Text(
                                  "Assigned By: ${requestData['assignedByEmail'] ?? 'Unknown'}"),
                            ],
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: requestData['isAssigned'] == true
                                ? Colors.green
                                : Colors.blue,
                          ),
                          onPressed: requestData['isAssigned'] == true
                              ? null
                              : () => _showAssignEquipmentDialog(
                                  request.id,
                                  requestData['utilisateur'],
                                  requestData['department']),
                          child: Text(requestData['isAssigned'] == true
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




/*import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool? isReadFilter;
  bool? isAssignedFilter;
  bool dateDescending = true;
  String? equipmentTypeFilter;

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

  void _showAssignEquipmentDialog(String requestId, String utilisateur, String department) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Assign Equipment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Utilisateur: $utilisateur"),
              const SizedBox(height: 10),
              const Text("Select equipment to assign:"),
              const SizedBox(height: 10),
              DropdownButton<String>(
                hint: const Text("Select Equipment"),
                value: selectedEquipment,
                items: availableEquipment.map((DocumentSnapshot document) {
                  final equipmentData = document.data() as Map<String, dynamic>;
                  return DropdownMenuItem<String>(
                    value: document.id,
                    child: Text(
                      "${equipmentData['brand']} - (${equipmentData['type']})",
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEquipment = value;
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _assignEquipmentToRequest(requestId, utilisateur, department);

                await FirebaseFirestore.instance
                    .collection('equipmentRequests')
                    .doc(requestId)
                    .update({
                  'isRead': true,
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _assignEquipmentToRequest(String requestId, String utilisateur, String department) async {
  if (selectedEquipment == null) return;

  try {
    final DocumentSnapshot equipmentDoc = await FirebaseFirestore.instance
        .collection('equipment')
        .doc(selectedEquipment)
        .get();

    final equipmentData = equipmentDoc.data() as Map<String, dynamic>;
    final String previousUser = equipmentData['user'] ?? 'No previous user';
    final Timestamp? lastAssignedDate = equipmentData['lastAssignedDate']; // The date when the equipment was last assigned

    final DocumentSnapshot requestDoc = await FirebaseFirestore.instance
        .collection('equipmentRequests')
        .doc(requestId)
        .get();

    final requestData = requestDoc.data() as Map<String, dynamic>;
    final String site = requestData['site'];

    Timestamp now = Timestamp.now();

    // Updating the new assignment
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

    // Update equipment collection with new user details
    await FirebaseFirestore.instance
        .collection('equipment')
        .doc(selectedEquipment)
        .update({
      'user': utilisateur,
      'department': department,
      'site': site,
      'lastAssignedDate': now,
    });

    // Calculate duration and add history for previous user if there was a previous assignment
    if (lastAssignedDate != null) {
      final int durationInDays =
          now.toDate().difference(lastAssignedDate.toDate()).inDays;

      // Add history entry with duration for previous user
      await FirebaseFirestore.instance
          .collection('HistoryOfEquipment')
          .doc(equipmentData['serial_number'])
          .set({
        'assignments': FieldValue.arrayUnion([
          {
            'user': previousUser,
            'department': equipmentData['department'],
            'admin': equipmentData['assignedBy'] ?? 'Unknown',
            'assignmentDate': lastAssignedDate,
            'durationInDays': durationInDays, // Adding duration for the previous user
          }
        ])
      }, SetOptions(merge: true));
    }

    // Store current assignment in history
    await _storeAssignmentInHistory(
      equipmentData['serial_number'],
      utilisateur,
      department,
      adminEmail!,
    );

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

Future<void> _storeAssignmentInHistory(
    String serialNumber, String user, String department, String adminEmail) async {
  try {
    final documentRef = FirebaseFirestore.instance
        .collection('HistoryOfEquipment')
        .doc(serialNumber);

    final assignmentEntry = {
      'user': user,
      'department': department,
      'admin': adminEmail,
      'assignmentDate': Timestamp.now(),
      'durationInDays': null, // New user has no duration initially
    };

    await documentRef.set({
      'assignments': FieldValue.arrayUnion([assignmentEntry]),
    }, SetOptions(merge: true));
  } catch (e) {
    print("Error storing assignment history: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error storing assignment history: $e")),
    );
  }
}

  void _applyFilters() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment Requests"),
        backgroundColor: Colors.deepPurple,
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
                  items: ['Imprimante', 'Avaya', 'Point d’access', 'Switch', 'DVR', 'TV', 'Scanner', 
                            'Routeur', 'Balanceur', 'Standard Téléphonique', 'Data Show', 'Desktop', 'Laptop']
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
                    return (doc.data() as Map<String, dynamic>).containsKey('isRead') &&
                           (doc['isRead'] == isReadFilter);
                  }).toList();
                }

                if (isAssignedFilter != null) {
                  filteredRequests = filteredRequests.where((doc) {
                    return (doc.data() as Map<String, dynamic>).containsKey('isAssigned') &&
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

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(requestData['name'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Status: ${requestData['status']}"),
                            Text(
                                "Requested on: ${requestData['requestDate'].toDate()}"),
                            Text(
                                "User: ${requestData['utilisateur']}"),
                            Text(
                                "Type: ${requestData['equipmentType']}"),
                            if (requestData['isAssigned'] == true) ...[
                              const Text("Assigned",
                                  style: TextStyle(color: Colors.green)),
                              Text(
                                  "Assigned By: ${requestData['assignedByEmail'] ?? 'Unknown'}"),
                            ],
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: requestData['isAssigned'] == true ? Colors.green : Colors.blue,
                          ),
                          onPressed: requestData['isAssigned'] == true
                              ? null
                              : () => _showAssignEquipmentDialog(request.id, requestData['utilisateur'], requestData['department']),
                          child: Text(requestData['isAssigned'] == true ? "Assigned" : "Assign Equipment"),
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
*/