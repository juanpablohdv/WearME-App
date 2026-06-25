import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import 'vital_card.dart';

class RespiratoryRateCard extends StatelessWidget {
  final ArduinoBluetoothService btService;

  const RespiratoryRateCard({
    super.key,
    required this.btService,
  });

  String _estado(double? rate) {
    if (rate == null) return '';
    if (rate < 7) return 'BRADIPNEA';
    if (rate > 30) return 'TAQUIPNEA';
    return 'NORMAL';
  }

  Color _color(double? rate) {
    if (rate == null) return Colors.white38;
    if (rate < 7) return Colors.orange;
    if (rate > 30) return Colors.redAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: btService.respiratoryStream,
      builder: (context, snapshot) {
        final rate = snapshot.data;

        return VitalCard(
          title: 'FREC. RESPIRATORIA',
          value: rate?.toStringAsFixed(1),
          unit: 'resp/min',
          estadoColor: _color(rate),
          icon: Icons.air,
          estado: _estado(rate),
        );
      },
    );
  }
}
