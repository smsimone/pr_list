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
  String get validationProjectAliasRequired => 'Project alias is required';

  @override
  String get validationProjectPathRequired => 'Project path is required';

  @override
  String get validationProjectPathMustBeAbsolute => 'Path must be absolute';

  @override
  String get validationProjectPathNotFound => 'Folder does not exist';

  @override
  String get validationProjectRepoInvalid => 'Invalid git repository';

  @override
  String get validationProjectMissingRemote =>
      'Git repository has no configured remotes';

  @override
  String get validationProjectNotFound => 'Project not found';

  @override
  String get pickFolder => 'Pick folder';

  @override
  String get createAlias => 'Create alias';

  @override
  String get jiraTicket => 'Ticket link';

  @override
  String get prLink => 'PR link';

  @override
  String get validationInvalidPrUrl => 'Invalid PR URL';

  @override
  String get ticketClosed => 'Ticket closed';

  @override
  String get viewList => 'List view';

  @override
  String get viewKanban => 'Kanban view';

  @override
  String get laneUnreleased => 'Unreleased';

  @override
  String get schedulerNotScheduled => 'Sync not scheduled';

  @override
  String schedulerCountdown(int minutes, int seconds) {
    return 'Next run in ${minutes}m ${seconds}s';
  }

  @override
  String get delete => 'Delete';

  @override
  String get deletePrTitle => 'Delete PR?';

  @override
  String get deletePrMessage => 'This action cannot be undone.';

  @override
  String get deleteProjectTitle => 'Delete project?';

  @override
  String get deleteProjectMessage => 'All linked PRs will also be deleted.';

  @override
  String get genericSaveError => 'Save failed';

  @override
  String get genericDeleteError => 'Delete failed';

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

  @override
  String get tabLogs => 'Logs';

  @override
  String get envMappingsTitle => 'Environment mappings';

  @override
  String get envMappingNameLabel => 'Name';

  @override
  String get envMappingPatternLabel => 'Branch suffix';

  @override
  String get envMappingDefault => 'not set';

  @override
  String get genericError => 'An error occurred';

  @override
  String get envSettings => 'Environments';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String updateAvailableBody(String version) {
    return 'Version $version is available. Download now?';
  }

  @override
  String get updateDownloading => 'Downloading update...';

  @override
  String get updateInstalling => 'Installing update...';

  @override
  String get updateError => 'Update failed';

  @override
  String get updateErrorUnknown => 'Unknown error';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionDownload => 'Download';

  @override
  String get actionClose => 'Close';

  @override
  String get filterProject => 'Filter by project';

  @override
  String get filterTicketStatus => 'Ticket status';

  @override
  String get ticketStatusAll => 'All';

  @override
  String get ticketStatusOpen => 'Open';

  @override
  String get ticketStatusClosed => 'Closed';

  @override
  String get ticketStatusWithout => 'Without ticket';

  @override
  String get credentialsTitle => 'Credentials';

  @override
  String get serviceName => 'Service';

  @override
  String get token => 'Token';

  @override
  String get jiraInstanceUrlLabel => 'Instance URL';

  @override
  String get ticketSyncStatus => 'Ticket status';

  @override
  String get aboutTitle => 'About';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutDescription =>
      'A simple PR management tool for Azure DevOps.';
}
