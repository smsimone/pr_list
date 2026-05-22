// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PR List';

  @override
  String get tabPrList => 'PR List';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get addPr => 'Add PR';

  @override
  String get editPr => 'Edit PR';

  @override
  String get addProject => 'Add project';

  @override
  String get editProject => 'Edit project';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get projectAlias => 'Project alias';

  @override
  String get projectPath => 'Project path';

  @override
  String get pickFolder => 'Pick folder';

  @override
  String get createAlias => 'Create alias';

  @override
  String get branch => 'Branch';

  @override
  String get jiraTicket => 'Jira ticket';

  @override
  String get prLink => 'PR link';

  @override
  String get ticketClosed => 'Ticket closed';

  @override
  String get providerStatus => 'PR status';

  @override
  String get lastCommit => 'Last commit SHA';

  @override
  String get patRequired => 'Azure PAT is required for sync';

  @override
  String get azurePatTitle => 'Azure PAT';

  @override
  String get azurePatLabel => 'PAT';

  @override
  String get tabProjects => 'Projects';

  @override
  String get emptyProjects => 'No projects yet';

  @override
  String get emptyState => 'No PRs yet';

  @override
  String get dashboardUnreleased => 'Tickets not released';

  @override
  String get dashboardUnclosed => 'Tickets not closed';
}
