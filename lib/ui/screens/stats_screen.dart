import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/game.dart';
import '../../models/player.dart';
import '../../providers/players_provider.dart';
import '../../providers/stats_provider.dart';
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.gold,
          labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(text: 'PLAYERS'),
            Tab(text: 'HISTORY'),
            Tab(text: 'LEADERBOARD'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _PlayerStatsTab(),
          _HistoryTab(),
          _LeaderboardTab(),
        ],
      ),
    );
  }
}

class _PlayerStatsTab extends ConsumerStatefulWidget {
  const _PlayerStatsTab();

  @override
  ConsumerState<_PlayerStatsTab> createState() => _PlayerStatsTabState();
}

class _PlayerStatsTabState extends ConsumerState<_PlayerStatsTab> {
  String? _selectedPlayerId;

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);

    return playersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (players) {
        if (players.isEmpty) {
          return Center(
            child: Text('No players yet', style: AppTheme.label),
          );
        }
        _selectedPlayerId ??= players.first.id;

        return Column(
          children: [
            _buildPlayerPicker(players),
            Expanded(child: _buildStats()),
          ],
        );
      },
    );
  }

  Widget _buildPlayerPicker(List<Player> players) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: players.map((p) {
          final selected = _selectedPlayerId == p.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPlayerId = p.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? p.color.withAlpha(30) : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? p.color : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  p.name,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? p.color : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStats() {
    if (_selectedPlayerId == null) return const SizedBox.shrink();
    final statsAsync = ref.watch(playerStatsProvider(_selectedPlayerId!));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (stats) => _buildStatsContent(stats),
    );
  }

  Widget _buildStatsContent(PlayerStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              StatCard(
                label: 'Avg PPD',
                value: stats.averagePPD.toStringAsFixed(2),
                icon: Icons.bar_chart_rounded,
                valueColor: AppColors.gold,
              ),
              StatCard(
                label: 'Win Rate',
                value: '${(stats.checkoutRate * 100).toStringAsFixed(0)}%',
                icon: Icons.emoji_events_outlined,
                valueColor: AppColors.green,
              ),
              StatCard(
                label: 'Games',
                value: '${stats.totalGames}',
                icon: Icons.sports_score_rounded,
              ),
              StatCard(
                label: 'Wins',
                value: '${stats.totalWins}',
                icon: Icons.star_outline_rounded,
                valueColor: AppColors.gold,
              ),
              StatCard(
                label: 'Best Turn',
                value: '${stats.highestTurn}',
                icon: Icons.trending_up_rounded,
                valueColor: AppColors.red,
              ),
              StatCard(
                label: '180s',
                value: '${stats.count180s}',
                icon: Icons.auto_awesome_rounded,
                valueColor: AppColors.purple,
              ),
            ],
          ),
          if (stats.zoneAccuracy.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildZoneAccuracy(stats),
          ],
          if (stats.topCheckouts.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildTopCheckouts(stats),
          ],
        ],
      ),
    );
  }

  Widget _buildZoneAccuracy(PlayerStats stats) {
    final total = stats.zoneAccuracy.values.fold(0, (s, v) => s + v);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ZONE BREAKDOWN', style: AppTheme.label.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 14),
          ...stats.zoneAccuracy.entries.map((e) {
            final pct = total > 0 ? e.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key.toUpperCase(),
                          style: AppTheme.label.copyWith(fontSize: 12)),
                      Text('${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: AppTheme.label.copyWith(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.border,
                      color: _zoneColor(e.key),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _zoneColor(String zone) => switch (zone) {
        'triple' => AppColors.red,
        'double' => AppColors.gold,
        'bull' => AppColors.purple,
        'outer_bull' => AppColors.blue,
        'miss' => AppColors.textSecondary,
        _ => AppColors.green,
      };

  Widget _buildTopCheckouts(PlayerStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOP CHECKOUTS', style: AppTheme.label.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stats.topCheckouts.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withAlpha(80)),
                ),
                child: Text(
                  c,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(gameHistoryProvider);
    final playersAsync = ref.watch(playersProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (games) => playersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (players) {
          final playerMap = {for (final p in players) p.id: p};
          if (games.isEmpty) {
            return Center(
              child: Text('No completed games yet', style: AppTheme.label),
            );
          }
          return _buildList(games, playerMap);
        },
      ),
    );
  }

  Widget _buildList(List<Game> games, Map<String, Player> playerMap) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: games.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _GameHistoryTile(game: games[i], playerMap: playerMap),
    );
  }
}

class _GameHistoryTile extends StatelessWidget {
  final Game game;
  final Map<String, Player> playerMap;

  const _GameHistoryTile({required this.game, required this.playerMap});

  @override
  Widget build(BuildContext context) {
    final winner = playerMap[game.winnerId];
    final fmt = DateFormat('MMM d, y  HH:mm');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${game.startingScore}',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (winner != null)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: winner.color,
                        child: Text(
                          winner.name[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${winner.name} won',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 2),
                Text(
                  game.endDate != null ? fmt.format(game.endDate!) : '',
                  style: AppTheme.label.copyWith(fontSize: 11),
                ),
                Text(
                  '${game.playerOrder.length} players',
                  style: AppTheme.label.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playersProvider);

    return playersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (players) {
        if (players.isEmpty) {
          return Center(child: Text('No players yet', style: AppTheme.label));
        }
        return _LeaderboardList(players: players);
      },
    );
  }
}

class _LeaderboardList extends ConsumerWidget {
  final List<Player> players;

  const _LeaderboardList({required this.players});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all player stats
    final statsMap = {
      for (final p in players)
        p.id: ref.watch(playerStatsProvider(p.id)),
    };

    // Sort by PPD descending (only players with data)
    final sorted = [...players]..sort((a, b) {
        final aPPD = statsMap[a.id]?.valueOrNull?.averagePPD ?? 0;
        final bPPD = statsMap[b.id]?.valueOrNull?.averagePPD ?? 0;
        return bPPD.compareTo(aPPD);
      });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final player = sorted[i];
        final stats = statsMap[player.id]?.valueOrNull;
        final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: i == 0 ? AppColors.gold.withAlpha(10) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: i == 0 ? AppColors.gold.withAlpha(80) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  medal,
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
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
                child: Text(
                  player.name,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stats != null ? stats.averagePPD.toStringAsFixed(2) : '—',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: i == 0 ? AppColors.gold : AppColors.textPrimary,
                    ),
                  ),
                  Text('PPD', style: AppTheme.label.copyWith(fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
