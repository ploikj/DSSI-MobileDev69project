import '../models/equipment.dart';
import '../services/api_service.dart';
import 'result.dart';

/// Repository สำหรับจัดการคลังอุปกรณ์ไอที
/// คืนค่าเป็น `Result<List<Equipment>>` ตาม Result Pattern
class EquipmentRepository {
  final ApiService apiService;

  EquipmentRepository({required this.apiService});

  Future<Result<List<Equipment>>> getEquipments({String? category, String? search}) async {
    try {
      final list = await apiService.fetchEquipments(category: category, search: search);
      return Success(list);
    } catch (e) {
      return Failure('ไม่สามารถดึงข้อมูลอุปกรณ์ได้: $e', e is Exception ? e : Exception(e.toString()));
    }
  }
}
