import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class RequestsChart extends StatefulWidget {
  @override
  _RequestsChartState createState() => _RequestsChartState();
}

class _RequestsChartState extends State<RequestsChart> {
  Map<String, int> monthlyData = {};
  Map<String, int> weeklyData = {};
  bool isLoading = true;
  String timeFrame = 'monthly';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final now = DateTime.now();
    final requestCounts = {'monthly': <String, int>{}, 'weekly': <String, int>{}};

    // Initialize keys for the last 6 months (month and year only)
    for (int i = 0; i < 6; i++) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthKey = "${monthDate.month}-${monthDate.year}";
      requestCounts['monthly']![monthKey] = 0;
    }

    // Initialize keys for the last 7 days (day and month only)
    for (int i = 0; i < 7; i++) {
      final weekDate = now.subtract(Duration(days: i));
      final weekKey = "${weekDate.day}-${weekDate.month}";
      requestCounts['weekly']![weekKey] = 0;
    }

    // Fetch all requests from Firestore
    final querySnapshot = await FirebaseFirestore.instance.collection('equipmentRequests').get();

    // Populate monthly and weekly request counts
    for (var doc in querySnapshot.docs) {
      final requestDate = (doc.data()['requestDate'] as Timestamp).toDate();
      final monthKey = "${requestDate.month}-${requestDate.year}"; // Month and year only for monthly data
      final weekKey = "${requestDate.day}-${requestDate.month}";  // Day and month only for weekly data

      if (requestCounts['monthly']!.containsKey(monthKey)) {
        requestCounts['monthly']![monthKey] = requestCounts['monthly']![monthKey]! + 1;
      }
      if (requestCounts['weekly']!.containsKey(weekKey)) {
        requestCounts['weekly']![weekKey] = requestCounts['weekly']![weekKey]! + 1;
      }
    }

    setState(() {
      monthlyData = requestCounts['monthly']!;
      weeklyData = requestCounts['weekly']!;
      isLoading = false;
    });
  }

  List<FlSpot> generateChartData(Map<String, int> data) {
    List<String> keys = data.keys.toList().reversed.toList();
    List<int> values = data.values.toList().reversed.toList();

    return List<FlSpot>.generate(keys.length, (index) {
      return FlSpot(index.toDouble(), values[index].toDouble());
    });
  }

  void _showFullScreenChart(BuildContext context) {
    final selectedData = timeFrame == 'monthly' ? monthlyData : weeklyData;
    final spots = generateChartData(selectedData);
    final labels = selectedData.keys.toList().reversed.toList();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            height: MediaQuery.of(context).size.height * 0.6,  // Adjusted height for better view
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: "Close",
                    ),
                  ],
                ),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.blueAccent,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 5,
                              color: Colors.blueAccent,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blueAccent.withOpacity(0.15),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final index = value.toInt();
                              return Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text(
                                  index >= 0 && index < labels.length ? labels[index] : '',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                              );
                            },
                            interval: 1,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: timeFrame != 'monthly',  // Hide left titles only for monthly view
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        drawHorizontalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 0.8,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 0.8,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedData = timeFrame == 'monthly' ? monthlyData : weeklyData;
    final spots = generateChartData(selectedData);
    final labels = selectedData.keys.toList().reversed.toList();

    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => timeFrame = 'monthly'),
                        child: Text(
                          'Monthly',
                          style: TextStyle(
                            color: timeFrame == 'monthly' ? Colors.blue : Colors.black,
                            fontWeight: timeFrame == 'monthly' ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => timeFrame = 'weekly'),
                        child: Text(
                          'Weekly',
                          style: TextStyle(
                            color: timeFrame == 'weekly' ? Colors.blue : Colors.black,
                            fontWeight: timeFrame == 'weekly' ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.fullscreen, color: Colors.blueAccent),
                    onPressed: () => _showFullScreenChart(context),
                    tooltip: "Expand",
                  ),
                ],
              ),
              SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 3,
                        color: Colors.blueAccent,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blueAccent,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blueAccent.withOpacity(0.15),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final index = value.toInt();
                            return Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                index >= 0 && index < labels.length ? labels[index] : '',
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                            );
                          },
                          interval: 1,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: timeFrame != 'monthly',  // Hide left titles only for monthly view
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 1,
                      verticalInterval: 1,
                      drawHorizontalLine: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 0.8,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 0.8,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}
