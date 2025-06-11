// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GatherUp';

  @override
  String get labelPlayers => 'lobbys';

  @override
  String get dialogLeaveLobby => 'Do you really want to leave the lobby?';

  @override
  String get titleLeaveLobby => 'Leave lobby?';

  @override
  String get errorNameTaken => 'Name is already taken.';

  @override
  String get errorLobbyInvalid => '❌ Invalid lobby ID';

  @override
  String get labelLobbyId => 'Lobby ID';

  @override
  String get labelYourName => 'Your name';

  @override
  String get labelReady => 'Ready';

  @override
  String get labelNotReady => 'Not ready';

  @override
  String get labelStartGame => 'Start game';

  @override
  String get labelNameChange => 'Enter new name';

  @override
  String get hintNameInput => 'e.g. Simon';

  @override
  String get labelSave => 'Save';

  @override
  String get labelCancel => 'Cancel';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackFormTitle => 'Your Feedback';

  @override
  String get feedbackName => 'Your name (optional)';

  @override
  String get feedbackMessage => 'Message';

  @override
  String get feedbackMessageRequired => 'Please enter a message.';

  @override
  String get feedbackRating => 'Rating:';

  @override
  String get feedbackSubmit => 'Submit';

  @override
  String get feedbackSuccess => 'Thank you for your feedback!';

  @override
  String get feedbackListTitle => 'Latest feedback';

  @override
  String get feedbackListEmpty => 'No feedback yet.';

  @override
  String get feedbackAnonymous => 'Anonymous';

  @override
  String get loginFailed => 'Login failed. Please check your credentials.';
}
