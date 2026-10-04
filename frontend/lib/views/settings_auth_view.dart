import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/booking_viewmodel.dart';

/// หน้าจอตรวจสอบระบบยืนยันตัวตน OIDC และ JWT ตามสถาปัตยกรรม MVVM
/// ติดต่อกับ AuthViewModel และ BookingViewModel ผ่าน Provider เท่านั้น ไม่ติดต่อ Service โดยตรง
class SettingsAuthView extends StatefulWidget {
  final VoidCallback? onLogout;

  const SettingsAuthView({
    super.key,
    this.onLogout,
  });

  @override
  State<SettingsAuthView> createState() => _SettingsAuthViewState();
}

class _SettingsAuthViewState extends State<SettingsAuthView> {
  final TextEditingController _usernameCtrl = TextEditingController(text: 'narathip');
  final TextEditingController _passwordCtrl = TextEditingController(text: 'pass1234');
  final TextEditingController _urlCtrl = TextEditingController();

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
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _saveBaseUrl() {
    final newUrl = _urlCtrl.text.trim();
    if (newUrl.isNotEmpty) {
      final authVM = context.read<AuthViewModel>();
      authVM.setBaseUrl(newUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blue.shade800,
          content: Text('อัปเดต Base URL เรียบร้อย: $newUrl'),
        ),
      );
    }
  }

  void _selectTestUser(String username, String password) {
    _usernameCtrl.text = username;
    _passwordCtrl.text = password;
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก Username และ Password')),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    final success = await authVM.loginOidc(username, password);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text('เข้าสู่ระบบผ่าน OpenID Connect (OIDC) สำเร็จ! สวัสดีคุณ $username'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('เข้าสู่ระบบไม่สำเร็จ: ${authVM.errorMessage}'),
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('คัดลอก $label เรียบร้อยแล้ว'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVM = context.watch<AuthViewModel>();
    final bookingVM = context.watch<BookingViewModel>();

    final isLoggedIn = authVM.isAuthenticated;
    final claims = authVM.claims;
    final header = authVM.header;
    final discovery = authVM.discovery;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ระบบยืนยันตัวตน & ตั้งค่า (OIDC & JWT)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              'Real OIDC Provider Architecture (Week 15)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'ออกจากระบบ',
              onPressed: widget.onLogout,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking & Pickup Status Summary Card (แสดงสถิตินัดรับตรงกันทุกหน้า)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.indigo.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.event_note, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ภาพรวมรายการจอง & วันนัดรับของคุณ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${bookingVM.pendingCount}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                            ),
                            const Text('รอนัดรับ', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                        Container(height: 28, width: 1, color: Colors.white24),
                        Column(
                          children: [
                            Text(
                              '${bookingVM.pickedUpCount}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.lightGreenAccent),
                            ),
                            const Text('รับแล้ว', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                        Container(height: 28, width: 1, color: Colors.white24),
                        Column(
                          children: [
                            Text(
                              '${bookingVM.returnedCount}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const Text('คืนเรียบร้อย', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 1. API Server URL Configuration Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.dns_outlined, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Backend & OIDC Issuer Endpoint',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'สลับ IP ให้ตรงกับอุปกรณ์ที่ใช้ทดสอบ:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          label: const Text('localhost:8000 (Web/Desktop)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            _urlCtrl.text = 'http://127.0.0.1:8000';
                            _saveBaseUrl();
                          },
                        ),
                        ActionChip(
                          label: const Text('10.0.2.2:8000 (Android)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            _urlCtrl.text = 'http://10.0.2.2:8000';
                            _saveBaseUrl();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _urlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Base URL',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveBaseUrl,
                          child: const Text('บันทึก'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. OIDC Discovery Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.hub_outlined, color: Colors.indigo.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'OIDC Discovery (/.well-known/openid-configuration)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _showDiscovery = !_showDiscovery);
                            if (_showDiscovery && discovery == null) {
                              authVM.fetchDiscovery();
                            }
                          },
                          child: Text(_showDiscovery ? 'ซ่อน' : 'แสดง'),
                        ),
                      ],
                    ),
                    if (_showDiscovery) ...[
                      const SizedBox(height: 8),
                      if (discovery != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            const JsonEncoder.withIndent('  ').convert(discovery),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                          ),
                        )
                      else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Authentication Section
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_user, color: Colors.purple.shade700, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              'ล็อกอินผ่าน OIDC 1.0 Provider',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        if (isLoggedIn)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ออนไลน์: ${authVM.username}',
                              style: TextStyle(fontSize: 11, color: Colors.green.shade900, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick test users selector
                    const Text(
                      'คลิกเลือกผู้ใช้งานทดสอบในระบบ:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.person, size: 12),
                          label: const Text('narathip (นศ.)', style: TextStyle(fontSize: 11)),
                          onPressed: () => _selectTestUser('narathip', 'pass1234'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.admin_panel_settings, size: 12),
                          label: const Text('admin (จนท.)', style: TextStyle(fontSize: 11)),
                          onPressed: () => _selectTestUser('admin', 'admin1234'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.school, size: 12),
                          label: const Text('somchai (อ.)', style: TextStyle(fontSize: 11)),
                          onPressed: () => _selectTestUser('somchai', 'pass1234'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: authVM.isLoading ? null : _login,
                            icon: authVM.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.login),
                            label: Text(authVM.isLoading ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ (ขอรับ OIDC Tokens)'),
                          ),
                        ),
                        if (isLoggedIn) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => authVM.logout(),
                            child: const Text('ออกจากระบบ'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Decoded OIDC ID Token Claims Section
            if (claims != null && claims.isNotEmpty) ...[
              Card(
                color: Colors.purple.shade50.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.purple.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.badge, color: Colors.purple.shade800, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Decoded OIDC Claims (ข้อมูลผู้ใช้ที่ได้รับ)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (header != null) ...[
                        Text('JWT Alg: ${header['alg']} | Typ: ${header['typ']} | Key ID: ${header['kid']}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const Divider(height: 14),
                      ],
                      Text('Subject (sub): ${claims['sub']}', style: const TextStyle(fontSize: 12)),
                      Text('Issuer (iss): ${claims['iss']}', style: const TextStyle(fontSize: 12)),
                      Text('Audience (aud): ${claims['aud']}', style: const TextStyle(fontSize: 12)),
                      Text('Username: ${claims['preferred_username'] ?? claims['nickname'] ?? '-'}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('Email: ${claims['email'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                      if (claims['exp'] != null)
                        Text(
                          'Expires at: ${DateTime.fromMillisecondsSinceEpoch((claims['exp'] as int) * 1000).toLocal()}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 5. Active Tokens Inspection Section
            if (authVM.accessToken != null && authVM.accessToken!.isNotEmpty) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.key, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text('Active Tokens (บันทึกใน Secure Storage)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTokenField('Access Token (Bearer)', authVM.accessToken!),
                      if (authVM.idToken != null) ...[
                        const SizedBox(height: 10),
                        _buildTokenField('OIDC ID Token (JWT)', authVM.idToken!),
                      ],
                      if (authVM.refreshToken != null) ...[
                        const SizedBox(height: 10),
                        _buildTokenField('Refresh Token', authVM.refreshToken!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTokenField(String label, String token) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              tooltip: 'คัดลอก $label',
              onPressed: () => _copyToClipboard(token, label),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            token,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
      ],
    );
  }
}
