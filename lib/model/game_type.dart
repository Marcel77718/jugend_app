// 📁 Datei: lib/model/game_type.dart

enum GameType { imposter, werwolf, palermo }

extension GameTypeExtension on GameType {
  String get label {
    switch (this) {
      case GameType.imposter:
        return 'Imposter';
      case GameType.werwolf:
        return 'Werwolf';
      case GameType.palermo:
        return 'Palermo';
    }
  }

  static GameType fromLabel(String value) {
    switch (value.toLowerCase()) {
      case 'imposter':
        return GameType.imposter;
      case 'werwolf':
        return GameType.werwolf;
      case 'palermo':
        return GameType.palermo;
      default:
        throw Exception('Unbekannter Spieltyp: $value');
    }
  }
}
