import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/complaint.dart';

class StatusPieChart extends StatelessWidget {
  const StatusPieChart({super.key, required this.counts});

  final Map<ComplaintStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Henüz şikayet verisi yok.')),
      );
    }

    final sections = ComplaintStatus.values
        .where((status) => (counts[status] ?? 0) > 0)
        .map((status) {
      final value = (counts[status] ?? 0).toDouble();
      return PieChartSectionData(
        value: value,
        title: '${value.toInt()}',
        color: _colorFor(status),
        radius: 58,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      );
    }).toList();

    return SizedBox(
      height: 240,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 36,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Color _colorFor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.bekliyor:
        return appAccent;
      case ComplaintStatus.inceleniyor:
        return appBlue;
      case ComplaintStatus.onaylandi:
        return appWhatsApp;
      case ComplaintStatus.reddedildi:
        return const Color(0xFFD64545);
      case ComplaintStatus.tamamlandi:
        return appPrimary;
    }
  }
}

class ServiceBarChart extends StatelessWidget {
  const ServiceBarChart({super.key, required this.totals});

  final Map<String, double> totals;

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Henüz satış verisi yok.')),
      );
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = entries.first.value;

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: maxValue * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  final label = entries[index].key.split(' ').first;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 10, color: appMuted),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < entries.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: entries[i].value,
                    color: appPrimary,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
