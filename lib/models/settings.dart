class Settings {
  /*bool soundEffects;
  bool hapticFeedback;
  int defaultGameVariant;
  bool defaultComboMode;
  bool scoreConfirmation;
  bool clearData;*/
  final Map<String, dynamic> _settingValues = {};
  Map<String, dynamic> get settingValues => _settingValues;

  void addValue(String key, var value) {
    _settingValues[key] = value;
  }

  Settings(
    /*{
    required this.soundEffects,
    required this.hapticFeedback,
    required this.defaultGameVariant,
    required this.defaultComboMode,
    required this.scoreConfirmation,
    required this.clearData,
  }*/
  );

  /*Map<String, dynamic> toMap() => {
    'soundEffects': soundEffects,
    'hapticFeedback': hapticFeedback,
    'defaultGameVariant': defaultGameVariant,
    'defaultComboMode': defaultComboMode,
    'scoreConfirmation': scoreConfirmation,
    'clearData': clearData,
  };

  factory Settings.fromMap(Map<String, dynamic> map) => Settings(
    soundEffects: map['soundEffects'],
    hapticFeedback: map['hapticFeedback'],
    defaultGameVariant: map['defaultGameVariant'],
    defaultComboMode: map['defaultComboMode'],
    scoreConfirmation: map['scoreConfirmation'],
    clearData: map['clearData'],
  );*/

  //TODO Maybe load this from a separate file later on
  factory Settings.basicSetup() {
    Settings basicSettings = Settings();
    basicSettings.addValue('soundEffects', false);
    basicSettings.addValue('hapticFeedback', false);
    basicSettings.addValue('defaultGameVariant', "501");
    basicSettings.addValue('defaultComboMode', false);
    basicSettings.addValue('scoreConfirmation', false);
    basicSettings.addValue('deleteAllData', false);
    return basicSettings;
  }
}
