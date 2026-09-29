import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SettingsAuthScreen extends StatefulWidget {
  const SettingsAuthScreen({super.key});

  @override
  State<SettingsAuthScreen> createState() => _SettingsAuthScreenState();
}

class _SettingsAuthScreenState extends State<SettingsAuthScreen> {
  final ApiService _apiService = ApiService();

  final TextEditingController _usernameCtrl = TextEditingController(text: 'admin');
  final TextEditingController _passwordCtrl = TextEditingController(text: 'admin1234');
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _accessCtrl = TextEditingController();
  final TextEditingController _refreshCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = _apiService.baseUrl;
    if (_apiService.accessToken != null) {
      _accessCtrl.text = _apiService.accessToken!;
    }
    if (_apiService.refreshToken != null) {
      _refreshCtrl.text = _apiService.refreshToken!;
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _urlCtrl.dispose();
    _accessCtrl.dispose();
    _refreshCtrl.dispose();
    super.dispose();
  }

  void _saveBaseUrl() {
    final newUrl = _urlCtrl.text.trim();
    if (newUrl.isNotEmpty) {
      _apiService.setBaseUrl(newUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blue.shade800,
          content: Text('อัปเดต Base URL เรียบร้อย: $newUrl'),
        ),
      );
    }
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

    setState(() => _isLoading = true);

    try {
      final res = await _apiService.login(username, password);
      if (!mounted) return;

      if (res['success'] == true) {
        final data = res['data'];
        _accessCtrl.text = data['access'];
        _refreshCtrl.text = data['refresh'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text('เข้าสู่ระบบสำเร็จ! สวัสดีคุณ $username'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('เข้าสู่ระบบไม่สำเร็จ: ${res['error']}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _logout() {
    _apiService.logout();
    _accessCtrl.clear();
    _refreshCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ออกจากระบบแล้ว')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoggedIn = _apiService.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ตั้งค่า & ยืนยันตัวตน (JWT Auth)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Week 14 Demo: การรับส่ง Access & Refresh Token',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Server URL Configuration Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.dns_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Backend API Server Address',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'สลับ IP ให้ตรงกับอุปกรณ์ที่ใช้ทดสอบ:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('127.0.0.1 (Web/Win)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            _urlCtrl.text = 'http://127.0.0.1:8000';
                            _saveBaseUrl();
                          },
                        ),
                        ActionChip(
                          label: const Text('10.0.2.2 (Android Emu)', style: TextStyle(fontSize: 11)),
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
            const SizedBox(height: 20),

            // Authentication Section
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
                            Icon(Icons.security, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'เข้าสู่ระบบ (JWT Authentication)',
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
                              'ล็อกอินแล้ว: ${_apiService.currentUsername}',
                              style: TextStyle(fontSize: 11, color: Colors.green.shade900, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _isLoading ? null : _login,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.login),
                            label: Text(_isLoading ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ (ขอรับ JWT Token)'),
                          ),
                        ),
                        if (isLoggedIn) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _logout,
                            child: const Text('ออกจากระบบ'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Token Output Display
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Access Token & Refresh Token ที่ได้รับ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _accessCtrl,
                      maxLines: 3,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Access Token',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                      ),
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _refreshCtrl,
                      maxLines: 2,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Refresh Token',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                      ),
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
