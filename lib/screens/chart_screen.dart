import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../widgets/vital_chart.dart';

class ChartScreen extends StatelessWidget {
  final String type;
  final String title;
  final double minY;
  final double maxY;
  final ArduinoBluetoothService btService;

  const ChartScreen({
    super.key,
    required this.type,
    required this.title,
    required this.minY,
    required this.maxY,
    required this.btService,
  });

  Stream<double>? _getStream() {
    switch (type) {
      case 'HR':
        return btService.heartRateStream;
      case 'SPO2':
        return btService.spo2Stream;
      case 'FR':
        return btService.respiratoryStream;
      case 'ET':
        return btService.expansionStream;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Center(
            child: AspectRatio(
              aspectRatio:
                  orientation == Orientation.portrait
                  ? 1
                  : 2,
              child: VitalChart(
                type: type,
                liveStream: _getStream(),
                minY: minY,
                maxY: maxY,
              ),
            ),
          );
        },
      ),
    );
  }
}
