import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardCards extends StatefulWidget {
  @override
  _DashboardCardsState createState() => _DashboardCardsState();
}

class _DashboardCardsState extends State<DashboardCards> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  int totalRequests = 0;
  int pendingRequests = 0;
  String topDepartments = "";
  int userApprovedRequests = 0;
  double totalRequestsTrend = 0;
  double pendingRequestsTrend = 0;
  double userApprovedRequestsTrend = 0;
  List<double> totalRequestsTrendData = [];
  List<double> pendingRequestsTrendData = [];
  List<double> userApprovedRequestsTrendData = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(Duration(days: 1));

    try {
      final User? currentUser = _auth.currentUser;
      final userEmail = currentUser?.email;

      if (userEmail == null) {
        print("User not logged in");
        setState(() {
          isLoading = false;
        });
        return;
      }

      final snapshot = await _firestore
          .collection('equipmentRequests')
          .where('requestDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('requestDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      int total = 0;
      int pending = 0;
      int approvedByUser = 0;
      Map<String, int> departmentCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        total++;

        if (data['status'] == 'Pending') {
          pending++;
        }

        if (data['status'] == 'Approved' && data['assignedByEmail'] == userEmail) {
          approvedByUser++;
        }

        String department = data['department'] ?? 'Unknown';
        departmentCounts[department] = (departmentCounts[department] ?? 0) + 1;
      }

      final sortedDepartments = departmentCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topDepartmentsList = sortedDepartments.take(3).map((e) => '${e.key}: ${e.value}').join(', ');

      setState(() {
        isLoading = false;
        totalRequests = total;
        pendingRequests = pending;
        topDepartments = topDepartmentsList;
        userApprovedRequests = approvedByUser;
        totalRequestsTrend = 10.5; // Placeholder trend data
        pendingRequestsTrend = -5.0; // Placeholder trend data
        userApprovedRequestsTrend = 15.0; // Placeholder trend data
        totalRequestsTrendData = [40, 50]; // Placeholder trend data
        pendingRequestsTrendData = [15, 20]; // Placeholder trend data
        userApprovedRequestsTrendData = [10, 15]; // Placeholder trend data
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching data: $e');
    }
  }

  Widget buildSparkline(List<double> data, bool isPositive) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                .toList(),
            isCurved: true,
            color: isPositive ? Colors.green : Colors.red,
            barWidth: 2,
            belowBarData: BarAreaData(
              show: true,
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.3),
            ),
          ),
        ],
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardData = [
      {
        "title": "Total Equipment Requests",
        "value": totalRequests,
        "trend": totalRequestsTrend,
        "trendData": totalRequestsTrendData,
        "color": Colors.orange,
        "icon": Icons.description,
      },
      {
        "title": "Pending Approvals",
        "value": pendingRequests,
        "trend": pendingRequestsTrend,
        "trendData": pendingRequestsTrendData,
        "color": Colors.amber,
        "icon": Icons.hourglass_empty,
      },
      {
        "title": "Top 3 Departments",
        "value": topDepartments,
        "trend": 0.0,
        "trendData": [],
        "color": Colors.blue,
        "icon": Icons.group,
      },
      {
        "title": "You Approved",
        "value": userApprovedRequests,
        "trend": userApprovedRequestsTrend,
        "trendData": userApprovedRequestsTrendData,
        "color": Colors.green,
        "icon": Icons.build,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;

        return isLoading
            ? Center(child: CircularProgressIndicator())
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: constraints.maxWidth > 600 ? 2.5 : 1.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: cardData.length,
                itemBuilder: (context, index) {
                  final data = cardData[index];
                  final isPositiveTrend = (data["trend"] as double) >= 0;

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: (data["color"] as Color).withOpacity(0.2),
                                child: Icon(
                                  data["icon"] as IconData,
                                  color: data["color"] as Color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data["title"] as String,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (index != 2) ...[
                            const SizedBox(height: 8),
                            Text(
                              "${data["value"]}",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Icon(
                                  isPositiveTrend ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isPositiveTrend ? Colors.green : Colors.red,
                                  size: 18,
                                ),
                                Text(
                                  "${data["trend"]}% Since last month",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isPositiveTrend ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            if ((data["trendData"] as List).isNotEmpty)
                              SizedBox(
                                height: 30,
                                child: buildSparkline(data["trendData"] as List<double>, isPositiveTrend),
                              ),
                          ] else
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                data["value"] as String,
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
      },
    );
  }
}
