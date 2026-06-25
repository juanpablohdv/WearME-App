import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'database_service.dart';
import 'notification_service.dart';

class ArduinoBluetoothService {
  static final ArduinoBluetoothService instance =
      ArduinoBluetoothService._internal();

  factory ArduinoBluetoothService() {
    return instance;
  }

  ArduinoBluetoothService._internal();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxChar;

  final StreamController<String> _dataController =
      StreamController.broadcast();

  // ───────── STREAMS ─────────
  final _hrController =
      StreamController<double>.broadcast();
  final _spo2Controller =
      StreamController<double>.broadcast();
  final _frController =
      StreamController<double>.broadcast();
  final _etController =
      StreamController<double>.broadcast();

  Stream<double> get heartRateStream =>
      _hrController.stream;
  Stream<double> get spo2Stream => _spo2Controller.stream;
  Stream<double> get respiratoryStream =>
      _frController.stream;
  Stream<double> get expansionStream =>
      _etController.stream;

  // ───────── CONEXIÓN ─────────
  final _connectionController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStream =>
      _connectionController.stream;

  bool _fullyConnected = false;
  bool _disconnectHandled = false;

  bool get isConnected => _fullyConnected;
  String? connectedDeviceName;

  String _buffer = '';

  final Map<String, int> _lastSaveTime = {};
  final Map<String, double> _lastValue = {};
  final Map<String, int> _criticalCounter = {};
  static const int saveIntervalMs = 1000;

  final List<Map<String, dynamic>> _dbBuffer = [];
  Timer? _dbTimer;

  Stream<ScanResult> scanDevices() {
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      androidUsesFineLocation: false,
    );
    return FlutterBluePlus.scanResults.expand((r) => r);
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    _device = device;

    await device.connect(
      timeout: const Duration(seconds: 10),
      autoConnect: false,
      license: License.free,
    );

    connectedDeviceName = device.platformName;
    _connectionController.add(true);

    //detecta desconexion BLE

    device.connectionState.listen((state) async {
      // conexión establecida
      if (state == BluetoothConnectionState.connected) {
        _fullyConnected = true;
        _disconnectHandled = false;
        return;
      }

      // desconexión real
      if (state == BluetoothConnectionState.disconnected) {
        // evitar spam infinito
        if (_disconnectHandled) return;

        _disconnectHandled = true;

        _fullyConnected = false;
        _device = null;

        _connectionController.add(false);

        await NotificationService.showAlert(
          'BLE desconectado',
          'El dispositivo biomédico se desconectó',
        );
      }
    });

    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid.toString().toLowerCase().contains(
        'fff0',
      )) {
        for (final char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();

          if (uuid.contains('fff4')) {
            await char.setNotifyValue(true);

            char.onValueReceived.listen((value) {
              if (value.isEmpty) return;

              final text = utf8.decode(
                value,
                allowMalformed: true,
              );

              _dataController.add(text);
              _processChunk(text);
            });
          }

          if (uuid.contains('fff1') &&
              char.properties.write) {
            _rxChar = char;
          }
        }
      }
    }

    _fullyConnected = true;
    _disconnectHandled = false;
    _startDbFlush();
  }

  void _processChunk(String chunk) {
    _buffer += chunk;

    while (_buffer.contains('\n')) {
      final idx = _buffer.indexOf('\n');
      final line = _buffer.substring(0, idx).trim();
      _buffer = _buffer.substring(idx + 1);

      _parseLine(line);
    }
  }

  void _parseLine(String line) {
    if (line.isEmpty) return;

    _handleValue('HR', line, r'HR:\s*(\d+)', _hrController);
    _handleValue(
      'SPO2',
      line,
      r'SPO2:\s*(\d+)',
      _spo2Controller,
    );
    _handleValue(
      'FR',
      line,
      r'FR:\s*([\d.]+)',
      _frController,
    );
    _handleValue(
      'ET',
      line,
      r'ET:\s*([\d.]+)',
      _etController,
    );
  }

  void _handleValue(
    String type,
    String line,
    String pattern,
    StreamController<double> controller,
  ) {
    final match = RegExp(pattern).firstMatch(line);
    if (match == null) return;

    final val = double.tryParse(match.group(1)!);
    if (val == null) return;

    // evitar repetidos
    if (_lastValue[type] == val) return;
    _lastValue[type] = val;

    // UI
    controller.add(val);
    _checkCritical(type, val);

    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastSaveTime[type] ?? 0;

    if (now - last >= saveIntervalMs) {
      _dbBuffer.add({
        'type': type,
        'value': val,
        'timestamp': now,
      });

      _lastSaveTime[type] = now;
    }
  }

  void _checkCritical(String type, double value) {
    bool critical = false;

    switch (type) {
      case 'HR':
        critical = value < 45 || value > 120;
        break;

      case 'SPO2':
        critical = value < 90;
        break;

      case 'FR':
        critical = value < 5 || value > 25;
        break;

      case 'ET':
        break;
    }

    _criticalCounter[type] ??= 0;

    if (critical) {
      _criticalCounter[type] = _criticalCounter[type]! + 1;

      if (_criticalCounter[type]! >= 5) {
        NotificationService.showAlert(
          '⚠️ ALERTA $type',
          'Se detectaron 5 mediciones críticas seguidas',
        );

        _criticalCounter[type] = 0;
      }
    } else {
      _criticalCounter[type] = 0;
    }
  }

  void _startDbFlush() {
    _dbTimer?.cancel();

    _dbTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) async {
        if (_dbBuffer.isEmpty) return;

        final copy = List<Map<String, dynamic>>.from(
          _dbBuffer,
        );
        _dbBuffer.clear();

        await DatabaseService.instance.insertBatch(copy);
      },
    );
  }

  Future<void> sendData(String data) async {
    if (_rxChar != null) {
      await _rxChar!.write(utf8.encode(data));
    }
  }

  Stream<String> get dataStream => _dataController.stream;

  Future<void> disconnect() async {
    _fullyConnected = false;
    _disconnectHandled = true;

    await _device?.disconnect();

    _device = null;

    _connectionController.add(false);
  }

  void dispose() {
    _dbTimer?.cancel();
    _dataController.close();
    _hrController.close();
    _spo2Controller.close();
    _frController.close();
    _etController.close();
    _connectionController.close();
  }
}
