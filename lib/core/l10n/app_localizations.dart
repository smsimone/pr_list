import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('it'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PR List'**
  String get appTitle;

  /// No description provided for @tabPrList.
  ///
  /// In en, this message translates to:
  /// **'PR List'**
  String get tabPrList;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @addPr.
  ///
  /// In en, this message translates to:
  /// **'Add PR'**
  String get addPr;

  /// No description provided for @editPr.
  ///
  /// In en, this message translates to:
  /// **'Edit PR'**
  String get editPr;

  /// No description provided for @addProject.
  ///
  /// In en, this message translates to:
  /// **'Add project'**
  String get addProject;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get editProject;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @projectAlias.
  ///
  /// In en, this message translates to:
  /// **'Project alias'**
  String get projectAlias;

  /// No description provided for @projectPath.
  ///
  /// In en, this message translates to:
  /// **'Project path'**
  String get projectPath;

  /// No description provided for @validationProjectAliasRequired.
  ///
  /// In en, this message translates to:
  /// **'Project alias is required'**
  String get validationProjectAliasRequired;

  /// No description provided for @validationProjectPathRequired.
  ///
  /// In en, this message translates to:
  /// **'Project path is required'**
  String get validationProjectPathRequired;

  /// No description provided for @validationProjectPathMustBeAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Path must be absolute'**
  String get validationProjectPathMustBeAbsolute;

  /// No description provided for @validationProjectPathNotFound.
  ///
  /// In en, this message translates to:
  /// **'Folder does not exist'**
  String get validationProjectPathNotFound;

  /// No description provided for @validationProjectRepoInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid git repository'**
  String get validationProjectRepoInvalid;

  /// No description provided for @validationProjectMissingRemote.
  ///
  /// In en, this message translates to:
  /// **'Git repository has no configured remotes'**
  String get validationProjectMissingRemote;

  /// No description provided for @validationProjectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Project not found'**
  String get validationProjectNotFound;

  /// No description provided for @pickFolder.
  ///
  /// In en, this message translates to:
  /// **'Pick folder'**
  String get pickFolder;

  /// No description provided for @createAlias.
  ///
  /// In en, this message translates to:
  /// **'Create alias'**
  String get createAlias;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @validationBranchRequired.
  ///
  /// In en, this message translates to:
  /// **'Branch is required'**
  String get validationBranchRequired;

  /// No description provided for @validationBranchNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'Branch cannot contain spaces'**
  String get validationBranchNoSpaces;

  /// No description provided for @validationBranchNotFound.
  ///
  /// In en, this message translates to:
  /// **'Branch does not exist in project repository'**
  String get validationBranchNotFound;

  /// No description provided for @jiraTicket.
  ///
  /// In en, this message translates to:
  /// **'Ticket link'**
  String get jiraTicket;

  /// No description provided for @prLink.
  ///
  /// In en, this message translates to:
  /// **'PR link'**
  String get prLink;

  /// No description provided for @validationInvalidPrUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid PR URL'**
  String get validationInvalidPrUrl;

  /// No description provided for @ticketClosed.
  ///
  /// In en, this message translates to:
  /// **'Ticket closed'**
  String get ticketClosed;

  /// No description provided for @viewList.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get viewList;

  /// No description provided for @viewKanban.
  ///
  /// In en, this message translates to:
  /// **'Kanban view'**
  String get viewKanban;

  /// No description provided for @laneUnreleased.
  ///
  /// In en, this message translates to:
  /// **'Unreleased'**
  String get laneUnreleased;

  /// No description provided for @laneDev.
  ///
  /// In en, this message translates to:
  /// **'Dev'**
  String get laneDev;

  /// No description provided for @laneUat.
  ///
  /// In en, this message translates to:
  /// **'UAT'**
  String get laneUat;

  /// No description provided for @lanePreprod.
  ///
  /// In en, this message translates to:
  /// **'Preprod'**
  String get lanePreprod;

  /// No description provided for @schedulerNotScheduled.
  ///
  /// In en, this message translates to:
  /// **'Sync not scheduled'**
  String get schedulerNotScheduled;

  /// No description provided for @schedulerCountdown.
  ///
  /// In en, this message translates to:
  /// **'Next run in {minutes}m {seconds}s'**
  String schedulerCountdown(int minutes, int seconds);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deletePrTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete PR?'**
  String get deletePrTitle;

  /// No description provided for @deletePrMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deletePrMessage;

  /// No description provided for @deleteProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete project?'**
  String get deleteProjectTitle;

  /// No description provided for @deleteProjectMessage.
  ///
  /// In en, this message translates to:
  /// **'All linked PRs will also be deleted.'**
  String get deleteProjectMessage;

  /// No description provided for @genericSaveError.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get genericSaveError;

  /// No description provided for @genericDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get genericDeleteError;

  /// No description provided for @providerStatus.
  ///
  /// In en, this message translates to:
  /// **'PR status'**
  String get providerStatus;

  /// No description provided for @lastCommit.
  ///
  /// In en, this message translates to:
  /// **'Last commit SHA'**
  String get lastCommit;

  /// No description provided for @patRequired.
  ///
  /// In en, this message translates to:
  /// **'Azure PAT is required for sync'**
  String get patRequired;

  /// No description provided for @azurePatTitle.
  ///
  /// In en, this message translates to:
  /// **'Azure PAT'**
  String get azurePatTitle;

  /// No description provided for @azurePatLabel.
  ///
  /// In en, this message translates to:
  /// **'PAT'**
  String get azurePatLabel;

  /// No description provided for @tabProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get tabProjects;

  /// No description provided for @emptyProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get emptyProjects;

  /// No description provided for @emptyState.
  ///
  /// In en, this message translates to:
  /// **'No PRs yet'**
  String get emptyState;

  /// No description provided for @dashboardUnreleased.
  ///
  /// In en, this message translates to:
  /// **'Tickets not released'**
  String get dashboardUnreleased;

  /// No description provided for @dashboardUnclosed.
  ///
  /// In en, this message translates to:
  /// **'Tickets not closed'**
  String get dashboardUnclosed;

  /// No description provided for @tabLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get tabLogs;

  /// No description provided for @envMappingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Environment mappings'**
  String get envMappingsTitle;

  /// No description provided for @envMappingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get envMappingNameLabel;

  /// No description provided for @envMappingPatternLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch suffix'**
  String get envMappingPatternLabel;

  /// No description provided for @envMappingDefault.
  ///
  /// In en, this message translates to:
  /// **'not set'**
  String get envMappingDefault;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get genericError;

  /// No description provided for @envSettings.
  ///
  /// In en, this message translates to:
  /// **'Environments'**
  String get envSettings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
