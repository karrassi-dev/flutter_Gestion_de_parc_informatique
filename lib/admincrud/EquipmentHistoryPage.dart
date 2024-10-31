import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EquipmentHistoryPage extends StatefulWidget {
  const EquipmentHistoryPage({Key? key}) : super(key: key);

  @override
  _EquipmentHistoryPageState createState() => _EquipmentHistoryPageState();
}

class _EquipmentHistoryPageState extends State<EquipmentHistoryPage> {
  String? selectedType;
  String? selectedEquipmentId;
  String? selectedBrandName;
  Map<String, String> equipmentMap = {};
  final List<String> typeOptions = [
    'imprimante', 'avaya', 'point d’access', 'switch', 'DVR', 'TV',
    'scanner', 'routeur', 'balanceur', 'standard téléphonique',
    'data show', 'desktop', 'laptop'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDropdown("Select Equipment Type", selectedType, typeOptions, (value) {
              setState(() {
                selectedType = value;
                selectedEquipmentId = null;
                selectedBrandName = null;
                fetchEquipmentList(value!);
              });
            }),
            const SizedBox(height: 20),
            _buildDropdown("Select Equipment by Brand", selectedBrandName, equipmentMap.values.toList(), (value) {
              setState(() {
                selectedEquipmentId = equipmentMap.keys.firstWhere((key) => equipmentMap[key] == value);
                selectedBrandName = value;
              });
            }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedEquipmentId != null ? showEquipmentHistory : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Show Equipment History", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, String? selectedItem, List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      hint: Text(hint),
      value: selectedItem,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  void fetchEquipmentList(String type) async {
    equipmentMap.clear();

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('equipment')
        .where('type', isEqualTo: type)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      final serialNumber = doc.id;
      final brandName = data?['brand'] ?? 'Unknown Brand';

      equipmentMap[serialNumber] = brandName;
    }

    setState(() {
      selectedEquipmentId = null;
      selectedBrandName = null;
    });
  }

  void showEquipmentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentHistoryDetailPage(
          equipmentId: selectedEquipmentId!,
        ),
      ),
    );
  }
}

class EquipmentHistoryDetailPage extends StatefulWidget {
  final String equipmentId;

  const EquipmentHistoryDetailPage({Key? key, required this.equipmentId}) : super(key: key);

  @override
  _EquipmentHistoryDetailPageState createState() => _EquipmentHistoryDetailPageState();
}

class _EquipmentHistoryDetailPageState extends State<EquipmentHistoryDetailPage> {
  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> filteredAssignments = [];
  DateTime? startDate;
  DateTime? endDate;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  void _fetchAssignments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('HistoryOfEquipment')
        .doc(widget.equipmentId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      assignments = List<Map<String, dynamic>>.from(data['assignments'] ?? []);
      assignments.sort((a, b) => (b['assignmentDate'] as Timestamp).compareTo(a['assignmentDate'] as Timestamp));
      _applyFilters();
    }
  }

  void _applyFilters() {
    setState(() {
      filteredAssignments = assignments.where((assignment) {
        bool matchesSearch = searchQuery.isEmpty ||
            (assignment['user'] ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
            (assignment['department'] ?? '').toLowerCase().contains(searchQuery.toLowerCase());

        final assignmentDate = (assignment['assignmentDate'] as Timestamp).toDate();
        bool matchesDate = (startDate == null || assignmentDate.isAfter(startDate!)) &&
            (endDate == null || assignmentDate.isBefore(endDate!));

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  void _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedRange != null) {
      setState(() {
        startDate = pickedRange.start;
        endDate = pickedRange.end;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment History Details"),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: "Filter by Date Range",
          ),
          // IconButton(
          //   icon: const Icon(Icons.search),
          //   onPressed: () {
          //     showSearch(
          //       context: context,
          //       delegate: AssignmentSearchDelegate(
          //         onQueryChanged: (query) {
          //           setState(() {
          //             searchQuery = query;
          //             _applyFilters();
          //           });
          //         },
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
      body: filteredAssignments.isEmpty
          ? const Center(child: Text("No history available for this equipment."))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredAssignments.length,
              itemBuilder: (context, index) {
                final assignment = filteredAssignments[index];
                final String user = assignment['user'] ?? 'Unknown User';
                final String department = assignment['department'] ?? 'Unknown Department';
                final String admin = assignment['admin'] ?? 'Unknown Admin';
                final Timestamp assignmentDate = assignment['assignmentDate'];
                final int? durationInDays = assignment['durationInDays'];
                final bool isCurrentAssignment = durationInDays == null;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      user,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCurrentAssignment ? Colors.green : Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Department: $department"),
                        Text("Assigned By: $admin"),
                        Text("Assignment Date: ${assignmentDate.toDate()}"),
                        if (!isCurrentAssignment)
                          Text("Duration: $durationInDays days", style: TextStyle(color: Colors.grey[700]))
                        else
                          const Text("Current Assignment", style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class AssignmentSearchDelegate extends SearchDelegate<String> {
  final ValueChanged<String> onQueryChanged;

  AssignmentSearchDelegate({required this.onQueryChanged});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onQueryChanged(query);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onQueryChanged(query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onQueryChanged(query);
    });
    return const SizedBox.shrink();
  }
}
