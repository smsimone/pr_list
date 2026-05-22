import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class SecureStorageService {
  static const String _kAzurePatKey = 'azure_pat';

  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  Future<Either<Failure, String?>> getAzurePat() async {
    try {
      final String? value = await _storage.read(key: _kAzurePatKey);
      return Either.right(value);
    } catch (err) {
      return Either.left(
        Failure(message: 'Failed to read PAT from secure storage', cause: err),
      );
    }
  }

  Future<Either<Failure, void>> setAzurePat(String value) async {
    assert(value.trim().isNotEmpty, 'value must not be empty');
    try {
      await _storage.write(key: _kAzurePatKey, value: value);
      return const Either.right(null);
    } catch (err) {
      return Either.left(
        Failure(message: 'Failed to save PAT to secure storage', cause: err),
      );
    }
  }
}
