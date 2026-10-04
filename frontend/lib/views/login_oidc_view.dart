import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/auth_viewmodel.dart';

/// หน้าจอเข้าสู่ระบบผ่าน OpenID Connect (OIDC) ตามรูปแบบสถาปัตยกรรม MVVM
/// ติดต่อกับ AuthViewModel ผ่าน Provider เท่านั้น ไม่ติดต่อ Service โดยตรง
class LoginOidcView extends StatefulWidget {
  const LoginOidcView({super.key});

  @override
  State<LoginOidcView> createState() => _LoginOidcViewState();
}

class _LoginOidcViewState extends State<LoginOidcView> {
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();

  HttpServer? _loopbackServer;
  bool _showDiscovery = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      _urlCtrl.text = authVM.baseUrl;
      authVM.fetchDiscovery();
    });
  }

  @override
  void dispose() {
    _stopLoopbackServer();
    _urlCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _stopLoopbackServer() {
    _loopbackServer?.close(force: true);
    _loopbackServer = null;
  }

  void _saveBaseUrl() {
    final newUrl = _urlCtrl.text.trim();
    if (newUrl.isNotEmpty) {
      final authVM = context.read<AuthViewModel>();
      authVM.setBaseUrl(newUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปเดต Base URL เรียบร้อย: $newUrl')),
      );
    }
  }

  /// เริ่มต้นกระบวนการ RFC 8252 Authorization Code Flow
  Future<void> _startAuthorizationCodeFlow() async {
    _stopLoopbackServer();
    final authVM = context.read<AuthViewModel>();
    String redirectUri = '${authVM.baseUrl}/callback';

    // บน Desktop หรือ Mobile ให้ลองเปิด Loopback Server พอร์ต 8888
    if (!kIsWeb) {
      try {
        _loopbackServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 8888);
        redirectUri = 'http://127.0.0.1:8888/callback';

        _loopbackServer?.listen((HttpRequest request) async {
          final uri = request.uri;
          final code = uri.queryParameters['code'];

          request.response.headers.contentType = ContentType.html;
          request.response.write('''
            <!DOCTYPE html>
            <html>
            <head><meta charset="utf-8"><title>Authentication Complete</title></head>
            <body style="font-family: sans-serif; display:flex; justify-content:center; align-items:center; height:100vh; background:#ecfdf5; margin:0;">
              <div style="background:white; padding:30px; border-radius:16px; box-shadow:0 10px 25px rgba(0,0,0,0.1); text-align:center;">
                <h2 style="color:#059669;">✅ ยืนยันตัวตน OIDC สำเร็จ!</h2>
                <p>คุณสามารถปิดหน้าต่างนี้และกลับสู่แอปพลิเคชันได้แล้ว</p>
              </div>
            </body>
            </html>
          ''');
          await request.response.close();

          if (code != null && code.isNotEmpty) {
            _handleReceivedCode(code, redirectUri: redirectUri);
          }
        });
      } catch (_) {
        redirectUri = '${authVM.baseUrl}/callback';
      }
    }

    final authUrl = authVM.getAuthorizationUrl(
      redirectUri: redirectUri,
      state: 'state_${DateTime.now().millisecondsSinceEpoch}',
    );

    final uri = Uri.parse(authUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Launch URL error: $e');
    }

    if (!mounted) return;
    _showCodeInputDialog(redirectUri);
  }

  void _showCodeInputDialog(String usedRedirectUri) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final authVM = context.watch<AuthViewModel>();
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.open_in_browser, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text('กำลังยืนยันตัวตน OIDC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ระบบได้เปิดหน้าล็อกอินของ OpenID Connect Server บนเบราว์เซอร์แล้ว:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ขั้นตอน:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('1. เข้าสู่ระบบบนหน้าเว็บ OIDC Server', style: TextStyle(fontSize: 12)),
                        Text('2. กดยอมรับการเข้าถึง (Consent)', style: TextStyle(fontSize: 12)),
                        Text('3. คัดลอก Authorization Code ที่ได้มาวางด้านล่าง', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _codeCtrl,
                    decoration: InputDecoration(
                      labelText: 'วาง Authorization Code หรือ URL',
                      hintText: 'เช่น edba4e472f4b4d10b1a3758438031f91',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste),
                        tooltip: 'วางจากคลิปบอร์ด',
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            String text = data!.text!.trim();
                            if (text.contains('code=')) {
                              final match = RegExp(r'code=([^&]+)').firstMatch(text);
                              if (match != null) text = match.group(1)!;
                            }
                            setDialogState(() {
                              _codeCtrl.text = text;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  if (authVM.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      authVM.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _stopLoopbackServer();
                  Navigator.pop(dialogCtx);
                },
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
                icon: authVM.isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check, size: 18),
                label: const Text('ยืนยันโค้ด'),
                onPressed: authVM.isLoading
                    ? null
                    : () async {
                        String raw = _codeCtrl.text.trim();
                        if (raw.isEmpty) return;
                        if (raw.contains('code=')) {
                          final match = RegExp(r'code=([^&]+)').firstMatch(raw);
                          if (match != null) raw = match.group(1)!;
                        }

                        Navigator.pop(dialogCtx);
                        await _handleReceivedCode(raw, redirectUri: usedRedirectUri);
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleReceivedCode(String code, {required String redirectUri}) async {
    _stopLoopbackServer();
    final authVM = context.read<AuthViewModel>();
    final success = await authVM.exchangeAuthCode(
      code: code,
      redirectUri: redirectUri,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text('ยืนยันตัวตนสำเร็จ! สวัสดีคุณ ${authVM.username}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(authVM.errorMessage ?? 'แลกเปลี่ยน Token ไม่สำเร็จ'),
          ),
        );
      }
    }
  }

  Future<void> _loginDirect(String user, String pass) async {
    final authVM = context.read<AuthViewModel>();
    final success = await authVM.loginOidc(user, pass);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text('เข้าสู่ระบบสำเร็จ! สวัสดีคุณ $user'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(authVM.errorMessage ?? 'เข้าสู่ระบบไม่สำเร็จ'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Header
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.devices, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ระบบจองอุปกรณ์ไอที',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'คณะวิศวกรรมศาสตร์ มหาวิทยาลัยอุบลราชธานี',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 28),

                // Main OIDC Login Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.verified_user, color: Colors.purple.shade700, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'เข้าสู่ระบบผ่าน OIDC Server',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'Authorization Code Flow (RFC 8252)',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'ล็อกอินด้วยบัญชีกลางมหาวิทยาลัย โดยระบบจะเปิดเบราว์เซอร์เพื่อขอ Authorization Code และแลกเปลี่ยนเป็น ID Token อย่างปลอดภัย',
                          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 24),

                        // Main Login Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 3,
                          ),
                          icon: authVM.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.open_in_browser),
                          label: const Text(
                            'เปิดหน้าล็อกอิน OIDC บนเบราว์เซอร์',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          onPressed: authVM.isLoading ? null : _startAuthorizationCodeFlow,
                        ),

                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('หรือทดสอบแบบรวดเร็ว', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Fast Test Login Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.flash_on, size: 18, color: Colors.amber),
                          label: const Text('ล็อกอินทันทีด้วยบัญชี narathip (pass1234)'),
                          onPressed: authVM.isLoading ? null : () => _loginDirect('narathip', 'pass1234'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.person_outline, size: 18),
                          label: const Text('ล็อกอินทันทีด้วย somchai (pass1234)'),
                          onPressed: authVM.isLoading ? null : () => _loginDirect('somchai', 'pass1234'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Base URL & Discovery Config Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.dns, size: 18, color: Colors.blueGrey),
                                SizedBox(width: 8),
                                Text('ตั้งค่า Server URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                setState(() => _showDiscovery = !_showDiscovery);
                                if (_showDiscovery && authVM.discovery == null) {
                                  authVM.fetchDiscovery();
                                }
                              },
                              child: Text(_showDiscovery ? 'ซ่อน' : 'OIDC Discovery', style: const TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _urlCtrl,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  labelText: 'Backend & OIDC Issuer URL',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _saveBaseUrl,
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                              child: const Text('บันทึก', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        if (_showDiscovery) ...[
                          const SizedBox(height: 8),
                          if (authVM.discovery != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Issuer: ${authVM.discovery?['issuer']}\nAuthorization: ${authVM.discovery?['authorization_endpoint']}\nToken: ${authVM.discovery?['token_endpoint']}\nJWKS: ${authVM.discovery?['jwks_uri']}',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
