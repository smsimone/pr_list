// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'PR List';

  @override
  String get tabPrList => 'PR List';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get addPr => 'Aggiungi PR';

  @override
  String get editPr => 'Modifica PR';

  @override
  String get save => 'Salva';

  @override
  String get cancel => 'Annulla';

  @override
  String get projectAlias => 'Alias progetto';

  @override
  String get branch => 'Branch';

  @override
  String get jiraTicket => 'Ticket Jira';

  @override
  String get prLink => 'Link PR';

  @override
  String get ticketClosed => 'Ticket chiuso';

  @override
  String get providerStatus => 'Stato PR';

  @override
  String get lastCommit => 'Ultimo commit SHA';

  @override
  String get patRequired => 'Azure PAT richiesto per la sync';

  @override
  String get azurePatTitle => 'Azure PAT';

  @override
  String get azurePatLabel => 'PAT';

  @override
  String get dashboardUnreleased => 'Ticket non rilasciati';

  @override
  String get dashboardUnclosed => 'Ticket non chiusi';

  @override
  String get emptyState => 'Nessuna PR';
}
