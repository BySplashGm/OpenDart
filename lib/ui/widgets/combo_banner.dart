import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/combo_result.dart';
import '../../theme/app_theme.dart';

class ComboBanner extends StatelessWidget {
  final ComboResult combo;
  final VoidCallback? onDismiss;

  const ComboBanner({super.key, required this.combo, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: AppTheme.comboDecoration(combo.color),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(combo.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  combo.displayText,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                if (combo.multiplierLabel.isNotEmpty)
                  Text(
                    combo.multiplierLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ],
        ),
      )
          .animate()
          .slideY(begin: -1, end: 0, curve: Curves.elasticOut, duration: 500.ms)
          .fadeIn(duration: 300.ms),
    );
  }
}
