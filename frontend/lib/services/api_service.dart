import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/equipment.dart';
import '../models/booking.dart';

class ApiService extends ChangeNotifier {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // URL เริ่มต้น: ถ้าเป็น Web/Desktop ใช้ 127.0.0.1 ถ้าเป็น Android Emulator สามารถสลับเป็น 10.0.2.2 ได้
  String _baseUrl = (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
      ? 'http://127.0.0.1:8000'
      : 'http://10.0.2.2:8000';

  String? _accessToken;
  String? _refreshToken;
  String? _currentUsername;

  String get baseUrl => _baseUrl;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get currentUsername => _currentUsername;
  bool get isLoggedIn => _accessToken != null;

  void setBaseUrl(String url) {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
    notifyListeners();
  }

  void setTokens({required String access, required String refresh, String? username}) {
    _accessToken = access;
    _refreshToken = refresh;
    if (username != null) _currentUsername = username;
    notifyListeners();
  }

  void logout() {
    _accessToken = null;
    _refreshToken = null;
    _currentUsername = null;
    notifyListeners();
  }

  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // --- Login / JWT ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    final uri = Uri.parse('$_baseUrl/api/token/');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      setTokens(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
        username: username,
      );
      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'statusCode': res.statusCode,
        'error': 'เข้าสู่ระบบไม่สำเร็จ (${res.statusCode})'
      };
    }
  }

  // --- Equipments ---
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

    final res = await http.get(uri, headers: _headers());
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

    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((item) => Booking.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('โหลดรายการจองไม่สำเร็จ (${res.statusCode})');
    }
  }

  // --- Create Booking ---
  Future<Booking> createBooking(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_baseUrl/api/bookings/');
    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      notifyListeners();
      return Booking.fromJson(data as Map<String, dynamic>);
    } else {
      final errData = jsonDecode(utf8.decode(res.bodyBytes));
      throw Exception('การจองไม่สำเร็จ: $errData');
    }
  }

  // --- Update Booking Status ---
  Future<Booking> updateBookingStatus(int id, String newStatus) async {
    final uri = Uri.parse('$_baseUrl/api/bookings/$id/');
    final res = await http.patch(
      uri,
      headers: _headers(),
      body: jsonEncode({'status': newStatus}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      notifyListeners();
      return Booking.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception('อัปเดตสถานะไม่สำเร็จ (${res.statusCode})');
    }
  }

  // --- Delete Booking ---
  Future<void> deleteBooking(int id) async {
    final uri = Uri.parse('$_baseUrl/api/bookings/$id/');
    final res = await http.delete(uri, headers: _headers());
    if (res.statusCode == 204 || res.statusCode == 200) {
      notifyListeners();
    } else {
      throw Exception('ลบรายการไม่สำเร็จ (${res.statusCode})');
    }
  }
}
