import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../repositories/booking_repository.dart';
import '../repositories/result.dart';

/// ViewModel สำหรับจัดการการจองและกำหนดการรับอุปกรณ์ไอทีตามสถาปัตยกรรม MVVM
class BookingViewModel extends ChangeNotifier {
  BookingRepository bookingRepository;

  BookingViewModel({required this.bookingRepository});

  void updateRepository(BookingRepository repository) {
    bookingRepository = repository;
  }

  List<Booking> _allBookings = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatus = 'ALL';

  List<Booking> get allBookings => _allBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatus => _selectedStatus;

  /// รายการที่กรองตามแท็บที่เลือกเพื่อนำไปแสดงผลบนหน้าจอ
  List<Booking> get displayedBookings {
    if (_selectedStatus == 'ALL') return _allBookings;
    if (_selectedStatus == 'PENDING') {
      return _allBookings.where((b) => b.status == 'PENDING' || b.status == 'APPROVED').toList();
    }
    return _allBookings.where((b) => b.status == _selectedStatus).toList();
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

  /// สลับฟิลเตอร์แสดงผลในเครื่อง โดยไม่ทำลายข้อมูลสถิติรวม
  void setStatusFilter(String status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
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
