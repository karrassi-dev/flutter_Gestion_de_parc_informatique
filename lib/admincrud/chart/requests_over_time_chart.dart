import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RequestsOverTimeChart extends StatefulWidget {
  @override
  _RequestsOverTimeChartState createState() => _RequestsOverTimeChartState();
}

class _RequestsOverTimeChartState extends State<RequestsOverTimeChart> {
  String selectedRange = 'Last 10 Days'; // Default selection
  List<FlSpot> spots = [];
  DateTime startDate = DateTime.now(); // Class-level variable for start date

  @override
  void initState() {
    super.initState();
    _fetchAndGenerateSpots(); // Fetch initial data for the default range
  }

  Future<void> _fetchAndGenerateSpots() async {
    DateTime now = DateTime.now();

    // Determine the start date based on the selected range
    if (selectedRange == 'Last 10 Days') {
      startDate = now.subtract(Duration(days: 10));
    } else if (selectedRange == 'Last Week') {
      startDate = now.subtract(Duration(days: 7));
    } else if (selectedRange == 'Last Month') {
      startDate = DateTime(now.year, now.month - 1, now.day);
    }

    spots.clear(); // Clear previous spots

    // Fetch data from Firestore
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('equipmentRequests')
        .where('requestDate', isGreaterThan: startDate)
        .orderBy('requestDate')
        .get();

    snapshot.docs.forEach((doc) {
      Timestamp timestamp = doc['requestDate'];
      DateTime requestDate = timestamp.toDate();
      double xValue = requestDate.difference(startDate).inDays.toDouble();
      double yValue = 1; // You can adjust this based on your requirements

      spots.add(FlSpot(xValue, yValue));
    });

    setState(() {}); // Trigger a rebuild with the new data
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedRange,
              items: ['Last 10 Days', 'Last Week', 'Last Month']
                  .map((String value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedRange = newValue;
                    _fetchAndGenerateSpots(); // Update spots when range changes
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 20), // Space between dropdown and chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: AspectRatio(
              aspectRatio: 1.5, // Adjust aspect ratio for responsiveness
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          DateTime date = startDate.add(Duration(days: value.toInt()));
                          return Text(DateFormat('MM/dd').format(date), style: TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey, width: 1)),
                  gridData: FlGridData(show: true, drawVerticalLine: true, drawHorizontalLine: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue, // Set the color directly
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)), // Area under the line
                      dotData: FlDotData(show: true), // Show dots on data points
                      barWidth: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
