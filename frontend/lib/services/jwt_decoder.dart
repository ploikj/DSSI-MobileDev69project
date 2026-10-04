import 'dart:convert';

/// ยูทิลิตีสำหรับถอดรหัส JSON Web Token (JWT) เพื่ออ่าน Claims และตรวจสอบวันหมดอายุ
class JwtDecoder {
  /// ถอดรหัส JWT เป็น Header, Payload และ Signature
  static Map<String, dynamic> decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Invalid JWT token format');
    }

    final header = _decodeBase64(parts[0]);
    final payload = _decodeBase64(parts[1]);

    return {
      'header': jsonDecode(header),
      'payload': jsonDecode(payload),
      'signature': parts[2],
    };
  }

  /// ดึงข้อมูล Claims (Payload) ออกมาจาก JWT
  static Map<String, dynamic> getPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    try {
      final payload = _decodeBase64(parts[1]);
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// ดึงข้อมูล Header ออกมาจาก JWT
  static Map<String, dynamic> getHeader(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    try {
      final header = _decodeBase64(parts[0]);
      return jsonDecode(header) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static String _decodeBase64(String str) {
    String normalized = base64Url.normalize(str);
    return utf8.decode(base64Url.decode(normalized));
  }

  /// อ่านวันหมดอายุของ Token จาก exp claim
  static DateTime? getExpirationDate(String token) {
    final payload = getPayload(token);
    if (!payload.containsKey('exp')) return null;
    final exp = payload['exp'] as int;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }

  /// ตรวจสอบว่า Token หมดอายุแล้วหรือไม่
  static bool isExpired(String token) {
    final expirationDate = getExpirationDate(token);
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate);
  }
}
