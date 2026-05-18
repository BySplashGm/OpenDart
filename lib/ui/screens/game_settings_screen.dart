import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opendart/models/game_rules.dart';
import 'package:opendart/models/settings.dart';
import 'package:opendart/providers/settings_provider.dart';
import 'package:opendart/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class GameSettingsScreen extends ConsumerStatefulWidget {
  const GameSettingsScreen({super.key});

  @override
  ConsumerState<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends ConsumerState<GameSettingsScreen> {
  final int _selectedVariant = 501;
  final bool _comboMode = false;
  final List<String> _selectedPlayerIds = [];
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (settings) => _buildBody(context, settings),
        ),
      ),
    );
  }

  dynamic _createValueSelector(int index, Settings settings /*value*/) {
    var key = settings.settingValues.keys.elementAt(index);
    var value = settings.settingValues[key];
    if (value is bool) {
      return Checkbox(
        value: value,
        onChanged: (bool? newValue) {
          setState(() {
            //value = newValue!;
            settings.settingValues[key] = newValue;
          });
        },
      );
    }
    if (value is int) {
      return DropdownMenu(
        initialSelection: GameRules.variants[0],
        dropdownMenuEntries: [
          for (var variant in GameRules.variants)
            DropdownMenuEntry(label: variant.toString(), value: variant),
        ],
      );
    }

    return Text(
      " $value",
      style: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildBody(BuildContext context, Settings settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: settings.settingValues.length,
        itemBuilder: (context, int index) {
          final key = settings.settingValues.keys.elementAt(index);
          var value = settings.settingValues[key];
          var valueDisplay = _createValueSelector(index, settings /*value*/);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                key,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              valueDisplay,
            ],
          );
        },
      ),
    );
  }
}
