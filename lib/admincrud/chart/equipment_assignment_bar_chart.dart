import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EquipmentAssignmentBarChart extends StatelessWidget {
  final Map<String, int> assignmentData;

  EquipmentAssignmentBarChart(this.assignmentData);

  @override
  Widget build(BuildContext context) {
    // Convert assignment data into lists
    List<String> departments = assignmentData.keys.toList();
    List<int> values = assignmentData.values.toList();

    // Handle empty or negative values
    if (values.isEmpty || values.any((value) => value < 0)) {
      return Center(child: Text("No valid data available."));
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < departments.length; i++) {
      barGroups.add(BarChartGroupData(
        x: i, // Use a simple integer index for x
        barRods: [
          BarChartRodData(
            toY: values[i].toDouble(),
            color: _getColorForDepartment(departments[i]),
            width: 30,
          ),
        ],
      ));
    }

    return Column(
      children: [
        BarChart(
          BarChartData(
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 38,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      departments[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            barGroups: barGroups,
          ),
        ),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(departments.length, (index) {
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: _getColorForDepartment(departments[index]),
                  ),
                  const SizedBox(width: 4),
                  Text(departments[index]),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Color _getColorForDepartment(String department) {
    switch (department) {
      case 'Administration':
        return Colors.blue;
      case 'Audit':
        return Colors.green;
      case 'IT':
        return Colors.orange;
      case 'HR':
        return Colors.red;
      // Add more cases as needed for different departments
      default:
        return Colors.grey; // Fallback color
    }
  }
}
