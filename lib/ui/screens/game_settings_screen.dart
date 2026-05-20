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
          data: (settings) => buildBody(context, ref, settings),
        ),
      ),
    );
  }

  dynamic _createValueSelector(
    BuildContext context,
    WidgetRef ref,
    String key,
    Settings settings,
  ) {
    //var key = settings.settingValues.keys.elementAt(index);
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
    if (value is String) {
      List<String> optionList = [];

      if (key == "defaultGameVariant") {
        optionList = GameRules.variants;
      }

      return DropdownMenu(
        initialSelection: value, //optionList[index],
        dropdownMenuEntries: [
          for (var option in optionList)
            DropdownMenuEntry(
              label: option,
              value: option,
            ),
        ],
        onSelected: (element) {
          setState(() {
            settings.settingValues[key] = element;
          });
        },
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

  Future<void> _showKillDialog(BuildContext context, WidgetRef ref) async {
    //final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete ALL Data?',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        /*content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: 'Player name',
            counterText: '',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),*/
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'false'),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.green),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'true'),
            child: const Text(
              'CONFIRM (WARNING! no more questions beyond this point! Your data WILL be lost!)',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );

    if (result == "true") {
      //Start kill sequence here ...
    }
  }

  Widget createSettingItem(
    BuildContext context,
    WidgetRef ref,
    int index,
    Settings settings,
  ) {
    var key = settings.settingValues.keys.elementAt(index);

    if (key == "deleteAllData") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showKillDialog(context, ref),
          /*Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GameSetupScreen()),
                    )*/
          icon: const Icon(Icons.dangerous, size: 28),
          label: const Text('CLEAR DATA'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            textStyle: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Text(
            key,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _createValueSelector(context, ref, key, settings),
      ],
    );
  }

  Widget buildBody(BuildContext context, WidgetRef ref, Settings settings) {
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
          return createSettingItem(context, ref, index, settings);
        },
      ),
    );
  }
}
