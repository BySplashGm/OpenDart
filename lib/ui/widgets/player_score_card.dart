import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../theme/app_theme.dart';

class PlayerScoreCard extends StatelessWidget {
  final Player player;
  final int remainingScore;
  final bool isActive;
  final int dartsThrown;

  const PlayerScoreCard({
    super.key,
    required this.player,
    required this.remainingScore,
    required this.isActive,
    required this.dartsThrown,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(isActive ? 16 : 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? player.color : AppColors.border,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: player.color.withAlpha(60),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isActive ? 14 : 10,
                backgroundColor: player.color,
                child: Text(
                  player.name[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: isActive ? 13 : 9,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  player.name,
                  style: GoogleFonts.nunito(
                    fontSize: isActive ? 14 : 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: player.color.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NOW',
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: player.color,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (isActive)
            Text(
              '$remainingScore',
              style: AppTheme.scoreDisplay(40),
            ).animate(key: ValueKey(remainingScore)).scale(
                  begin: const Offset(1.15, 1.15),
                  end: const Offset(1, 1),
                  duration: 250.ms,
                  curve: Curves.easeOut,
                )
          else
            Text(
              '$remainingScore',
              style: AppTheme.scoreDisplay(22),
            ),
          if (isActive && dartsThrown > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < dartsThrown ? player.color : AppColors.border,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
