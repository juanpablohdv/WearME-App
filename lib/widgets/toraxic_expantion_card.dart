import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import 'vital_card.dart';

class ExpansionCard extends StatelessWidget {
  final ArduinoBluetoothService btService;

  const ExpansionCard({super.key, required this.btService});

  String? _estado(double? val) {
    if (val == null) return null;
    if (val < 40) return 'BAJA';
    if (val > 80) return 'ALTA';
    return 'NORMAL';
  }

  Color _color(double? val) {
    if (val == null) return Colors.white38;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: btService.expansionStream.distinct(),
      builder: (context, snapshot) {
        final val = snapshot.hasData ? snapshot.data : null;

        final estado = _estado(val);
        final color = _color(val);

        return VitalCard(
          title: 'EXPANSIÓN TORÁCICA',
          value: val?.toStringAsFixed(1),
          unit: 'mm',
          estadoColor: color,
          icon: Icons.expand,
          estado: estado,
        );
      },
    );
  }
}
