import 'package:flutter/foundation.dart';
import '../models/equipment.dart';
import '../repositories/equipment_repository.dart';
import '../repositories/result.dart';

/// ViewModel สำหรับจัดการคลังอุปกรณ์ไอทีตามสถาปัตยกรรม MVVM
class EquipmentViewModel extends ChangeNotifier {
  EquipmentRepository equipmentRepository;

  EquipmentViewModel({required this.equipmentRepository});

  void updateRepository(EquipmentRepository repository) {
    equipmentRepository = repository;
  }

  List<Equipment> _equipments = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'all';
  String _searchQuery = '';

  List<Equipment> get equipments => _equipments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  final List<Map<String, String>> categories = const [
    {'key': 'all', 'label': 'ทั้งหมด'},
    {'key': 'laptop', 'label': 'โน้ตบุ๊ก & PC'},
    {'key': 'projector', 'label': 'โปรเจกเตอร์'},
    {'key': 'tablet', 'label': 'แท็บเล็ต/iPad'},
    {'key': 'audio_video', 'label': 'กล้อง & ระบบเสียง'},
    {'key': 'accessories', 'label': 'อุปกรณ์เสริม'},
  ];

  Future<void> loadEquipments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await equipmentRepository.getEquipments(
      category: _selectedCategory,
      search: _searchQuery,
    );

    switch (result) {
      case Success(:final data):
        _equipments = data;
        _isLoading = false;
        notifyListeners();
      case Failure(:final message):
        _errorMessage = message;
        _isLoading = false;
        notifyListeners();
    }
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    loadEquipments();
  }

  void search(String query) {
    _searchQuery = query;
    loadEquipments();
  }
}
