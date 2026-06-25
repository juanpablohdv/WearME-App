import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> data = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();

    loadData();

    // refresco automático
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => loadData(),
    );
  }

  Future<void> loadData() async {
    final db = await DatabaseService.instance.database;

    final result = await db.query(
      'vitals',
      orderBy: 'timestamp DESC',
    );

    if (!mounted) return;

    setState(() {
      data = result;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp,
    );

    return '${date.day}/${date.month} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }

  //Colores por tipo y numero
  Color getColor(String type, double value) {
    switch (type) {
      // ❤️ HEART RATE
      case 'HR':
        if (value > 105) {
          return Colors.redAccent;
        } else if (value < 55) {
          return Colors.orangeAccent;
        } else {
          return Colors.greenAccent;
        }

      // 🩸 SPO2
      case 'SPO2':
        if (value < 95) {
          return Colors.redAccent;
        } else {
          return Colors.greenAccent;
        }

      // 🌬️ FRECUENCIA RESPIRATORIA
      case 'FR':
        if (value > 30) {
          return Colors.redAccent;
        } else if (value < 7) {
          return Colors.orangeAccent;
        } else {
          return Colors.greenAccent;
        }

      // 📏 EXPANSIÓN TORÁCICA
      case 'ET':
        return Colors.greenAccent;

      default:
        return Colors.white;
    }
  }

  Icon getIcon(String type) {
    switch (type) {
      case 'HR':
        return const Icon(Icons.favorite);
      case 'SPO2':
        return const Icon(Icons.bloodtype);
      case 'FR':
        return const Icon(Icons.air);
      case 'ET':
        return const Icon(Icons.expand);
      default:
        return const Icon(Icons.device_unknown);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),

      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),

      body: data.isEmpty
          ? const Center(
              child: Text(
                'Sin datos',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (_, i) {
                final item = data[i];

                final type = item['type'];
                final value = item['value'];
                final timestamp = item['timestamp'];

                return Card(
                  color: const Color(0xFF16213E),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: getColor(
                        type,
                        value,
                      ),
                      child: IconTheme(
                        data: const IconThemeData(
                          color: Colors.white,
                          size: 22,
                        ),
                        child: getIcon(type),
                      ),
                    ),

                    title: Text(
                      '$type: $value',
                      style: TextStyle(
                        color: getColor(type, value),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      formatDate(timestamp),
                      style: const TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
