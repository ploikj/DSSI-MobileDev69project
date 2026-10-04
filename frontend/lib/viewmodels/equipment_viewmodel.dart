import 'package:flutter/foundation.dart';
import '../models/equipment.dart';
import '../repositories/equipment_repository.dart';
import '../repositories/result.dart';

/// ViewModel สำหรับจัดการคลังอุปกรณ์ไอที
/// รองรับการค้นหาแบบเรียลไทม์ (Real-time Search), การกรองตามหมวดหมู่/สถานะพร้อมยืม, และการเรียงลำดับหลายรูปแบบ
class EquipmentViewModel extends ChangeNotifier {
  EquipmentRepository equipmentRepository;

  EquipmentViewModel({required this.equipmentRepository});

  void updateRepository(EquipmentRepository repository) {
    equipmentRepository = repository;
  }

  List<Equipment> _allEquipments = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Real-time Search & Filter States
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _onlyAvailable = false;
  String _sortBy = 'name_asc'; // name_asc, name_desc, available_desc, newest

  List<Equipment> get allEquipments => _allEquipments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get onlyAvailable => _onlyAvailable;
  String get sortBy => _sortBy;

  /// รายการอุปกรณ์หลักที่แสดงผล (ผ่านการค้นหา กรอง และจัดเรียง)
  List<Equipment> get equipments => displayedEquipments;

  /// รายการอุปกรณ์ที่ผ่านการค้นหา กรอง และเรียงลำดับแบบเรียลไทม์ (Instant Response)
  List<Equipment> get displayedEquipments {
    List<Equipment> list = List.from(_allEquipments);

    // 1. กรองตามหมวดหมู่ (Category Filter)
    if (_selectedCategory != 'all') {
      list = list.where((item) => item.category == _selectedCategory).toList();
    }

    // 2. กรองเฉพาะที่พร้อมยืม (Availability Filter)
    if (_onlyAvailable) {
      list = list.where((item) => item.isAvailable).toList();
    }

    // 3. ค้นหาแบบเรียลไทม์ (Real-time Search Query)
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((item) {
        final nameMatch = item.name.toLowerCase().contains(q);
        final modelMatch = item.modelNumber?.toLowerCase().contains(q) ?? false;
        final descMatch = item.description.toLowerCase().contains(q);
        final locMatch = item.pickupLocation.toLowerCase().contains(q);
        final catMatch = item.categoryDisplay.toLowerCase().contains(q);
        return nameMatch || modelMatch || descMatch || locMatch || catMatch;
      }).toList();
    }

    // 4. เรียงลำดับ (Sorting)
    switch (_sortBy) {
      case 'name_desc':
        list.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'available_desc':
        list.sort((a, b) => b.availableQuantity.compareTo(a.availableQuantity));
        break;
      case 'newest':
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'name_asc':
      default:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return list;
  }

  final List<Map<String, String>> categories = const [
    {'key': 'all', 'label': 'ทั้งหมด'},
    {'key': 'laptop', 'label': 'โน้ตบุ๊ก & PC'},
    {'key': 'projector', 'label': 'โปรเจกเตอร์'},
    {'key': 'tablet', 'label': 'แท็บเล็ต/iPad'},
    {'key': 'audio_video', 'label': 'กล้อง & ระบบเสียง'},
    {'key': 'accessories', 'label': 'อุปกรณ์เสริม'},
  ];

  /// โหลดข้อมูลอุปกรณ์ทั้งหมดจาก Backend
  Future<void> loadEquipments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await equipmentRepository.getEquipments();

    switch (result) {
      case Success(:final data):
        _allEquipments = data;
        _isLoading = false;
        notifyListeners();
      case Failure(:final message):
        _errorMessage = message;
        _isLoading = false;
        notifyListeners();
    }
  }

  /// ค้นหาแบบเรียลไทม์ขณะพิมพ์ (Instant Filter)
  void search(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// สลับหมวดหมู่
  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  /// สลับตัวกรองเฉพาะที่พร้อมยืม
  void toggleOnlyAvailable([bool? value]) {
    final next = value ?? !_onlyAvailable;
    if (_onlyAvailable == next) return;
    _onlyAvailable = next;
    notifyListeners();
  }

  /// เปลี่ยนรูปแบบการเรียงลำดับ
  void setSortBy(String sortOption) {
    if (_sortBy == sortOption) return;
    _sortBy = sortOption;
    notifyListeners();
  }
}
