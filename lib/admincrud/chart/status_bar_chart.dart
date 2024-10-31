import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatusBarChart extends StatelessWidget {
  final Map<String, int> data;

  StatusBarChart(this.data);

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barGroups = data.entries.map((entry) {
      return BarChartGroupData(
        x: data.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            width: 15,
            color: Colors.blueAccent,
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Get status labels based on index
                final statuses = data.keys.toList();
                return Text(
                  statuses[value.toInt()],
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                );
              },
            ),
          ),
        ),
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
      ),
    );
  }
}
