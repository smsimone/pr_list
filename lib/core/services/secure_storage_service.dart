import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class SecureStorageService {
  final _logger = Logger('SecureStorageService');
  static const _kAzurePatKey = 'azure_pat';
  static const _kJiraPatKey = 'jira_pat';
  static const _kJiraInstanceUrlKey = 'jira_instance_url';
  static const _kJiraEmailKey = 'jira_email';

  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  Future<Either<Failure, String?>> getAzurePat() async {
    _logger.info('Reading Azure PAT from secure storage...');
    try {
      final value = await _storage.read(key: _kAzurePatKey);
      _logger.info(value == null ? 'Azure PAT not found' : 'Azure PAT read successfully');
      return Either.right(value);
    } catch (err) {
      _logger.severe('Failed to read Azure PAT: $err');
      return Either.left(
        Failure(message: 'Failed to read Azure PAT from secure storage', cause: err),
      );
    }
  }

  Future<Either<Failure, void>> setAzurePat(String value) async {
    assert(value.trim().isNotEmpty, 'value must not be empty');
    _logger.info('Saving Azure PAT to secure storage...');
    try {
      await _storage.write(key: _kAzurePatKey, value: value);
      _logger.info('Azure PAT saved successfully');
      return const Either.right(null);
    } catch (err) {
      _logger.severe('Failed to save Azure PAT: $err');
      return Either.left(
        Failure(message: 'Failed to save Azure PAT to secure storage', cause: err),
      );
    }
  }

  Future<Either<Failure, String?>> getJiraPat() async {
    _logger.info('Reading Jira PAT from secure storage...');
    try {
      final value = await _storage.read(key: _kJiraPatKey);
      _logger.info(value == null ? 'Jira PAT not found' : 'Jira PAT read successfully');
      return Either.right(value);
    } catch (err) {
      _logger.severe('Failed to read Jira PAT: $err');
      return Either.left(
        Failure(message: 'Failed to read Jira PAT from secure storage', cause: err),
      );
    }
  }

  Future<Either<Failure, void>> setJiraPat(String value) async {
    assert(value.trim().isNotEmpty, 'value must not be empty');
    _logger.info('Saving Jira PAT to secure storage...');
    try {
      await _storage.write(key: _kJiraPatKey, value: value);
      _logger.info('Jira PAT saved successfully');
      return const Either.right(null);
    } catch (err) {
      _logger.severe('Failed to save Jira PAT: $err');
      return Either.left(
        Failure(message: 'Failed to save Jira PAT to secure storage', cause: err),
      );
    }
  }

  Future<Either<Failure, String?>> getJiraInstanceUrl() async {
    _logger.info('Reading Jira instance URL from secure storage...');
    try {
      final value = await _storage.read(key: _kJiraInstanceUrlKey);
      _logger.info(value == null ? 'Jira instance URL not found' : 'Jira instance URL read successfully');
      return Either.right(value);
    } catch (err) {
      _logger.severe('Failed to read Jira instance URL: $err');
      return Either.left(
        Failure(message: 'Failed to read Jira instance URL from secure storage', cause: err),
      );
    }
  }

  Future<Either<Failure, void>> setJiraInstanceUrl(String value) async {
    assert(value.trim().isNotEmpty, 'value must not be empty');
    _logger.info('Saving Jira instance URL to secure storage...');
    try {
      await _storage.write(key: _kJiraInstanceUrlKey, value: value);
      _logger.info('Jira instance URL saved successfully');
      return const Either.right(null);
    } catch (err) {
      _logger.severe('Failed to save Jira instance URL: $err');
      return Either.left(
        Failure(message: 'Failed to save Jira instance URL to secure storage', cause: err),
      );
    }
  }

  Future<Either<Failure, String?>> getJiraEmail() async {
    _logger.info('Reading Jira email from secure storage...');
    try {
      final value = await _storage.read(key: _kJiraEmailKey);
      _logger.info(value == null ? 'Jira email not found' : 'Jira email read successfully');
      return Either.right(value);
    } catch (err) {
      _logger.severe('Failed to read Jira email: $err');
      return Either.left(
        Failure(message: 'Failed to read Jira email from secure storage', cause: err),
      );
    }
  }

  Future<Either<Failure, void>> setJiraEmail(String value) async {
    assert(value.trim().isNotEmpty, 'value must not be empty');
    _logger.info('Saving Jira email to secure storage...');
    try {
      await _storage.write(key: _kJiraEmailKey, value: value);
      _logger.info('Jira email saved successfully');
      return const Either.right(null);
    } catch (err) {
      _logger.severe('Failed to save Jira email: $err');
      return Either.left(
        Failure(message: 'Failed to save Jira email to secure storage', cause: err),
      );
    }
  }
}
