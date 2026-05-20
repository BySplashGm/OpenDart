import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opendart/models/settings.dart';
import 'package:uuid/uuid.dart';

class SettingsNotifier extends AsyncNotifier<Settings> {
  final _uuid = const Uuid();

  @override
  Future<Settings> build() async {
    return Settings.basicSetup();
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);
