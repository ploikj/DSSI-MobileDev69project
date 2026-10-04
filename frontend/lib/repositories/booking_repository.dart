import '../models/booking.dart';
import '../services/api_service.dart';
import 'result.dart';

/// Repository สำหรับจัดการรายการจองอุปกรณ์และกำหนดการรับ
/// จัดการข้อผิดพลาดและส่งกลับข้อมูลผ่าน Result Pattern
class BookingRepository {
  final ApiService apiService;

  BookingRepository({required this.apiService});

  /// ดึงรายการจองทั้งหมด
  Future<Result<List<Booking>>> getBookings({String? status, String? search}) async {
    try {
      final list = await apiService.fetchBookings(status: status, search: search);
      return Success(list);
    } catch (e) {
      return Failure('ไม่สามารถดึงข้อมูลการจองได้: $e', e is Exception ? e : Exception(e.toString()));
    }
  }

  /// สร้างรายการจองใหม่
  Future<Result<Booking>> createBooking(Map<String, dynamic> payload) async {
    try {
      final booking = await apiService.createBooking(payload);
      return Success(booking);
    } catch (e) {
      return Failure('ทำรายการจองไม่สำเร็จ: $e', e is Exception ? e : Exception(e.toString()));
    }
  }

  /// อัปเดตสถานะการจอง (เช่น รับอุปกรณ์แล้ว, คืนอุปกรณ์แล้ว)
  Future<Result<Booking>> updateBookingStatus(int id, String newStatus) async {
    try {
      final booking = await apiService.updateBookingStatus(id, newStatus);
      return Success(booking);
    } catch (e) {
      return Failure('อัปเดตสถานะไม่สำเร็จ: $e', e is Exception ? e : Exception(e.toString()));
    }
  }

  /// ลบรายการจอง
  Future<Result<void>> deleteBooking(int id) async {
    try {
      await apiService.deleteBooking(id);
      return const Success(null);
    } catch (e) {
      return Failure('ลบรายการจองไม่สำเร็จ: $e', e is Exception ? e : Exception(e.toString()));
    }
  }
}
