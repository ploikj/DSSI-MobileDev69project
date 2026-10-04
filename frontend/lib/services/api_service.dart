import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/equipment.dart';
import '../models/booking.dart';

/// Service สำหรับติดต่อเครือข่าย HTTP REST API และ OIDC Provider
class ApiService {
  final http.Client _client;

  String _baseUrl = (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
      ? 'http://127.0.0.1:8000'
      : 'http://10.0.2.2:8000';

  String? _accessToken;
  String? _idToken;
  String? _refreshToken;
  String? _currentUsername;
  Map<String, dynamic>? _decodedClaims;
  Map<String, dynamic>? _decodedHeader;
  Map<String, dynamic>? _discoveryData;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  String get baseUrl => _baseUrl;
  String? get accessToken => _accessToken;
  String? get idToken => _idToken;
  String? get refreshToken => _refreshToken;
  String? get currentUsername => _currentUsername;
  Map<String, dynamic>? get decodedClaims => _decodedClaims;
  Map<String, dynamic>? get decodedHeader => _decodedHeader;
  Map<String, dynamic>? get discoveryData => _discoveryData;
  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;

  void setBaseUrl(String url) {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
  }

  void setTokens({
    required String access,
    String? id,
    String? refresh,
    String? username,
    Map<String, dynamic>? claims,
    Map<String, dynamic>? header,
  }) {
    _accessToken = access;
    if (id != null) _idToken = id;
    if (refresh != null) _refreshToken = refresh;
    if (username != null) _currentUsername = username;
    if (claims != null) _decodedClaims = claims;
    if (header != null) _decodedHeader = header;
  }

  void clearTokens() {
    _accessToken = null;
    _idToken = null;
    _refreshToken = null;
    _currentUsername = null;
    _decodedClaims = null;
    _decodedHeader = null;
  }

  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (_currentUsername != null && _currentUsername!.isNotEmpty) {
      headers['X-Username'] = _currentUsername!;
    }
    return headers;
  }

  // --- OIDC Authentication ---

  /// เรียก Login OIDC โดยตรง
  Future<Map<String, dynamic>> loginOidc(String username, String password) async {
    final uri = Uri.parse('$_baseUrl/api/oidc/login/');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'client_id': 'flutter-mobile-client',
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final rawIdToken = data['id_token'] as String?;
      Map<String, dynamic>? claims;
      Map<String, dynamic>? header;

      if (rawIdToken != null && rawIdToken.isNotEmpty) {
        try {
          final parts = rawIdToken.split('.');
          if (parts.length == 3) {
            final headerJson = utf8.decode(base64Url.decode(base64Url.normalize(parts[0])));
            final payloadJson = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
            header = jsonDecode(headerJson) as Map<String, dynamic>;
            claims = jsonDecode(payloadJson) as Map<String, dynamic>;
          }
        } catch (_) {}
      }

      setTokens(
        access: data['access_token'] ?? '',
        id: rawIdToken,
        refresh: data['refresh_token'],
        username: username,
        claims: claims,
        header: header,
      );

      return {
        'success': true,
        'data': data,
        'claims': claims,
        'header': header,
      };
    } else {
      final err = jsonDecode(utf8.decode(res.bodyBytes));
      return {
        'success': false,
        'error': err['error'] ?? 'Login failed (${res.statusCode})',
      };
    }
  }

  /// แลก Authorization Code กับ Token (RFC 8252 Authorization Code Flow)
  Future<Map<String, dynamic>> exchangeAuthCode({
    required String code,
    required String redirectUri,
    String? codeVerifier,
  }) async {
    final uri = Uri.parse('$_baseUrl/oidc/token/');
    final body = {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
      'client_id': 'flutter-mobile-client',
    };
    if (codeVerifier != null) {
      body['code_verifier'] = codeVerifier;
    }

    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final rawIdToken = data['id_token'] as String?;
      Map<String, dynamic>? claims;
      Map<String, dynamic>? header;

      if (rawIdToken != null && rawIdToken.isNotEmpty) {
        try {
          final parts = rawIdToken.split('.');
          if (parts.length == 3) {
            final headerJson = utf8.decode(base64Url.decode(base64Url.normalize(parts[0])));
            final payloadJson = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
            header = jsonDecode(headerJson) as Map<String, dynamic>;
            claims = jsonDecode(payloadJson) as Map<String, dynamic>;
          }
        } catch (_) {}
      }

      setTokens(
        access: data['access_token'] ?? '',
        id: rawIdToken,
        refresh: data['refresh_token'],
        username: claims?['preferred_username'] ?? claims?['name'] ?? 'OIDC User',
        claims: claims,
        header: header,
      );

      return {
        'success': true,
        'data': data,
        'claims': claims,
        'header': header,
      };
    } else {
      final err = jsonDecode(utf8.decode(res.bodyBytes));
      return {
        'success': false,
        'error': err['error_description'] ?? err['error'] ?? 'Token exchange failed (${res.statusCode})',
      };
    }
  }

  /// ดึงข้อมูล OIDC Discovery เอกสารมาตรฐาน
  Future<Map<String, dynamic>?> fetchOidcDiscovery() async {
    final uri = Uri.parse('$_baseUrl/.well-known/openid-configuration');
    try {
      final res = await _client.get(uri);
      if (res.statusCode == 200) {
        _discoveryData = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return _discoveryData;
      }
    } catch (_) {}
    return null;
  }

  // --- Equipment Catalog ---

  Future<List<Equipment>> fetchEquipments({String? category, String? search}) async {
    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty && category != 'all') {
      queryParams['category'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$_baseUrl/api/equipments/').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final res = await _client.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((item) => Equipment.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('โหลดรายการอุปกรณ์ไม่สำเร็จ (${res.statusCode})');
    }
  }

  // --- Bookings ---

  Future<List<Booking>> fetchBookings({String? status, String? search}) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty && status != 'ALL') {
      queryParams['status'] = status;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$_baseUrl/api/bookings/').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final res = await _client.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((item) => Booking.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('โหลดรายการจองไม่สำเร็จ (${res.statusCode})');
    }
  }

  Future<Booking> createBooking(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_baseUrl/api/bookings/');
    final res = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return Booking.fromJson(data);
    } else {
      final errData = jsonDecode(utf8.decode(res.bodyBytes));
      throw Exception('การจองไม่สำเร็จ: $errData');
    }
  }

  Future<Booking> updateBookingStatus(int id, String newStatus) async {
    final uri = Uri.parse('$_baseUrl/api/bookings/$id/');
    final res = await _client.patch(
      uri,
      headers: _headers(),
      body: jsonEncode({'status': newStatus}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return Booking.fromJson(data);
    } else {
      String errorMessage = 'อัปเดตสถานะไม่สำเร็จ (${res.statusCode})';
      try {
        final errData = jsonDecode(utf8.decode(res.bodyBytes));
        if (errData is Map && errData['error'] != null) {
          errorMessage = errData['error'].toString();
        } else if (errData is Map && errData['detail'] != null) {
          errorMessage = errData['detail'].toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteBooking(int id) async {
    final uri = Uri.parse('$_baseUrl/api/bookings/$id/');
    final res = await _client.delete(uri, headers: _headers());
    if (res.statusCode != 204 && res.statusCode != 200) {
      String errorMessage = 'ลบรายการไม่สำเร็จ (${res.statusCode})';
      try {
        final errData = jsonDecode(utf8.decode(res.bodyBytes));
        if (errData is Map && errData['error'] != null) {
          errorMessage = errData['error'].toString();
        } else if (errData is Map && errData['detail'] != null) {
          errorMessage = errData['detail'].toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
