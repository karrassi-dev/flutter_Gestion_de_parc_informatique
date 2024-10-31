import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RequesterBarChart extends StatelessWidget {
  final Map<String, int> data;
  final List<String> emails;

  RequesterBarChart(this.data, this.emails);

  @override
  Widget build(BuildContext context) {
    final topRequesters = (data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(4)
        .toList();

    final colors = [Colors.teal, Colors.blue, Colors.orange, Colors.purple];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final barWidth = screenWidth * 0.05;
    final textFontSize = screenWidth * 0.025;

    List<BarChartGroupData> barGroups = topRequesters.asMap().entries.map((entry) {
      int index = entry.key;
      var dataEntry = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dataEntry.value.toDouble(),
            width: barWidth,
            color: colors[index],
          ),
        ],
      );
    }).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.fullscreen),
              onPressed: () => _showFullScreenChart(context),
              tooltip: "Expand",
            ),
          ],
        ),
        Flexible(
          child: SizedBox(
            height: screenHeight * 0.35, // Set height as a percentage of screen height
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: textFontSize, color: Colors.black),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < topRequesters.length) {
                          return Text(
                            topRequesters[value.toInt()].key,
                            style: TextStyle(fontSize: textFontSize, color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barGroups: barGroups,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Flexible(
          child: SingleChildScrollView(
            child: _buildLegend(topRequesters, colors, textFontSize, screenWidth),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(List<MapEntry<String, int>> topRequesters, List<Color> colors, double textFontSize, double screenWidth) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: List.generate(topRequesters.length, (index) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: colors[index],
              radius: 5,
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: screenWidth * 0.2,
              child: Text(
                emails[index],
                style: TextStyle(fontSize: textFontSize),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showFullScreenChart(BuildContext context) {
    final topRequesters = (data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(4)
        .toList();

    final colors = [Colors.teal, Colors.blue, Colors.orange, Colors.purple];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final barWidth = screenWidth * 0.05;
    final textFontSize = screenWidth * 0.025;

    List<BarChartGroupData> barGroups = topRequesters.asMap().entries.map((entry) {
      int index = entry.key;
      var dataEntry = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dataEntry.value.toDouble(),
            width: barWidth,
            color: colors[index],
          ),
        ],
      );
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  SizedBox(
                    height: screenHeight * 0.5,
                    child: BarChart(
                      BarChartData(
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(fontSize: textFontSize, color: Colors.black),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < topRequesters.length) {
                                  return Text(
                                    topRequesters[value.toInt()].key,
                                    style: TextStyle(fontSize: textFontSize, color: Colors.black),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        barGroups: barGroups,
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLegend(topRequesters, colors, textFontSize, screenWidth),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
