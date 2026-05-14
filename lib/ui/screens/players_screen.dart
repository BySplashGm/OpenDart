import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_color_picker_plus/flutter_color_picker_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;

import '../../models/player.dart';
import '../../providers/players_provider.dart';
import '../../theme/app_theme.dart';

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Players')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      body: playersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (players) => players.isEmpty
            ? _buildEmpty(context, ref)
            : _buildList(context, ref, players),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('No players yet', style: AppTheme.label),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showAddDialog(context, ref),
            child: const Text('Add First Player'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Player> players) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _PlayerTile(player: players[i]),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final emojiController = TextEditingController();
    Color playerColor = AppColors.red;
    //String playerEmoji = '🎯';
    emojiController.text = '🎯';
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'New Player',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 20,
                decoration: const InputDecoration(
                  hintText: 'Player name',
                  counterText: '',
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
              ),
              SizedBox(height: 8),
              ColorPicker(
                pickerColor: playerColor,
                onColorChanged: (c) {
                  playerColor = c;
                },
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 100,
                width: 640,
                child: EmojiPicker(
                  onEmojiSelected: (c, e) {
                    //playerEmoji = e.emoji;
                  },
                  onBackspacePressed: null,
                  textEditingController: emojiController,
                  config: Config(
                    height: 64,
                    //bgColor: const Color(0xFFF2F2F2),
                    checkPlatformCompatibility: true,
                    emojiSet: (Locale locale) {
                      return AppEmojis.emojiSetDarts;
                    },
                    emojiViewConfig: EmojiViewConfig(
                      // Issue: https://github.com/flutter/flutter/issues/28894
                      emojiSizeMax:
                          28 *
                          (foundation.defaultTargetPlatform ==
                                  TargetPlatform.iOS
                              ? 1.20
                              : 1.0),
                      replaceEmojiOnLimitExceed: true,
                      recentsLimit: 8,
                    ),
                    viewOrderConfig: const ViewOrderConfig(
                      top: EmojiPickerItem.emojiView,
                      middle: EmojiPickerItem.categoryBar,
                      bottom: EmojiPickerItem.searchBar,
                    ),
                    skinToneConfig: const SkinToneConfig(),
                    categoryViewConfig: const CategoryViewConfig(),
                    bottomActionBarConfig: const BottomActionBarConfig(
                      showBackspaceButton: false,
                      showSearchViewButton: false,
                    ),
                    searchViewConfig: const SearchViewConfig(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await ref
          .read(playersProvider.notifier)
          .addPlayer(
            name,
            playerColor.toARGB32(),
            emojiController.text.characters.last,
          );
    }
  }
}

class _PlayerTile extends ConsumerWidget {
  final Player player;

  const _PlayerTile({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(player.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.red.withAlpha(40),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              'Delete ${player.name}?',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            content: const Text(
              'Their game history will still be preserved.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) =>
          ref.read(playersProvider.notifier).deletePlayer(player.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: player.color,
              child: Text(
                (player.avatarEmoji /*?? player.name[0].toUpperCase()*/ ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                player.name,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: () => _showRenameDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: player.name);
    final emojiController = TextEditingController(text: player.avatarEmoji);
    Color playerColor = Color(player.avatarColor);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Rename Player',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 20,
              decoration: const InputDecoration(counterText: ''),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
            SizedBox(height: 8),
            ColorPicker(
              pickerColor: playerColor,
              onColorChanged: (c) {
                playerColor = c;
              },
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 100,
              width: 640,
              child: EmojiPicker(
                onEmojiSelected: (c, e) {
                  //playerEmoji = e.emoji;
                },
                onBackspacePressed: null,
                textEditingController: emojiController,
                config: Config(
                  height: 64,
                  //bgColor: const Color(0xFFF2F2F2),
                  checkPlatformCompatibility: true,
                  emojiSet: (Locale locale) {
                    return AppEmojis.emojiSetDarts;
                  },
                  emojiViewConfig: EmojiViewConfig(
                    // Issue: https://github.com/flutter/flutter/issues/28894
                    emojiSizeMax:
                        28 *
                        (foundation.defaultTargetPlatform == TargetPlatform.iOS
                            ? 1.20
                            : 1.0),
                    replaceEmojiOnLimitExceed: true,
                    recentsLimit: 8,
                  ),
                  viewOrderConfig: const ViewOrderConfig(
                    top: EmojiPickerItem.emojiView,
                    middle: EmojiPickerItem.categoryBar,
                    bottom: EmojiPickerItem.searchBar,
                  ),
                  skinToneConfig: const SkinToneConfig(),
                  categoryViewConfig: const CategoryViewConfig(),
                  bottomActionBarConfig: const BottomActionBarConfig(
                    showBackspaceButton: false,
                    showSearchViewButton: false,
                  ),
                  searchViewConfig: const SearchViewConfig(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if ((name != null && name.isNotEmpty) &&
        ((name != player.name) ||
            (playerColor.toARGB32() != player.avatarColor) ||
            (emojiController.text.characters.last != player.avatarEmoji))) {
      await ref
          .read(playersProvider.notifier)
          .updatePlayer(
            player.copyWith(
              name: name,
              avatarColor: playerColor.toARGB32(),
              avatar: emojiController.text.characters.last,
            ),
          );
    }
  }
}
