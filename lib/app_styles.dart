import 'package:flutter/material.dart';

class AppTextStyles {
  // Estilo para títulos grandes (Negrita)
  static const TextStyle titleMain = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    letterSpacing: 1.2,
  );

  // Estilo para subtítulos (Semi-bold)
  static const TextStyle subTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600, // Semi-bold
    color: Colors.blueAccent,
  );

  // Estilo para datos de lectura (Monitor)
  static const TextStyle monitorData = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w900, // Black (lo más grueso)
    color: Colors.greenAccent,
    fontFamily: 'Courier', // Un estilo digital
  );
}
