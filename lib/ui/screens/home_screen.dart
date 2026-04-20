import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'players_screen.dart';
import 'game_setup_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Spacer(),
              _buildMainAction(context),
              const SizedBox(height: 16),
              _buildSecondaryActions(context),
              const Spacer(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OPEN',
          style: GoogleFonts.nunito(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            height: 1,
            letterSpacing: -2,
          ),
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
        Text(
          'DART',
          style: GoogleFonts.nunito(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: AppColors.gold,
            height: 1,
            letterSpacing: -2,
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 600.ms).slideX(begin: -0.2),
        const SizedBox(height: 8),
        Text(
          'Darts. Scored. Your way.',
          style: AppTheme.label,
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildMainAction(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GameSetupScreen()),
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 28),
        label: const Text('NEW GAME'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 500.ms)
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SecondaryButton(
            icon: Icons.people_alt_rounded,
            label: 'Players',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayersScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SecondaryButton(
            icon: Icons.bar_chart_rounded,
            label: 'Stats',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 550.ms);
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'Open source · Offline first',
        style: AppTheme.label.copyWith(fontSize: 11),
      ),
    ).animate().fadeIn(delay: 700.ms);
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.textPrimary),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
