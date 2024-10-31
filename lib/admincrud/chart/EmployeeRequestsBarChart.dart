import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EmployeeRequestsBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Define a maximum width for the bar chart based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth = screenWidth * 0.05; // Adjust the width of the bars

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AspectRatio(
        aspectRatio: 1.5, // Aspect ratio to keep chart responsive
        child: BarChart(
          BarChartData(
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    const employees = ['Alice', 'Bob', 'Charlie', 'David'];
                    if (value.toInt() < employees.length) {
                      return Text(
                        employees[value.toInt()],
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            barGroups: _generateBarGroups(barWidth),
            gridData: FlGridData(show: false),
            alignment: BarChartAlignment.spaceAround,
            maxY: 20,
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(double barWidth) {
    return [
      BarChartGroupData(
        x: 0,
        barRods: [BarChartRodData(toY: 10, width: barWidth, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [BarChartRodData(toY: 8, width: barWidth, color: Colors.green)],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [BarChartRodData(toY: 15, width: barWidth, color: Colors.orange)],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [BarChartRodData(toY: 5, width: barWidth, color: Colors.purple)],
      ),
    ];
  }
}
