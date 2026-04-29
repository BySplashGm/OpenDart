import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../models/throw_record.dart';
import '../../providers/game_provider.dart';
import '../../providers/players_provider.dart';
import '../../theme/app_theme.dart';
import 'home_screen.dart';
import 'game_setup_screen.dart';

class GameSummaryScreen extends ConsumerStatefulWidget {
  const GameSummaryScreen({super.key});

  @override
  ConsumerState<GameSummaryScreen> createState() => _GameSummaryScreenState();
}

class _GameSummaryScreenState extends ConsumerState<GameSummaryScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * cos(step),
        halfWidth + externalRadius * sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final playersAsync = ref.watch(playersProvider);

    if (gameState == null) {
      return const Scaffold(body: Center(child: Text('No game data')));
    }

    return playersAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (players) {
        final playerMap = {for (final p in players) p.id: p};
        return Stack(
          children: [
            _buildSummary(context, gameState, playerMap),

            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                blastDirection: -pi / 2,
                minBlastForce: 15,
                maxBlastForce: 20,
                emissionFrequency: 0.015,
                minimumSize: const Size(25, 25),
                maximumSize: const Size(50, 50),
                numberOfParticles: 30,
                gravity: 0.05,
                colors: const [AppColors.gold, Colors.white],
                createParticlePath: drawStar,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummary(
    BuildContext context,
    GameState gs,
    Map<String, Player> playerMap,
  ) {
    final winner = playerMap[gs.game.winnerId];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (winner != null) _buildWinnerCard(winner),
                    const SizedBox(height: 24),
                    _buildStatsGrid(gs, playerMap),
                    const SizedBox(height: 24),
                    _buildTurnBreakdown(gs, playerMap),
                    const SizedBox(height: 32),
                    _buildActions(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerCard(Player winner) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: AppTheme.glowCard,
          child: Column(
            children: [
              Text('🎯', style: const TextStyle(fontSize: 48))
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: 800.ms,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.1, 1.1),
                    end: const Offset(0.9, 0.9),
                    duration: 800.ms,
                  ),
              const SizedBox(height: 12),
              Text(
                'WINNER',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                winner.name,
                style: GoogleFonts.nunito(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          curve: Curves.elasticOut,
          duration: 700.ms,
        );
  }

  Widget _buildStatsGrid(GameState gs, Map<String, Player> playerMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PLAYER STATS',
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...gs.game.playerOrder.map((id) {
          final player = playerMap[id];
          if (player == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PlayerSummaryCard(
              player: player,
              throws: gs.allThrows.where((t) => t.playerId == id).toList(),
              isWinner: gs.game.winnerId == id,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTurnBreakdown(GameState gs, Map<String, Player> playerMap) {
    // Group throws by round and player
    final rounds = <int, Map<String, List<ThrowRecord>>>{};
    for (final t in gs.allThrows) {
      rounds.putIfAbsent(t.round, () => {});
      rounds[t.round]!.putIfAbsent(t.playerId, () => []).add(t);
    }

    if (rounds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TURN BREAKDOWN',
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: rounds.entries.take(20).map((e) {
              final round = e.key;
              final playerThrows = e.value;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        'R$round',
                        style: AppTheme.label.copyWith(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: gs.game.playerOrder
                            .where((id) => playerThrows.containsKey(id))
                            .map((id) {
                              final player = playerMap[id];
                              final darts = playerThrows[id]!;
                              final total = darts
                                  .where((t) => !t.isBust)
                                  .fold(0, (s, t) => s + t.scoreValue);
                              final hasBust = darts.any((t) => t.isBust);

                              return Row(
                                children: [
                                  if (player != null)
                                    CircleAvatar(
                                      radius: 8,
                                      backgroundColor: player.color,
                                      child: Text(
                                        player.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 8,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  Text(
                                    darts
                                        .map(
                                          (t) => t.isBust
                                              ? 'BUST'
                                              : t.displayLabel,
                                        )
                                        .join(' · '),
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: hasBust
                                          ? AppColors.red
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    hasBust ? 'BUST' : '+$total',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: hasBust
                                          ? AppColors.red
                                          : AppColors.gold,
                                    ),
                                  ),
                                ],
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(gameProvider.notifier).reset();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const GameSetupScreen()),
              );
            },
            icon: const Icon(Icons.replay_rounded),
            label: const Text('PLAY AGAIN'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              ref.read(gameProvider.notifier).reset();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
            child: const Text('Back to Home'),
          ),
        ),
      ],
    );
  }
}

class _PlayerSummaryCard extends StatelessWidget {
  final Player player;
  final List<ThrowRecord> throws;
  final bool isWinner;

  const _PlayerSummaryCard({
    required this.player,
    required this.throws,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final valid = throws.where((t) => !t.isBust).toList();
    final totalScore = valid.fold(0, (s, t) => s + t.scoreValue);
    final ppd = valid.isEmpty ? 0.0 : totalScore / valid.length;
    final busts = throws.where((t) => t.isBust).length;
    final combos = throws.where((t) => t.comboMultiplier > 1.0).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWinner ? player.color.withAlpha(15) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWinner ? player.color : AppColors.border,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: player.color,
            child: Text(
              player.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.name,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isWinner) ...[
                      const SizedBox(width: 6),
                      const Text('🏆', style: TextStyle(fontSize: 14)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'PPD: ${ppd.toStringAsFixed(1)}  ·  Darts: ${throws.length}  ·  Busts: $busts${combos > 0 ? '  ·  Combos: $combos' : ''}',
                  style: AppTheme.label.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
