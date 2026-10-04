import 'package:flutter/foundation.dart';
import '../services/localization_service.dart';
import '../services/token_storage_service.dart';

/// ViewModel สำหรับจัดการการสลับภาษา (ไทย 🇹🇭 / อังกฤษ 🇬🇧)
/// ตามสถาปัตยกรรม MVVM และบันทึกการตั้งค่าลงใน Secure Storage
class LocaleViewModel extends ChangeNotifier {
  TokenStorageService tokenStorage;
  String _currentLocale = 'th';

  LocaleViewModel({required this.tokenStorage}) {
    _loadSavedLocale();
  }

  void updateStorage(TokenStorageService storage) {
    tokenStorage = storage;
  }

  String get currentLocale => _currentLocale;
  bool get isThai => _currentLocale == 'th';
  bool get isEnglish => _currentLocale == 'en';

  Future<void> _loadSavedLocale() async {
    final saved = await tokenStorage.loadLocale();
    if (saved != null && (saved == 'th' || saved == 'en')) {
      _currentLocale = saved;
      notifyListeners();
    }
  }

  /// แปลข้อความตาม Key และใส่พารามิเตอร์แบบไดนามิก
  String t(String key, [Map<String, String>? params]) {
    return LocalizationService.translate(key, _currentLocale, params);
  }

  /// สลับภาษาโดยตรง
  Future<void> setLocale(String langCode) async {
    if (_currentLocale == langCode) return;
    _currentLocale = langCode;
    notifyListeners();
    await tokenStorage.saveLocale(langCode);
  }

  /// สลับภาษาระหว่าง TH และ EN ในคลิกเดียว
  Future<void> toggleLocale() async {
    final next = _currentLocale == 'th' ? 'en' : 'th';
    await setLocale(next);
  }
}
