import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A secure storage utility class for storing sensitive data
class SecureStorage {
  static const _keyAuthToken = 'auth_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserData = 'user_data';
  
  final FlutterSecureStorage _storage;
  
  /// Creates a new instance of [SecureStorage]
  const SecureStorage() : _storage = const FlutterSecureStorage();

  /// Saves the authentication token securely
  Future<void> saveAuthToken(String token) async {
    try {
      await _storage.write(key: _keyAuthToken, value: token);
    } catch (e) {
      throw Exception('Failed to save auth token: $e');
    }
  }

  /// Retrieves the authentication token
  Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _keyAuthToken);
    } catch (e) {
      throw Exception('Failed to get auth token: $e');
    }
  }

  /// Saves the refresh token securely
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _keyRefreshToken, value: token);
    } catch (e) {
      throw Exception('Failed to save refresh token: $e');
    }
  }

  /// Retrieves the refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e) {
      throw Exception('Failed to get refresh token: $e');
    }
  }

  /// Saves user data securely
  Future<void> saveUserData(String userData) async {
    try {
      await _storage.write(key: _keyUserData, value: userData);
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  /// Retrieves user data
  Future<String?> getUserData() async {
    try {
      return await _storage.read(key: _keyUserData);
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  /// Clears all secure storage
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Failed to clear secure storage: $e');
    }
  }

  /// Checks if the device supports secure storage
  Future<bool> isDeviceSupported() async {
    try {
      const testKey = 'test_key';
      const testValue = 'test_value';
      await _storage.write(key: testKey, value: testValue);
      final value = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);
      return value == testValue;
    } catch (e) {
      return false;
    }
  }
  
  /// Factory method to create a singleton instance
  static const SecureStorage instance = SecureStorage();
}
