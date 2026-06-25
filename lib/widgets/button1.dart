import 'package:flutter/material.dart';

class CustomMenuButton extends StatelessWidget {
  // Definimos las "propiedades" que queremos cambiar cada vez
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback
  onPressed; // La función que se ejecuta al tocarlo

  const CustomMenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(
            270,
            60,
          ), // Tamaño fijo para consistencia
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
      ),
    );
  }
}
