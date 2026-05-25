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

  @override
  String get envMappingsTitle => 'Mapping ambienti';

  @override
  String get envMappingNameLabel => 'Nome';

  @override
  String get envMappingPatternLabel => 'Suffisso branch';

  @override
  String get envMappingDefault => 'non impostato';

  @override
  String get genericError => 'Si è verificato un errore';

  @override
  String get envSettings => 'Ambienti';

  @override
  String get updateAvailableTitle => 'Aggiornamento disponibile';

  @override
  String updateAvailableBody(String version) {
    return 'Versione $version disponibile. Scaricare ora?';
  }

  @override
  String get updateDownloading => 'Download aggiornamento...';

  @override
  String get updateInstalling => 'Installazione aggiornamento...';

  @override
  String get updateError => 'Aggiornamento fallito';

  @override
  String get updateErrorUnknown => 'Errore sconosciuto';

  @override
  String get actionSkip => 'Ignora';

  @override
  String get actionDownload => 'Scarica';

  @override
  String get actionClose => 'Chiudi';

  @override
  String get filterProject => 'Filtra per progetto';

  @override
  String get filterTicketStatus => 'Stato ticket';

  @override
  String get ticketStatusAll => 'Tutti';

  @override
  String get ticketStatusOpen => 'Aperto';

  @override
  String get ticketStatusClosed => 'Chiuso';

  @override
  String get ticketStatusWithout => 'Senza ticket';

  @override
  String get credentialsTitle => 'Credenziali';

  @override
  String get serviceName => 'Servizio';

  @override
  String get token => 'Token';

  @override
  String get jiraInstanceUrlLabel => 'URL istanza';

  @override
  String get ticketSyncStatus => 'Stato ticket';
}
