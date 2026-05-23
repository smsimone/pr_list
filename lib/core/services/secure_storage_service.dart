import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class SecureStorageService {
  final _logger = Logger('SecureStorageService');
  static const _kAzurePatKey = 'azure_pat';

  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  Future<Either<Failure, String?>> getAzurePat() async {
    _logger.info('Reading PAT from secure storage...');
    try {
      final value = await _storage.read(key: _kAzurePatKey);
      _logger.info(value == null ? 'PAT not found in storage' : 'PAT read successfully');
      return Either.right(value);
    } catch (err) {
      _logger.severe('Failed to read PAT: $err');
      return Either.left(
        Failure(message: 'Failed to read PAT from secure storage', cause: err),
      );
    }
  }

  Future<Either<Failure, void>> setAzurePat(String value) async {
    assert(value.trim().isNotEmpty, 'value must not be empty');
    _logger.info('Saving PAT to secure storage...');
    try {
      await _storage.write(key: _kAzurePatKey, value: value);
      _logger.info('PAT saved successfully');
      return const Either.right(null);
    } catch (err) {
      _logger.severe('Failed to save PAT: $err');
      return Either.left(
        Failure(message: 'Failed to save PAT to secure storage', cause: err),
      );
    }
  }
}
