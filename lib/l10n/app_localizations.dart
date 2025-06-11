import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'GatherUp'**
  String get appTitle;

  /// Label for players in the lobby
  ///
  /// In en, this message translates to:
  /// **'lobbys'**
  String get labelPlayers;

  /// Dialog text for leaving the lobby
  ///
  /// In en, this message translates to:
  /// **'Do you really want to leave the lobby?'**
  String get dialogLeaveLobby;

  /// Title for leave lobby dialog
  ///
  /// In en, this message translates to:
  /// **'Leave lobby?'**
  String get titleLeaveLobby;

  /// Error message when name is taken
  ///
  /// In en, this message translates to:
  /// **'Name is already taken.'**
  String get errorNameTaken;

  /// Error message for invalid lobby ID
  ///
  /// In en, this message translates to:
  /// **'❌ Invalid lobby ID'**
  String get errorLobbyInvalid;

  /// Label for lobby ID
  ///
  /// In en, this message translates to:
  /// **'Lobby ID'**
  String get labelLobbyId;

  /// Label for your name
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get labelYourName;

  /// Button text for ready
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get labelReady;

  /// Button text for not ready
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get labelNotReady;

  /// Button text for start game
  ///
  /// In en, this message translates to:
  /// **'Start game'**
  String get labelStartGame;

  /// Label for name change
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get labelNameChange;

  /// Placeholder for name input
  ///
  /// In en, this message translates to:
  /// **'e.g. Simon'**
  String get hintNameInput;

  /// Button text for save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get labelSave;

  /// Button text for cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get labelCancel;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Feedback'**
  String get feedbackFormTitle;

  /// No description provided for @feedbackName.
  ///
  /// In en, this message translates to:
  /// **'Your name (optional)'**
  String get feedbackName;

  /// No description provided for @feedbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get feedbackMessage;

  /// No description provided for @feedbackMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message.'**
  String get feedbackMessageRequired;

  /// No description provided for @feedbackRating.
  ///
  /// In en, this message translates to:
  /// **'Rating:'**
  String get feedbackRating;

  /// No description provided for @feedbackSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get feedbackSubmit;

  /// No description provided for @feedbackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get feedbackSuccess;

  /// No description provided for @feedbackListTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest feedback'**
  String get feedbackListTitle;

  /// No description provided for @feedbackListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No feedback yet.'**
  String get feedbackListEmpty;

  /// No description provided for @feedbackAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get feedbackAnonymous;

  /// General error message for login failure
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get loginFailed;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
