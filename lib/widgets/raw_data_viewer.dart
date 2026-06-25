import 'dart:async';
import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class RawDataViewer extends StatefulWidget {
  final ArduinoBluetoothService btService;

  const RawDataViewer({super.key, required this.btService});

  @override
  State<RawDataViewer> createState() =>
      _RawDataViewerState();
}

class _RawDataViewerState extends State<RawDataViewer> {
  StreamSubscription<String>? _subscription;
  String _buffer = '';
  final List<String> _lines = [];

  @override
  void initState() {
    super.initState();

    _subscription = widget.btService.dataStream.listen((
      chunk,
    ) {
      _buffer += chunk;

      while (_buffer.contains('\n')) {
        final idx = _buffer.indexOf('\n');
        final line = _buffer.substring(0, idx).trim();
        _buffer = _buffer.substring(idx + 1);

        if (line.isNotEmpty) {
          setState(() {
            _lines.insert(0, line); // último arriba

            // limitar a 50 líneas
            if (_lines.length > 50) {
              _lines.removeLast();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        reverse: true,
        itemCount: _lines.length,
        itemBuilder: (_, i) => Text(
          _lines[i],
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
