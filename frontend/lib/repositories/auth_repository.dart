import '../services/api_service.dart';
import '../services/token_storage_service.dart';
import 'result.dart';

/// Repository สำหรับจัดการ Authentication และ Session
/// ใช้ Result Pattern ส่งกลับ Success หรือ Failure เสมอ
class AuthRepository {
  final ApiService apiService;
  final TokenStorageService tokenStorage;

  AuthRepository({
    required this.apiService,
    required this.tokenStorage,
  });

  /// กู้คืน Session จาก Secure Storage เมื่อเปิดแอป
  Future<Result<Map<String, dynamic>?>> restoreSession() async {
    try {
      final session = await tokenStorage.loadSession();
      if (session != null && session['accessToken'] != null) {
        apiService.setTokens(
          access: session['accessToken'],
          id: session['idToken'],
          refresh: session['refreshToken'],
          username: session['username'],
          claims: session['claims'],
        );
        return Success(session);
      }
      return const Success(null);
    } catch (e) {
      return Failure('ไม่สามารถกู้คืน Session ได้: $e', e is Exception ? e : Exception(e.toString()));
    }
  }

  /// ล็อกอินผ่าน OIDC
  Future<Result<Map<String, dynamic>>> loginOidc(String username, String password) async {
    try {
      final res = await apiService.loginOidc(username, password);
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        await tokenStorage.saveTokens(
          accessToken: data['access_token'] ?? '',
          idToken: data['id_token'],
          refreshToken: data['refresh_token'],
          username: username,
          userClaims: res['claims'],
        );
        return Success(res);
      } else {
        return Failure(res['error'] ?? 'เข้าสู่ระบบไม่สำเร็จ');
      }
    } catch (e) {
      return Failure('ข้อผิดพลาดการเชื่อมต่อ: $e', e is Exception ? e : Exception(e.toString()));
    }
  }

  /// แลกเปลี่ยน Authorization Code (RFC 8252)
  Future<Result<Map<String, dynamic>>> exchangeAuthCode({
    required String code,
    required String redirectUri,
    String? codeVerifier,
  }) async {
    try {
      final res = await apiService.exchangeAuthCode(
        code: code,
        redirectUri: redirectUri,
        codeVerifier: codeVerifier,
      );
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        final claims = res['claims'] as Map<String, dynamic>?;
        await tokenStorage.saveTokens(
          accessToken: data['access_token'] ?? '',
          idToken: data['id_token'],
          refreshToken: data['refresh_token'],
          username: claims?['preferred_username'] ?? claims?['name'] ?? 'OIDC User',
          userClaims: claims,
        );
        return Success(res);
      } else {
        return Failure(res['error'] ?? 'แลกเปลี่ยน Token ไม่สำเร็จ');
      }
    } catch (e) {
      return Failure('ข้อผิดพลาดการเชื่อมต่อ: $e', e is Exception ? e : Exception(e.toString()));
    }
  }

  /// ดึงเอกสาร OIDC Discovery
  Future<Result<Map<String, dynamic>?>> getOidcDiscovery() async {
    try {
      final data = await apiService.fetchOidcDiscovery();
      return Success(data);
    } catch (e) {
      return Failure('ไม่สามารถดึง Discovery ได้: $e', e is Exception ? e : Exception(e.toString()));
    }
  }

  /// อัปเดต Backend Base URL
  void setBaseUrl(String url) {
    apiService.setBaseUrl(url);
  }

  /// ออกจากระบบและล้าง Secure Storage
  Future<Result<void>> logout() async {
    try {
      apiService.clearTokens();
      await tokenStorage.clearSession();
      return const Success(null);
    } catch (e) {
      return Failure('ออกจากระบบไม่สมบูรณ์: $e', e is Exception ? e : Exception(e.toString()));
    }
  }
}
