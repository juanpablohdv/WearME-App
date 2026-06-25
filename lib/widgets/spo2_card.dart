import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import 'vital_card.dart';

class Spo2Card extends StatelessWidget {
  final ArduinoBluetoothService btService;

  const Spo2Card({super.key, required this.btService});

  String _estado(double? val) {
    if (val == null) return '';
    if (val < 95) return 'BAJO';
    return 'NORMAL';
  }

  Color _color(double? val) {
    if (val == null) return Colors.white38;
    if (val < 95) return Colors.redAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: btService.spo2Stream,
      builder: (context, snapshot) {
        final val = snapshot.data;

        return VitalCard(
          title: 'SPO2',
          value: val?.toStringAsFixed(0),
          unit: '%',
          estadoColor: _color(val),
          icon: Icons.bloodtype,
          estado: _estado(val),
        );
      },
    );
  }
}
