import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/repositories/booking_repository.dart';
import 'package:frontend/repositories/equipment_repository.dart';
import 'package:frontend/repositories/result.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/viewmodels/booking_viewmodel.dart';
import 'package:frontend/viewmodels/equipment_viewmodel.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Result Pattern Tests', () {
    test('Success contains data and isSuccess is true', () {
      const result = Success<int>(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, 42);
      expect(result.dataOrNull, 42);
      expect(result.errorOrNull, isNull);

      final transformed = result.when(
        success: (d) => 'value: $d',
        failure: (m, e) => 'error: $m',
      );
      expect(transformed, 'value: 42');
    });

    test('Failure contains message and isFailure is true', () {
      const result = Failure<int>('Network error');
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.message, 'Network error');
      expect(result.dataOrNull, isNull);
      expect(result.errorOrNull, 'Network error');

      final transformed = result.when(
        success: (d) => 'value: $d',
        failure: (m, e) => 'error: $m',
      );
      expect(transformed, 'error: Network error');
    });
  });

  group('Equipment MVVM Layer Tests', () {
    test('EquipmentRepository returns Success on 200 HTTP response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '''[
            {
              "id": 1,
              "name": "Dell XPS 13",
              "category": "laptop",
              "category_display": "โน้ตบุ๊ก",
              "model_number": "XPS-9320",
              "description": "Core i7",
              "image_url": "",
              "total_quantity": 5,
              "available_quantity": 3,
              "pickup_location": "ห้อง EN2"
            }
          ]''',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final repo = EquipmentRepository(apiService: apiService);

      final result = await repo.getEquipments();
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.length, 1);
      expect(result.dataOrNull?.first.name, 'Dell XPS 13');
    });

    test('EquipmentRepository returns Failure on 500 error without throwing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final apiService = ApiService(client: mockClient);
      final repo = EquipmentRepository(apiService: apiService);

      final result = await repo.getEquipments();
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, contains('ไม่สามารถดึงข้อมูลอุปกรณ์ได้'));
    });

    test('EquipmentViewModel updates state and notifies listeners', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '''[
            {
              "id": 1,
              "name": "MacBook Pro M3",
              "category": "laptop",
              "category_display": "โน้ตบุ๊ก",
              "total_quantity": 4,
              "available_quantity": 2,
              "pickup_location": "EN2"
            }
          ]''',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final repo = EquipmentRepository(apiService: apiService);
      final vm = EquipmentViewModel(equipmentRepository: repo);

      expect(vm.isLoading, isFalse);
      expect(vm.equipments.isEmpty, isTrue);

      await vm.loadEquipments();

      expect(vm.isLoading, isFalse);
      expect(vm.equipments.length, 1);
      expect(vm.equipments.first.name, 'MacBook Pro M3');
    });
  });

  group('Booking MVVM Layer Tests', () {
    test('BookingViewModel calculates consistent counts and filters in-memory', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '''[
            {
              "id": 101,
              "borrower_name": "Test User",
              "borrower_phone": "0812345678",
              "quantity": 1,
              "pickup_date": "2026-10-05",
              "pickup_time": "09:30:00",
              "return_date": "2026-10-08",
              "purpose": "Test Project",
              "status": "PENDING",
              "status_display": "รอนัดรับ",
              "note": ""
            },
            {
              "id": 102,
              "borrower_name": "Test User",
              "borrower_phone": "0812345678",
              "quantity": 1,
              "pickup_date": "2026-10-01",
              "pickup_time": "10:00:00",
              "return_date": "2026-10-04",
              "purpose": "Presentation",
              "status": "PICKED_UP",
              "status_display": "รับอุปกรณ์แล้ว",
              "note": ""
            }
          ]''',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final repo = BookingRepository(apiService: apiService);
      final vm = BookingViewModel(bookingRepository: repo);

      await vm.loadBookings();

      // Verify global counters calculated from total data
      expect(vm.totalCount, 2);
      expect(vm.pendingCount, 1);
      expect(vm.pickedUpCount, 1);
      expect(vm.returnedCount, 0);

      // Verify that changing status filter does NOT reset counters!
      vm.setStatusFilter('PICKED_UP');
      expect(vm.displayedBookings.length, 1);
      expect(vm.displayedBookings.first.id, 102);

      // Counters remain identical!
      expect(vm.pendingCount, 1);
      expect(vm.pickedUpCount, 1);
      expect(vm.returnedCount, 0);
    });
  });
}
