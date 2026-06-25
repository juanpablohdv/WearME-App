import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';

class VitalChart extends StatefulWidget {
  final String type;
  final Stream<double>? liveStream;
  final double minY;
  final double maxY;

  const VitalChart({
    super.key,
    required this.type,
    this.liveStream,
    required this.minY,
    required this.maxY,
  });

  @override
  State<VitalChart> createState() => _VitalChartState();
}

class _VitalChartState extends State<VitalChart>
    with AutomaticKeepAliveClientMixin {
  List<FlSpot> spots = [];
  bool loading = true;

  double _time = 0;
  final double window = 60;

  StreamSubscription<double>? _subscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _listenLive();
  }

  Future<void> _loadHistory() async {
    final data = await DatabaseService.instance.getVitals(
      widget.type,
    );

    if (data.isEmpty) {
      setState(() => loading = false);
      return;
    }

    final baseTime = data.last['timestamp'];

    spots = data.map((e) {
      return FlSpot(
        (e['timestamp'] - baseTime) / 1000.0,
        e['value'],
      );
    }).toList();

    setState(() => loading = false);
  }

  void _listenLive() {
    if (widget.liveStream == null) return;

    _subscription?.cancel();

    _subscription = widget.liveStream!.listen((val) {
      _time += 1;

      if (!mounted) return;

      setState(() {
        spots.add(FlSpot(_time, val));

        if (spots.length > 100) {
          spots.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (spots.isEmpty) {
      return const Center(
        child: Text(
          'Sin datos',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.all(12),
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
          minY: widget.minY,
          maxY: widget.maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval:
                (widget.maxY - widget.minY) / 4,
            verticalInterval: 10,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white10,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.white10,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (widget.maxY - widget.minY) / 4,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 10,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}s',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              barWidth: 2,
              color: Colors.greenAccent,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
