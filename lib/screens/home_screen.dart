import 'package:flutter/material.dart';
import 'package:pf_app/app_colors.dart';
import 'real_time_screen.dart';
import 'history_screen.dart';
import '/widgets/button1.dart';
import '../app_styles.dart';
import '../services/bluetooth_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ArduinoBluetoothService _btService =
      ArduinoBluetoothService();
  bool _isConnecting = false;
  bool _isConnected = false;
  String _connectedDeviceName = '';

  // ── 1. PERMISOS ─────────────────────────────────────────────
  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
      Permission.sms,
      Permission.phone,
      Permission.notification,
    ].request();
  }

  // ── 2. INIT STATE ────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _requestPermissions();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    //ESCUCHAR CONEXIÓN
    _btService.connectionStream.listen((connected) {
      if (!mounted) return;

      setState(() {
        _isConnected = connected;
        if (!connected) _connectedDeviceName = '';
      });
    });
  }

  Future<void> _connectBluetooth() async {
    final btState =
        await FlutterBluePlus.adapterState.first;

    if (!mounted) return;

    if (btState != BluetoothAdapterState.on) {
      _showSnack(
        'Activa el Bluetooth del dispositivo primero',
      );
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final selected = await showDialog<BluetoothDevice>(
        context: context,
        builder: (_) =>
            _DevicePickerDialog(btService: _btService),
      );

      if (!mounted) return;

      if (selected == null) {
        setState(() => _isConnecting = false);
        return;
      }

      await _btService.connect(selected);

      if (!mounted) return;

      setState(() {
        _isConnected = true;
        _connectedDeviceName = selected.platformName;
        _isConnecting = false;
      });

      _showSnack('Conectado a $_connectedDeviceName');
    } catch (e) {
      if (!mounted) return;

      setState(() => _isConnecting = false);

      _showSnack('Error al conectar: $e');
    }
  }

  // ── 4. DESCONECTAR ───────────────────────────────────────────
  Future<void> _disconnectBluetooth() async {
    await _btService.disconnect();
    setState(() {
      _isConnected = false;
      _connectedDeviceName = '';
    });
    _showSnack('Dispositivo desconectado');
  }

  // ── 5. SNACKBAR ──────────────────────────────────────────────
  void _showSnack(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── 6. DISPOSE ───────────────────────────────────────────────
  @override
  void dispose() {
    _btService
        .disconnect(); // sin el if, siempre desconecta
    super.dispose();
  }

  // ── 7. BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final statusText = _isConnecting
        ? 'Estado: Conectando...'
        : _isConnected
        ? 'Estado: Conectado ($_connectedDeviceName)'
        : 'Estado: Desconectado';

    final logo = Image.asset(
      'assets/images/Logo WearMe.png',
      height: 300,
    );

    final status = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        statusText,
        key: ValueKey(statusText),
        style: AppTextStyles.titleMain,
        textAlign: TextAlign.center,
      ),
    );

    final buttons = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _isConnecting
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : CustomMenuButton(
                label: _isConnected
                    ? 'DESCONECTAR'
                    : 'CONECTAR DISPOSITIVO',
                icon: _isConnected
                    ? Icons.bluetooth_disabled
                    : Icons.monitor_heart,
                color: _isConnected
                    ? Colors.redAccent
                    : AppColors.blue1,
                onPressed: _isConnected
                    ? _disconnectBluetooth
                    : _connectBluetooth,
              ),
        CustomMenuButton(
          label: 'TIEMPO REAL',
          icon: Icons.timer,
          color: AppColors.blue2,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RealTimeScreen(btService: _btService),
            ),
          ),
        ),
        CustomMenuButton(
          label: 'HISTORIAL',
          icon: Icons.history,
          color: AppColors.green1,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const HistoryScreen(),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape =
                MediaQuery.of(context).orientation ==
                Orientation.landscape;

            if (isLandscape) {
              // ── HORIZONTAL ────────────────────────────────
              return Row(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            logo,
                            const SizedBox(height: 16),
                            status,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: buttons,
                      ),
                    ),
                  ),
                ],
              );
            }

            // ── VERTICAL ──────────────────────────────────
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        logo,
                        const SizedBox(height: 32),
                        status,
                        const SizedBox(height: 40),
                        buttons,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Diálogo selector de dispositivos ────────────────────────────────────────
class _DevicePickerDialog extends StatefulWidget {
  final ArduinoBluetoothService btService;
  const _DevicePickerDialog({required this.btService});

  @override
  State<_DevicePickerDialog> createState() =>
      _DevicePickerDialogState();
}

class _DevicePickerDialogState
    extends State<_DevicePickerDialog> {
  final List<BluetoothDevice> _found = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  void _scan() {
    setState(() {
      _found.clear();
      _isScanning = true;
    });

    widget.btService.scanDevices().listen(
      (result) {
        if (!mounted) return;
        // Solo muestra dispositivos con nombre
        if (result.device.platformName.isEmpty) return;
        setState(() {
          final exists = _found.any(
            (d) => d.remoteId == result.device.remoteId,
          );
          if (!exists) _found.add(result.device);
        });
      },
      onDone: () {
        if (mounted) setState(() => _isScanning = false);
      },
    );

    // Para el scan después de 10s
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _isScanning = false);
    });
  }

  @override
  void dispose() {
    widget.btService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          const Text(
            'Dispositivos BLE',
            style: TextStyle(color: Colors.white),
          ),
          const Spacer(),
          if (_isScanning)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.tealAccent,
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: _found.isEmpty
            ? Center(
                child: Text(
                  _isScanning
                      ? 'Buscando dispositivos...'
                      : 'No se encontraron dispositivos',
                  style: const TextStyle(
                    color: Colors.white54,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: _found.length,
                itemBuilder: (_, i) {
                  final d = _found[i];
                  return ListTile(
                    leading: const Icon(
                      Icons.bluetooth,
                      color: Colors.blueAccent,
                    ),
                    title: Text(
                      d.platformName,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      d.remoteId.toString(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, d),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: _scan,
          child: const Text(
            'Buscar de nuevo',
            style: TextStyle(color: Colors.tealAccent),
          ),
        ),
        TextButton(
          onPressed: () {
            widget.btService.stopScan();
            Navigator.pop(context);
          },
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }
}
