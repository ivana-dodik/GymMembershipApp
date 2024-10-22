import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AgeDistributionPieChart extends StatelessWidget {
  final Map<String, int> ageDistribution;

  const AgeDistributionPieChart({
    super.key,
    required this.ageDistribution,
  });

  @override
  Widget build(BuildContext context) {
    final totalMembers = ageDistribution.values.reduce((a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 200, // Increased height to accommodate larger pie chart
            child: PieChart(
              PieChartData(
                sections: ageDistribution.entries
                    .map((entry) => PieChartSectionData(
                          value: (entry.value / totalMembers) * 100,
                          color: _getPieColor(entry.key),
                          title: '(age: ${entry.key})\n${entry.value}',
                          radius: 90,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          titlePositionPercentageOffset: 0.5,
                          gradient: LinearGradient(
                            colors: [
                              _getPieColor(entry.key).withOpacity(0.7),
                              _getPieColor(entry.key)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ))
                    .toList(),
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                centerSpaceRadius: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Assign different colors based on the age group
  Color _getPieColor(String ageGroup) {
    switch (ageGroup) {
      case '18-25':
        return Colors.blue;
      case '26-35':
        return const Color.fromARGB(255, 111, 194, 114);
      case '36-45':
        return const Color.fromARGB(255, 232, 168, 72);
      case '46-60':
        return const Color.fromARGB(255, 225, 89, 79);
      case '60+':
        return const Color.fromARGB(255, 194, 79, 214);
      default:
        return Colors.grey; // Default color for any other groups
    }
  }
}
