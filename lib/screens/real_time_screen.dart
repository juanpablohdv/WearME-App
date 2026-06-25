import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../widgets/respiratory_rate_card.dart';
import '../widgets/toraxic_expantion_card.dart';
import '../widgets/raw_data_viewer.dart';
import '../widgets/heart_rate_card.dart';
import '../widgets/spo2_card.dart';
import 'chart_screen.dart';

class RealTimeScreen extends StatefulWidget {
  final ArduinoBluetoothService btService;

  const RealTimeScreen({
    super.key,
    required this.btService,
  });

  @override
  State<RealTimeScreen> createState() =>
      _RealTimeScreenState();
}

class _RealTimeScreenState extends State<RealTimeScreen> {
  int selectedChart = -1;
  String currentType = 'FR';

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation ==
        Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Tiempo Real'),
        backgroundColor: const Color(0xFF1A1A2E),
        leading: selectedChart != -1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    selectedChart = -1;
                  });
                },
              )
            : null,
      ),

      body: widget.btService.isConnected
          ? IndexedStack(
              index: selectedChart == -1 ? 0 : 1,
              children: [
                _buildCards(isLandscape),
                _buildChart(),
              ],
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bluetooth_disabled,
                      color: Colors.white24,
                      size: 64,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Conecte el microcontrolador por Bluetooth para utilizar la función de tiempo real',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Vista normal (cards)
  Widget _buildCards(bool isLandscape) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      currentType = 'FR';
                      selectedChart = 1;
                    });
                  },
                  child: RespiratoryRateCard(
                    btService: widget.btService,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      currentType = 'ET';
                      selectedChart = 1;
                    });
                  },
                  child: ExpansionCard(
                    btService: widget.btService,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      currentType = 'HR';
                      selectedChart = 1;
                    });
                  },
                  child: HeartRateCard(
                    btService: widget.btService,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      currentType = 'SPO2';
                      selectedChart = 1;
                    });
                  },
                  child: Spo2Card(
                    btService: widget.btService,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // SOLO MOSTRAR CONSOLA EN VERTICAL
            if (!isLandscape)
              RawDataViewer(btService: widget.btService),
          ],
        ),
      ),
    );
  }

  // Vista gráfica
  Widget _buildChart() {
    return ChartScreen(
      type: currentType,
      title: _getTitle(),
      minY: _getMinY(),
      maxY: _getMaxY(),
      btService: widget.btService,
    );
  }

  // Helpers

  String _getTitle() {
    switch (currentType) {
      case 'HR':
        return 'Heart Rate';
      case 'SPO2':
        return 'Oxygen Saturation';
      case 'ET':
        return 'Toraxic Expansion';
      default:
        return 'Respiratory Rate';
    }
  }

  double _getMinY() {
    switch (currentType) {
      case 'HR':
        return 40;
      case 'SPO2':
        return 85;
      case 'ET':
        return 0;
      default:
        return 0;
    }
  }

  double _getMaxY() {
    switch (currentType) {
      case 'HR':
        return 140;
      case 'SPO2':
        return 100;
      case 'ET':
        return 150;
      default:
        return 40;
    }
  }
}
