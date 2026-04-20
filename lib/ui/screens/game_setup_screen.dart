import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../models/game.dart';
import '../../models/game_rules.dart';
import '../../models/player.dart';
import '../../providers/players_provider.dart';
import '../../providers/game_provider.dart';
import '../../theme/app_theme.dart';
import 'active_game_screen.dart';
import 'players_screen.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  int _selectedVariant = 501;
  bool _comboMode = false;
  final List<String> _selectedPlayerIds = [];
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Game')),
      body: playersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (players) => _buildBody(context, players),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<Player> players) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('GAME VARIANT'),
                const SizedBox(height: 12),
                _buildVariantSelector(),
                const SizedBox(height: 28),
                _buildComboModeToggle(),
                const SizedBox(height: 28),
                _buildSectionLabel('PLAYERS'),
                const SizedBox(height: 4),
                Text(
                  'Select 1–8 players. Order determines turn sequence.',
                  style: AppTheme.label,
                ),
                const SizedBox(height: 12),
                if (players.isEmpty)
                  _buildNoPlayersPrompt(context)
                else
                  _buildPlayerList(players),
              ],
            ),
          ),
        ),
        _buildStartButton(context, players),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildVariantSelector() {
    return Row(
      children: GameRules.variants.map((v) {
        final selected = _selectedVariant == v;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedVariant = v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.gold.withAlpha(20)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.gold : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  '$v',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: selected ? AppColors.gold : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComboModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _comboMode ? AppColors.purple.withAlpha(20) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _comboMode ? AppColors.purple : AppColors.border,
          width: _comboMode ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSectionLabel('COMBO MODE'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'EXPERIMENTAL',
                        style: GoogleFonts.nunito(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Earn combo bonuses for exact matches, consecutive doubles & zone mastery. Does not affect actual scores.',
                  style: AppTheme.label.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: _comboMode,
            onChanged: (v) => setState(() => _comboMode = v),
            activeThumbColor: AppColors.purple,
            activeTrackColor: AppColors.purple.withAlpha(120),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(List<Player> players) {
    return Column(
      children: players.map((p) {
        final selected = _selectedPlayerIds.contains(p.id);
        final order = selected ? _selectedPlayerIds.indexOf(p.id) + 1 : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedPlayerIds.remove(p.id);
                } else if (_selectedPlayerIds.length < 8) {
                  _selectedPlayerIds.add(p.id);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? p.color.withAlpha(20) : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? p.color : AppColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: p.color,
                    child: Text(
                      p.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p.name,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (order != null)
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$order',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    const Icon(Icons.add_circle_outline,
                        color: AppColors.textSecondary, size: 22),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoPlayersPrompt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text('No players found', style: AppTheme.label),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayersScreen()),
            ),
            child: const Text('Add Players'),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, List<Player> players) {
    final canStart = _selectedPlayerIds.isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canStart ? () => _startGame(context) : null,
            icon: const Icon(Icons.sports_score_rounded),
            label: Text(
              canStart
                  ? 'START — $_selectedVariant (${_selectedPlayerIds.length} players)'
                  : 'Select at least 1 player',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: canStart ? AppColors.gold : AppColors.surfaceElevated,
              foregroundColor: canStart ? AppColors.background : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startGame(BuildContext context) async {
    final game = Game(
      id: _uuid.v4(),
      startingScore: _selectedVariant,
      playerIds: List.from(_selectedPlayerIds),
      playerOrder: List.from(_selectedPlayerIds),
      startDate: DateTime.now(),
      doubleOut: true,
      comboMode: _comboMode,
    );

    final navigator = Navigator.of(context);
    await ref.read(gameProvider.notifier).startGame(game);
    if (!mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const ActiveGameScreen()),
    );
  }
}
