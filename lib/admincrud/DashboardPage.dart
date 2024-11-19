import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './chart/equipment_type_pie_chart.dart';
import './chart/status_bar_chart.dart';
import './chart/requester_bar_chart.dart';
import './chart/RequestsChart.dart';
import './chart/DashboardCards.dart'; // Import DashboardCards

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? selectedType;

  Future<Map<String, dynamic>> fetchFilteredChartData(String? typeFilter) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('equipmentRequests').get();
    List<Map<String, dynamic>> requests = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    Map<String, int> equipmentTypeCounts = {};
    Map<String, int> statusCounts = {};
    Map<String, int> requesterCounts = {};
    Map<String, int> requestsOverTime = {};

    for (var request in requests) {
      String equipmentType = request['equipmentType'] ?? 'Unknown';
      if (typeFilter != null && equipmentType != typeFilter) continue;

      equipmentTypeCounts[equipmentType] = (equipmentTypeCounts[equipmentType] ?? 0) + 1;
      String status = request['status'] ?? 'Unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      String requester = request['requester'] ?? 'Unknown';
      requesterCounts[requester] = (requesterCounts[requester] ?? 0) + 1;

      String requestMonth = (request['requestDate'] as Timestamp).toDate().toString().substring(0, 7);
      requestsOverTime[requestMonth] = (requestsOverTime[requestMonth] ?? 0) + 1;
    }

    final topRequesters = (requesterCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(4).toList();
    final topRequesterEmails = topRequesters.map((entry) {
      final request = requests.firstWhere((req) => req['requester'] == entry.key, orElse: () => {});
      return request['email'] as String? ?? 'No email';
    }).toList();

    return {
      "equipmentTypeCounts": equipmentTypeCounts,
      "statusCounts": statusCounts,
      "requesterCounts": Map.fromEntries(topRequesters),
      "requestsOverTime": requestsOverTime,
      "topRequesterEmails": topRequesterEmails,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Admin Dashboard"),
      //   backgroundColor: Colors.blueAccent,
      //   elevation: 2,
      // ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchFilteredChartData(selectedType),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardCards(), // Display summary cards at the top
                const SizedBox(height: 16),

                // Chart Sections
                const Text("Requests by Equipment Type", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 300,
                  child: EquipmentTypePieChart(
                    data['equipmentTypeCounts'],
                    onSectionTapped: (type) {
                      setState(() {
                        selectedType = type.isEmpty ? null : type;
                      });
                    },
                    onLegendTapped: (type) {
                      setState(() {
                        selectedType = type.isEmpty ? null : type;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                const Text("Status of Requests", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 300, child: StatusBarChart(data['statusCounts'])),
                const SizedBox(height: 16),

                const Text("Top Requesters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 300,
                  child: RequesterBarChart(
                    data['requesterCounts'],
                    data['topRequesterEmails'] as List<String>,
                  ),
                ),
                const SizedBox(height: 16),

                const Text("Requests Over Time", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 300,
                  child: RequestsChart(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}







/*

// In your existing DashboardPage file

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './chart/requests_over_time_chart.dart';
import './chart/equipment_type_pie_chart.dart';
import './chart/status_bar_chart.dart';
import './chart/requester_bar_chart.dart';
import './chart/equipment_assignment_bar_chart.dart'; // Import the new chart

Future<Map<String, dynamic>> fetchChartData() async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('equipmentRequests')
      .get();

  List<Map<String, dynamic>> requests = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

  Map<String, int> equipmentTypeCounts = {};
  Map<String, int> statusCounts = {};
  Map<String, int> requesterCounts = {};
  Map<String, int> requestsOverTime = {}; // Modify for your preferred time grouping

  for (var request in requests) {
    String equipmentType = request['equipmentType'] ?? 'Unknown';
    equipmentTypeCounts[equipmentType] = (equipmentTypeCounts[equipmentType] ?? 0) + 1;

    String status = request['status'] ?? 'Unknown';
    statusCounts[status] = (statusCounts[status] ?? 0) + 1;

    String requester = request['requester'] ?? 'Unknown';
    requesterCounts[requester] = (requesterCounts[requester] ?? 0) + 1;

    String requestMonth = (request['requestDate'] as Timestamp).toDate().toString().substring(0, 7);
    requestsOverTime[requestMonth] = (requestsOverTime[requestMonth] ?? 0) + 1;
  }

  return {
    "equipmentTypeCounts": equipmentTypeCounts,
    "statusCounts": statusCounts,
    "requesterCounts": requesterCounts,
    "requestsOverTime": requestsOverTime,
  };
}


// In the same file as your DashboardPage or in a separate data service file

Future<Map<String, int>> fetchEquipmentAssignmentsByDepartment() async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('equipmentRequests')
      .get();

  Map<String, int> departmentCounts = {};

  for (var doc in snapshot.docs) {
    // Ensure you access the correct fields based on your data structure
    String department = doc['department'] ?? 'Unknown'; // Adjust based on your actual structure
    if (department.isNotEmpty) {
      departmentCounts[department] = (departmentCounts[department] ?? 0) + 1;
    }
  }

  // Sort the departments by count and take the top 3
  var sortedDepartments = departmentCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  Map<String, int> topDepartments = {};
  for (int i = 0; i < (sortedDepartments.length < 3 ? sortedDepartments.length : 3); i++) {
    topDepartments[sortedDepartments[i].key] = sortedDepartments[i].value;
  }

  return topDepartments;
}




class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchChartData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Requests Over Time", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 300, child: RequestsOverTimeChart()), // Existing chart
                const SizedBox(height: 20),

                const Text("Requests by Equipment Type", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 300, child: EquipmentTypePieChart(data['equipmentTypeCounts'])),
                const SizedBox(height: 20),

                const Text("Status of Requests", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 300, child: StatusBarChart(data['statusCounts'])),
                const SizedBox(height: 20),

                const Text("Top Requesters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 300, child: RequesterBarChart(data['requesterCounts'])),
                const SizedBox(height: 20),

                const Text("Top Departments by Equipment Assignment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                FutureBuilder<Map<String, int>>(
                  future: fetchEquipmentAssignmentsByDepartment(), // Fetch the top departments
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    final topDepartments = snapshot.data!;
                    return SizedBox(height: 300, child: EquipmentAssignmentBarChart(topDepartments)); // New chart
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
*/
