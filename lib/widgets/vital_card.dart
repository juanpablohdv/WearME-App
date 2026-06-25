import 'package:flutter/material.dart';

class VitalCard extends StatelessWidget {
  final String title;
  final String? value;
  final String unit;
  final String? estado;
  final Color estadoColor;
  final IconData icon;
  final AnimationController? spinnerController;

  const VitalCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.estadoColor,
    required this.icon,
    this.estado,
    this.spinnerController,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLoading = value == null;

    return Container(
      width: 220,
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isLoading
              ? Colors.white24
              : estadoColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Ícono siempre visible ──────────────────────
          Icon(
            icon,
            color: estadoColor.withValues(alpha: 0.8),
            size: 32,
          ),
          const SizedBox(height: 8),

          // ── Etiqueta ───────────────────────────────────
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // ── Spinner o valor ────────────────────────────
          if (isLoading)
            // Spinner pequeño separado del ícono
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white24,
              ),
            )
          else
            Text(
              value!,
              style: TextStyle(
                color: estadoColor,
                fontSize: 52,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),

          const SizedBox(height: 8),

          // ── Unidad ─────────────────────────────────────
          Text(
            isLoading ? 'Esperando...' : unit,
            style: TextStyle(
              color: isLoading
                  ? Colors.white38
                  : Colors.white54,
              fontSize: 13,
            ),
          ),

          // ── Estado ─────────────────────────────────────
          if (estado != null && !isLoading) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                estado!,
                style: TextStyle(
                  color: estadoColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
