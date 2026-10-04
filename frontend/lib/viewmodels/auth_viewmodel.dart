import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../repositories/result.dart';

/// ViewModel สำหรับจัดการ Authentication และ Session ตามสถาปัตยกรรม MVVM
class AuthViewModel extends ChangeNotifier {
  AuthRepository authRepository;

  AuthViewModel({required this.authRepository});

  void updateRepository(AuthRepository repository) {
    authRepository = repository;
  }

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _username;
  Map<String, dynamic>? _claims;
  Map<String, dynamic>? _header;
  Map<String, dynamic>? _discovery;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;
  Map<String, dynamic>? get claims => _claims;
  Map<String, dynamic>? get header => _header;
  Map<String, dynamic>? get discovery => _discovery;

  String get baseUrl => authRepository.apiService.baseUrl;
  String? get accessToken => authRepository.apiService.accessToken;
  String? get idToken => authRepository.apiService.idToken;
  String? get refreshToken => authRepository.apiService.refreshToken;

  /// ตรวจสอบและกู้คืน Session จาก Secure Storage อัตโนมัติ (Route Guard)
  Future<void> initSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await authRepository.restoreSession();

    switch (result) {
      case Success(:final data):
        if (data != null && data['accessToken'] != null) {
          _isAuthenticated = true;
          _username = data['username'];
          _claims = data['claims'];
        } else {
          _isAuthenticated = false;
        }
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
      case Failure(:final message):
        _isAuthenticated = false;
        _isInitialized = true;
        _isLoading = false;
        _errorMessage = message;
        notifyListeners();
    }
  }

  /// เข้าสู่ระบบผ่าน OIDC ด้วย Resource Owner Password Credentials
  Future<bool> loginOidc(String user, String pass) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await authRepository.loginOidc(user, pass);

    switch (result) {
      case Success(:final data):
        _isAuthenticated = true;
        _username = user;
        _claims = data['claims'];
        _header = data['header'];
        _isLoading = false;
        notifyListeners();
        return true;
      case Failure(:final message):
        _isLoading = false;
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }

  /// แลกเปลี่ยน Authorization Code เป็น Access & ID Token (Authorization Code Flow)
  Future<bool> exchangeAuthCode({
    required String code,
    required String redirectUri,
    String? codeVerifier,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await authRepository.exchangeAuthCode(
      code: code,
      redirectUri: redirectUri,
      codeVerifier: codeVerifier,
    );

    switch (result) {
      case Success(:final data):
        _isAuthenticated = true;
        final c = data['claims'] as Map<String, dynamic>?;
        _username = c?['preferred_username'] ?? c?['name'] ?? 'OIDC User';
        _claims = c;
        _header = data['header'] as Map<String, dynamic>?;
        _isLoading = false;
        notifyListeners();
        return true;
      case Failure(:final message):
        _isLoading = false;
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }

  /// ดึงข้อมูล OIDC Discovery
  Future<void> fetchDiscovery() async {
    final result = await authRepository.getOidcDiscovery();
    if (result is Success<Map<String, dynamic>?>) {
      _discovery = result.data;
      notifyListeners();
    }
  }

  /// เปลี่ยน Base URL
  void setBaseUrl(String url) {
    authRepository.setBaseUrl(url);
    fetchDiscovery();
    notifyListeners();
  }

  /// สร้าง URL สำหรับเรียก Authorization Code Flow
  String getAuthorizationUrl({required String redirectUri, required String state, String? codeChallenge}) {
    final queryParams = {
      'response_type': 'code',
      'client_id': 'flutter-mobile-client',
      'redirect_uri': redirectUri,
      'scope': 'openid profile email student_id phone',
      'state': state,
    };
    if (codeChallenge != null) {
      queryParams['code_challenge'] = codeChallenge;
      queryParams['code_challenge_method'] = 'S256';
    }
    return Uri.parse('$baseUrl/oidc/authorize/').replace(queryParameters: queryParams).toString();
  }

  /// ออกจากระบบและล้าง Token
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await authRepository.logout();

    _isAuthenticated = false;
    _username = null;
    _claims = null;
    _header = null;
    _isLoading = false;
    notifyListeners();
  }
}
