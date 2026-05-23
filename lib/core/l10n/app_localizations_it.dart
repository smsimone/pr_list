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
  String get addProject => 'Aggiungi progetto';

  @override
  String get editProject => 'Modifica progetto';

  @override
  String get save => 'Salva';

  @override
  String get cancel => 'Annulla';

  @override
  String get projectAlias => 'Alias progetto';

  @override
  String get projectPath => 'Percorso progetto';

  @override
  String get validationProjectAliasRequired => 'Alias progetto obbligatorio';

  @override
  String get validationProjectPathRequired => 'Percorso progetto obbligatorio';

  @override
  String get validationProjectPathMustBeAbsolute =>
      'Il percorso deve essere assoluto';

  @override
  String get validationProjectPathNotFound => 'La cartella non esiste';

  @override
  String get validationProjectRepoInvalid => 'Repository git non valido';

  @override
  String get validationProjectMissingRemote =>
      'Il repository non ha remote configurati';

  @override
  String get validationProjectNotFound => 'Progetto non trovato';

  @override
  String get pickFolder => 'Scegli cartella';

  @override
  String get createAlias => 'Crea alias';

  @override
  String get branch => 'Branch';

  @override
  String get validationBranchRequired => 'Branch obbligatorio';

  @override
  String get validationBranchNoSpaces => 'Il branch non può contenere spazi';

  @override
  String get validationBranchNotFound =>
      'Branch non presente nella repository del progetto';

  @override
  String get jiraTicket => 'Ticket link';

  @override
  String get prLink => 'Link PR';

  @override
  String get validationInvalidPrUrl => 'URL PR non valido';

  @override
  String get ticketClosed => 'Ticket chiuso';

  @override
  String get viewList => 'Vista lista';

  @override
  String get viewKanban => 'Vista kanban';

  @override
  String get laneUnreleased => 'Non rilasciato';

  @override
  String get laneDev => 'Dev';

  @override
  String get laneUat => 'UAT';

  @override
  String get lanePreprod => 'Preprod';

  @override
  String get schedulerNotScheduled => 'Sync non pianificata';

  @override
  String schedulerCountdown(int minutes, int seconds) {
    return 'Prossimo giro tra ${minutes}m ${seconds}s';
  }

  @override
  String get delete => 'Elimina';

  @override
  String get deletePrTitle => 'Eliminare PR?';

  @override
  String get deletePrMessage => 'Questa azione non può essere annullata.';

  @override
  String get deleteProjectTitle => 'Eliminare progetto?';

  @override
  String get deleteProjectMessage =>
      'Verranno eliminate anche tutte le PR collegate.';

  @override
  String get genericSaveError => 'Salvataggio non riuscito';

  @override
  String get genericDeleteError => 'Eliminazione non riuscita';

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
  String get tabProjects => 'Progetti';

  @override
  String get emptyProjects => 'Nessun progetto';

  @override
  String get emptyState => 'Nessuna PR';

  @override
  String get dashboardUnreleased => 'Ticket non rilasciati';

  @override
  String get dashboardUnclosed => 'Ticket non chiusi';

  @override
  String get tabLogs => 'Log';
}
