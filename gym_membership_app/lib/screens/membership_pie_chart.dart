import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MembershipPieChart extends StatelessWidget {
  final int totalMembers;
  final int activeMembers;
  final int expiredMembers;

  const MembershipPieChart({
    super.key,
    required this.totalMembers,
    required this.activeMembers,
    required this.expiredMembers,
  });

  @override
  Widget build(BuildContext context) {
    final double activePercentage = (activeMembers / totalMembers) * 100;
    final double expiredPercentage = (expiredMembers / totalMembers) * 100;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: activePercentage,
                    color: const Color.fromARGB(255, 116, 193, 118),
                    title: '(Active)\n$activeMembers',
                    radius: 90,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    titlePositionPercentageOffset: 0.5,
                    gradient: LinearGradient(
                      colors: [Colors.green.withOpacity(0.7), Colors.green],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  PieChartSectionData(
                    value: expiredPercentage,
                    color: const Color.fromARGB(255, 232, 60, 48),
                    title: '(Expired)\n$expiredMembers',
                    radius: 90,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    titlePositionPercentageOffset: 0.5,
                    gradient: LinearGradient(
                      colors: [Colors.red.withOpacity(0.7), Colors.red],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ],
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                centerSpaceRadius: 25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
