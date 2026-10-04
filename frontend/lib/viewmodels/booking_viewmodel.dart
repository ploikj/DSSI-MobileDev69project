import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../repositories/booking_repository.dart';
import '../repositories/result.dart';

/// ViewModel สำหรับจัดการการจองและกำหนดการรับอุปกรณ์ไอที
/// รองรับการค้นหาแบบเรียลไทม์ (Real-time Search), การกรองตามสถานะ, และการเรียงลำดับวันนัดรับ
class BookingViewModel extends ChangeNotifier {
  BookingRepository bookingRepository;

  BookingViewModel({required this.bookingRepository});

  void updateRepository(BookingRepository repository) {
    bookingRepository = repository;
  }

  List<Booking> _allBookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Real-time Search & Filter States
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  String _sortBy = 'pickup_asc'; // pickup_asc, pickup_desc, created_desc, id_desc

  List<Booking> get allBookings => _allBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;

  /// รายการที่กรองตามสถานะ คำค้นหา และเรียงลำดับแบบเรียลไทม์เพื่อนำไปแสดงผลบนหน้าจอ
  List<Booking> get displayedBookings {
    List<Booking> list = List.from(_allBookings);

    // 1. กรองตามแท็บสถานะ (Status Tab Filter)
    if (_selectedStatus == 'PENDING') {
      list = list.where((b) => b.status == 'PENDING' || b.status == 'APPROVED').toList();
    } else if (_selectedStatus != 'ALL') {
      list = list.where((b) => b.status == _selectedStatus).toList();
    }

    // 2. ค้นหาแบบเรียลไทม์ (Real-time Search Query)
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((b) {
        final idMatch = b.id.toString().contains(q);
        final eqMatch = b.equipmentDetail?.name.toLowerCase().contains(q) ?? false;
        final borrowerMatch = b.borrowerName.toLowerCase().contains(q);
        final phoneMatch = b.borrowerPhone.toLowerCase().contains(q);
        final studentIdMatch = b.borrowerStudentId.toLowerCase().contains(q);
        final purposeMatch = b.purpose.toLowerCase().contains(q);
        return idMatch || eqMatch || borrowerMatch || phoneMatch || studentIdMatch || purposeMatch;
      }).toList();
    }

    // 3. เรียงลำดับ (Sorting)
    switch (_sortBy) {
      case 'pickup_desc':
        list.sort((a, b) => '${b.pickupDate} ${b.pickupTime}'.compareTo('${a.pickupDate} ${a.pickupTime}'));
        break;
      case 'created_desc':
      case 'id_desc':
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'pickup_asc':
      default:
        list.sort((a, b) => '${a.pickupDate} ${a.pickupTime}'.compareTo('${b.pickupDate} ${b.pickupTime}'));
        break;
    }

    return list;
  }

  /// สถิติที่คำนวณจากข้อมูลจริงทั้งหมด สม่ำเสมอและไม่ลดเป็น 0 เมื่อคลิกฟิลเตอร์
  int get pendingCount => _allBookings.where((b) => b.status == 'PENDING' || b.status == 'APPROVED').length;
  int get pickedUpCount => _allBookings.where((b) => b.status == 'PICKED_UP').length;
  int get returnedCount => _allBookings.where((b) => b.status == 'RETURNED').length;
  int get totalCount => _allBookings.length;

  /// โหลดรายการจองทั้งหมดจาก Data Layer ผ่าน Result Pattern
  Future<void> loadBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await bookingRepository.getBookings();

    switch (result) {
      case Success(:final data):
        _allBookings = data;
        _isLoading = false;
        notifyListeners();
      case Failure(:final message):
        _errorMessage = message;
        _isLoading = false;
        notifyListeners();
    }
  }

  /// ค้นหาแบบเรียลไทม์ขณะพิมพ์
  void search(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// สลับฟิลเตอร์แสดงผลในเครื่อง โดยไม่ทำลายข้อมูลสถิติรวม
  void setStatusFilter(String status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    notifyListeners();
  }

  /// เปลี่ยนรูปแบบการเรียงลำดับ
  void setSortBy(String sortOption) {
    if (_sortBy == sortOption) return;
    _sortBy = sortOption;
    notifyListeners();
  }

  /// สร้างรายการจองใหม่
  Future<bool> createBooking(Map<String, dynamic> payload) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await bookingRepository.createBooking(payload);

    switch (result) {
      case Success():
        await loadBookings();
        return true;
      case Failure(:final message):
        _errorMessage = message;
        _isLoading = false;
        notifyListeners();
        return false;
    }
  }

  /// อัปเดตสถานะ เช่น รับอุปกรณ์แล้ว หรือ คืนอุปกรณ์แล้ว
  Future<bool> updateStatus(int id, String newStatus) async {
    final result = await bookingRepository.updateBookingStatus(id, newStatus);

    switch (result) {
      case Success():
        await loadBookings();
        return true;
      case Failure(:final message):
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }

  /// ลบรายการจอง
  Future<bool> deleteBooking(int id) async {
    final result = await bookingRepository.deleteBooking(id);

    switch (result) {
      case Success():
        await loadBookings();
        return true;
      case Failure(:final message):
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }
}
