import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';
import '../../providers/players_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/combo_banner.dart';
import '../widgets/checkout_suggestion.dart';
import '../widgets/player_score_card.dart';
import '../widgets/score_input_pad.dart';
import 'game_summary_screen.dart';

class ActiveGameScreen extends ConsumerWidget {
  const ActiveGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final playersAsync = ref.watch(playersProvider);

    if (gameState == null) {
      return const Scaffold(
        body: Center(child: Text('No active game')),
      );
    }

    // Navigate to summary when game is over
    ref.listen(gameProvider, (prev, next) {
      if (next?.isGameOver == true && prev?.isGameOver == false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GameSummaryScreen()),
        );
      }
    });

    return playersAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (players) {
        final playerMap = {for (final p in players) p.id: p};
        return _buildGame(context, ref, gameState, playerMap);
      },
    );
  }

  Widget _buildGame(
    BuildContext context,
    WidgetRef ref,
    GameState gs,
    Map<String, Player> playerMap,
  ) {
    final currentPlayer = playerMap[gs.currentPlayerId];
    if (currentPlayer == null) {
      return const Scaffold(body: Center(child: Text('Player not found')));
    }

    final otherPlayerIds = gs.game.playerOrder
        .where((id) => id != gs.currentPlayerId)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(context, ref, gs, currentPlayer),
                if (otherPlayerIds.isNotEmpty)
                  _buildOtherPlayers(gs, otherPlayerIds, playerMap),
                _buildDartSlots(gs),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ScoreInputPad(
                      enabled: gs.canThrow,
                      remainingScore: gs.currentRemaining,
                      onThrow: (raw, type) =>
                          ref.read(gameProvider.notifier).recordThrow(raw, type),
                    ),
                  ),
                ),
              ],
            ),
            // Combo banner overlay (only when combo mode is enabled)
            if (gs.game.comboMode && gs.lastCombo != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ComboBanner(
                  combo: gs.lastCombo!,
                  onDismiss: () =>
                      ref.read(gameProvider.notifier).dismissCombo(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    GameState gs,
    Player currentPlayer,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: currentPlayer.color,
                child: Text(
                  currentPlayer.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                currentPlayer.name,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'R${gs.currentRound}',
                style: AppTheme.label,
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.undo_rounded, color: AppColors.textSecondary),
                onPressed: gs.allThrows.isNotEmpty
                    ? () => ref.read(gameProvider.notifier).undoLastThrow()
                    : null,
                tooltip: 'Undo last dart',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${gs.currentRemaining}',
                style: AppTheme.scoreDisplay(56),
              ).animate(key: ValueKey(gs.currentRemaining)).scale(
                    begin: const Offset(1.1, 1.1),
                    end: const Offset(1, 1),
                    duration: 200.ms,
                  ),
              const SizedBox(width: 12),
              if (gs.currentRemaining <= 170)
                CheckoutSuggestion(remaining: gs.currentRemaining),
            ],
          ),
          Text(
            'starts at ${gs.game.startingScore}  ·  double out',
            style: AppTheme.label,
          ),
        ],
      ),
    );
  }

  Widget _buildOtherPlayers(
    GameState gs,
    List<String> otherIds,
    Map<String, Player> playerMap,
  ) {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: otherIds.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final id = otherIds[i];
          final player = playerMap[id];
          if (player == null) return const SizedBox.shrink();
          return SizedBox(
            width: 140,
            child: PlayerScoreCard(
              player: player,
              remainingScore: gs.remainingScores[id] ?? 0,
              isActive: false,
              dartsThrown: 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDartSlots(GameState gs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('This turn:', style: AppTheme.label),
          const SizedBox(width: 12),
          ...List.generate(3, (i) {
            final hasThrow = i < gs.currentTurnThrows.length;
            final t = hasThrow ? gs.currentTurnThrows[i] : null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasThrow
                      ? (t!.isBust
                          ? AppColors.red.withAlpha(30)
                          : AppColors.surfaceElevated)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasThrow
                        ? (t!.isBust ? AppColors.red : AppColors.border)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  hasThrow
                      ? (t!.isBust ? 'BUST' : '+${t.scoreValue}')
                      : '—',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: hasThrow
                        ? (t!.isBust ? AppColors.red : AppColors.gold)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
