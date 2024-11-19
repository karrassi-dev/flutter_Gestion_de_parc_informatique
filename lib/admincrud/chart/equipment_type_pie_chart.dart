

/*import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EquipmentTypePieChart extends StatefulWidget {
  final Map<String, int> data;

  EquipmentTypePieChart(this.data);

  @override
  _EquipmentTypePieChartState createState() => _EquipmentTypePieChartState();
}

class _EquipmentTypePieChartState extends State<EquipmentTypePieChart> {
  int? _focusedIndex;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          _buildPieChart(screenWidth * 0.7, screenHeight * 0.7), // Responsive chart size
          const SizedBox(height: 20),
          _buildLegend(screenWidth * 0.8), // Responsive legend size
        ],
      ),
    );
  }

  Widget _buildPieChart(double chartWidth, double chartHeight) {
    return SizedBox(
      height: chartWidth,
      width: chartWidth,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: chartWidth * 0.3,
              sections: _generateSections(),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                      _focusedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    } else {
                      _focusedIndex = null;
                    }
                  });
                },
              ),
            ),
          ),
          if (_focusedIndex != null && _focusedIndex! >= 0 && _focusedIndex! < widget.data.length)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.data.keys.elementAt(_focusedIndex!),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  widget.data.values.elementAt(_focusedIndex!) > 0
                      ? '${(widget.data.values.elementAt(_focusedIndex!) / widget.data.values.reduce((a, b) => a + b) * 100).toStringAsFixed(1)}%'
                      : 'No Requests',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections() {
    final total = widget.data.values.isEmpty ? 1 : widget.data.values.reduce((a, b) => a + b);

    return widget.data.entries.map((entry) {
      int index = widget.data.keys.toList().indexOf(entry.key);
      bool isFocused = _focusedIndex == index;
      double percentage = total > 0 ? (entry.value / total) * 100 : 0;

      return PieChartSectionData(
        color: _getColorForEntry(entry.key).withOpacity(isFocused ? 1.0 : 0.4),
        value: entry.value.toDouble(),
        title: entry.value > 0 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isFocused ? 50 : 40,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(isFocused ? 1.0 : 0.5),
        ),
      );
    }).toList();
  }

  Color _getColorForEntry(String entryKey) {
    final colors = [
      Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.red,
      Colors.yellow, Colors.brown, Colors.cyan, Colors.indigo, Colors.pink
    ];
    return colors[widget.data.keys.toList().indexOf(entryKey) % colors.length];
  }

  Widget _buildLegend(double width) {
    List<Widget> legendItems = widget.data.keys.map((key) {
      int index = widget.data.keys.toList().indexOf(key);
      return GestureDetector(
        onTap: () {
          setState(() {
            _focusedIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                color: _getColorForEntry(key).withOpacity(_focusedIndex == index ? 1.0 : 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                key,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Container(
      width: width,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12.0,
        runSpacing: 8.0,
        children: legendItems,
      ),
    );
  }

  void _showFullScreenChart(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
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
                Expanded(
                  child: Center(
                    child: _buildPieChart(screenWidth * 0.8, screenHeight * 0.8), // Expanded chart size in fullscreen
                  ),
                ),
                _buildLegend(screenWidth * 0.9),
              ],
            ),
          ),
        );
      },
    );
  }
}
*/


import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EquipmentTypePieChart extends StatefulWidget {
  final Map<String, int> data;
  final Function(String) onSectionTapped; 
  final Function(String) onLegendTapped;  

  EquipmentTypePieChart(this.data, {required this.onSectionTapped, required this.onLegendTapped});

  @override
  _EquipmentTypePieChartState createState() => _EquipmentTypePieChartState();
}

class _EquipmentTypePieChartState extends State<EquipmentTypePieChart> {
  int? _focusedIndex;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          _buildPieChart(screenWidth * 0.7, screenHeight * 0.7),
          const SizedBox(height: 20),
          _buildLegend(screenWidth * 0.8),
        ],
      ),
    );
  }

  Widget _buildPieChart(double chartWidth, double chartHeight) {
  return SizedBox(
    height: chartWidth,
    width: chartWidth,
    child: Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: chartWidth * 0.3,
            sections: _generateSections(),
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                    _focusedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    String selectedType = widget.data.keys.elementAt(_focusedIndex!);
                    widget.onSectionTapped(selectedType); // Notify dashboard
                  } else {
                    _focusedIndex = null;
                    widget.onSectionTapped(''); 
                  }
                });
              },
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _focusedIndex = null; 
              widget.onSectionTapped(''); 
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Reset',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Text(
                'View All',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (_focusedIndex != null && _focusedIndex! >= 0 && _focusedIndex! < widget.data.length)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.data.keys.elementAt(_focusedIndex!),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getColorForEntry(widget.data.keys.elementAt(_focusedIndex!)),
                  ),
                ),
                Text(
                  '${_getPercentage(widget.data.values.elementAt(_focusedIndex!)).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}


  List<PieChartSectionData> _generateSections() {
    final total = widget.data.values.isEmpty ? 1 : widget.data.values.reduce((a, b) => a + b);

    return widget.data.entries.map((entry) {
      int index = widget.data.keys.toList().indexOf(entry.key);
      bool isFocused = _focusedIndex == index;
      double percentage = total > 0 ? (entry.value / total) * 100 : 0;

      return PieChartSectionData(
        color: _getColorForEntry(entry.key).withOpacity(isFocused ? 1.0 : 0.4),
        value: entry.value.toDouble(),
        title: entry.value > 0 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isFocused ? 50 : 40,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(isFocused ? 1.0 : 0.5),
        ),
      );
    }).toList();
  }

  double _getPercentage(int value) {
    final total = widget.data.values.reduce((a, b) => a + b);
    return (value / total) * 100;
  }

  Color _getColorForEntry(String entryKey) {
    final colors = [
      Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.red,
      Colors.yellow, Colors.brown, Colors.cyan, Colors.indigo, Colors.pink
    ];
    return colors[widget.data.keys.toList().indexOf(entryKey) % colors.length];
  }

  Widget _buildLegend(double width) {
    List<Widget> legendItems = widget.data.keys.map((key) {
      int index = widget.data.keys.toList().indexOf(key);
      return GestureDetector(
        onTap: () {
          setState(() {
            _focusedIndex = index;
            widget.onLegendTapped(key); 
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                color: _getColorForEntry(key).withOpacity(_focusedIndex == index ? 1.0 : 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                key,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _focusedIndex == index ? FontWeight.bold : FontWeight.normal,
                  color: _focusedIndex == index ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Container(
      width: width,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12.0,
        runSpacing: 8.0,
        children: legendItems,
      ),
    );
  }

  void _showFullScreenChart(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
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
                Expanded(
                  child: Center(
                    child: _buildPieChart(screenWidth * 0.8, screenHeight * 0.8),
                  ),
                ),
                _buildLegend(screenWidth * 0.9),
              ],
            ),
          ),
        );
      },
    );
  }
}

