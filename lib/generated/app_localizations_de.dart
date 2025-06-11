// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'GatherUp';

  @override
  String get labelPlayers => 'Lobbies';

  @override
  String get dialogLeaveLobby => 'Willst du die Lobby wirklich verlassen?';

  @override
  String get titleLeaveLobby => 'Lobby verlassen?';

  @override
  String get errorNameTaken => 'Name ist bereits vergeben.';

  @override
  String get errorLobbyInvalid => '❌ Ungültige Lobby-ID';

  @override
  String get labelLobbyId => 'Lobby-ID';

  @override
  String get labelYourName => 'Du heißt';

  @override
  String get labelReady => 'Bereit';

  @override
  String get labelNotReady => 'Nicht bereit';

  @override
  String get labelStartGame => 'Spiel starten';

  @override
  String get labelNameChange => 'Neuen Namen eingeben';

  @override
  String get hintNameInput => 'z. B. Simon';

  @override
  String get labelSave => 'Speichern';

  @override
  String get labelCancel => 'Abbrechen';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackFormTitle => 'Dein Feedback';

  @override
  String get feedbackName => 'Dein Name (optional)';

  @override
  String get feedbackMessage => 'Nachricht';

  @override
  String get feedbackMessageRequired => 'Bitte gib eine Nachricht ein.';

  @override
  String get feedbackRating => 'Bewertung:';

  @override
  String get feedbackSubmit => 'Absenden';

  @override
  String get feedbackSuccess => 'Danke für dein Feedback!';

  @override
  String get feedbackListTitle => 'Letzte Rückmeldungen';

  @override
  String get feedbackListEmpty => 'Noch kein Feedback vorhanden.';

  @override
  String get feedbackAnonymous => 'Anonym';

  @override
  String get loginFailed => 'Login fehlgeschlagen. Bitte überprüfe deine Eingaben.';
}
