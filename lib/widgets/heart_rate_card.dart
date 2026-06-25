import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import 'vital_card.dart';

class HeartRateCard extends StatelessWidget {
  final ArduinoBluetoothService btService;

  const HeartRateCard({super.key, required this.btService});

  String _estado(double? val) {
    if (val == null) return '';
    if (val < 55) return 'BAJO';
    if (val > 105) return 'ALTO';
    return 'NORMAL';
  }

  Color _color(double? val) {
    if (val == null) return Colors.white38;
    if (val < 55) return Colors.orange;
    if (val > 105) return Colors.redAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: btService.heartRateStream,
      builder: (context, snapshot) {
        final val = snapshot.data;

        return VitalCard(
          title: 'HEART RATE',
          value: val?.toStringAsFixed(0),
          unit: 'bpm',
          estadoColor: _color(val),
          icon: Icons.favorite,
          estado: _estado(val),
        );
      },
    );
  }
}
