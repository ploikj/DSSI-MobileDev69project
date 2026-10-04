import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'jwt_decoder.dart';

/// Service จัดการเก็บและอ่าน Token ลงใน Secure Storage ของระบบปฏิบัติการ
class TokenStorageService {
  final FlutterSecureStorage _storage;

  TokenStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _keyAccessToken = 'oidc_access_token';
  static const String _keyIdToken = 'oidc_id_token';
  static const String _keyRefreshToken = 'oidc_refresh_token';
  static const String _keyUsername = 'oidc_username';
  static const String _keyUserClaims = 'oidc_user_claims';

  /// บันทึก Token และ Claims ลงใน Secure Storage
  Future<void> saveTokens({
    required String accessToken,
    String? idToken,
    String? refreshToken,
    String? username,
    Map<String, dynamic>? userClaims,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (idToken != null) {
      await _storage.write(key: _keyIdToken, value: idToken);
    }
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
    if (username != null) {
      await _storage.write(key: _keyUsername, value: username);
    }
    if (userClaims != null) {
      await _storage.write(key: _keyUserClaims, value: jsonEncode(userClaims));
    }
  }

  /// โหลด Token และ Session ที่บันทึกไว้
  Future<Map<String, dynamic>?> loadSession() async {
    final accessToken = await _storage.read(key: _keyAccessToken);
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final idToken = await _storage.read(key: _keyIdToken);
    final refreshToken = await _storage.read(key: _keyRefreshToken);
    final username = await _storage.read(key: _keyUsername);
    final rawClaims = await _storage.read(key: _keyUserClaims);

    Map<String, dynamic>? userClaims;
    if (rawClaims != null && rawClaims.isNotEmpty) {
      try {
        userClaims = jsonDecode(rawClaims) as Map<String, dynamic>;
      } catch (_) {}
    }

    // ตรวจสอบ Token หมดอายุหรือไม่ (ถ้ามี ID Token)
    if (idToken != null && idToken.isNotEmpty) {
      try {
        if (JwtDecoder.isExpired(idToken)) {
          await clearSession();
          return null;
        }
      } catch (_) {}
    }

    return {
      'accessToken': accessToken,
      'idToken': idToken,
      'refreshToken': refreshToken,
      'username': username,
      'claims': userClaims,
    };
  }

  /// อ่าน Access Token ปัจจุบัน
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// ล้าง Session และ Token ทั้งหมดเมื่อ Logout
  Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyIdToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyUserClaims);
  }
}
