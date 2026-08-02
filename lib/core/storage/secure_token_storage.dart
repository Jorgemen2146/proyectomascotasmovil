import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

/// Wraps [FlutterSecureStorage] to persist only JWT access/refresh tokens.
///
/// User passwords must NEVER be passed to this service or stored anywhere
/// on-device.
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken, value: accessToken),
      _storage.write(key: StorageKeys.refreshToken, value: refreshToken),
    ]);
  }

  Future<String?> readAccessToken() => _storage.read(key: StorageKeys.accessToken);

  Future<String?> readRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken);

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
    ]);
  }

  Future<bool> hasValidSession() async {
    final refreshToken = await readRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }
}
