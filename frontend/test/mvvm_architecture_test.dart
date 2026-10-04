import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/booking.dart';
import 'package:frontend/repositories/auth_repository.dart';
import 'package:frontend/repositories/booking_repository.dart';
import 'package:frontend/repositories/equipment_repository.dart';
import 'package:frontend/repositories/result.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/localization_service.dart';
import 'package:frontend/services/token_storage_service.dart';
import 'package:frontend/viewmodels/auth_viewmodel.dart';
import 'package:frontend/viewmodels/booking_viewmodel.dart';
import 'package:frontend/viewmodels/equipment_viewmodel.dart';
import 'package:frontend/viewmodels/locale_viewmodel.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeTokenStorageService extends TokenStorageService {
  String? _savedLocale;
  Map<String, dynamic>? _savedSession;

  @override
  Future<void> saveLocale(String langCode) async {
    _savedLocale = langCode;
  }

  @override
  Future<String?> loadLocale() async {
    return _savedLocale;
  }

  @override
  Future<void> saveSession(Map<String, dynamic> session) async {
    _savedSession = session;
  }

  @override
  Future<Map<String, dynamic>?> loadSession() async {
    return _savedSession;
  }
}

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

      // Real-time search in bookings
      vm.setStatusFilter('ALL');
      vm.search('Presentation');
      expect(vm.displayedBookings.length, 1);
      expect(vm.displayedBookings.first.id, 102);

      // Sorting in bookings
      vm.search('');
      vm.setSortBy('pickup_asc');
      expect(vm.displayedBookings.first.id, 102); // 2026-10-01 is sooner than 2026-10-05
      vm.setSortBy('pickup_desc');
      expect(vm.displayedBookings.first.id, 101); // 2026-10-05 is later
    });
  });

  group('Equipment Real-time Search, Filter & Sort Tests', () {
    test('EquipmentViewModel real-time search, category filter, availability, and multi-sort work in-memory', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '''[
            {
              "id": 1,
              "name": "Dell Latitude 5420",
              "category": "laptop",
              "category_display": "โน้ตบุ๊ก",
              "total_quantity": 5,
              "available_quantity": 3,
              "is_available": true,
              "pickup_location": "EN2-204",
              "description": "High performance i7"
            },
            {
              "id": 2,
              "name": "Epson Projector EB-X06",
              "category": "projector",
              "category_display": "โปรเจกเตอร์",
              "total_quantity": 2,
              "available_quantity": 0,
              "is_available": false,
              "pickup_location": "EN2-205",
              "description": "HD 3600 lumens"
            },
            {
              "id": 3,
              "name": "Apple iPad Air 5",
              "category": "tablet",
              "category_display": "แท็บเล็ต",
              "total_quantity": 4,
              "available_quantity": 4,
              "is_available": true,
              "pickup_location": "EN2-204",
              "description": "M1 chip 64GB"
            }
          ]''',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final repo = EquipmentRepository(apiService: apiService);
      final vm = EquipmentViewModel(equipmentRepository: repo);

      await vm.loadEquipments();
      expect(vm.equipments.length, 3);

      // 1. Real-time Search
      vm.search('Epson');
      expect(vm.equipments.length, 1);
      expect(vm.equipments.first.name, 'Epson Projector EB-X06');

      vm.search('');
      expect(vm.equipments.length, 3);

      // 2. Category Filter
      vm.setCategory('tablet');
      expect(vm.equipments.length, 1);
      expect(vm.equipments.first.name, 'Apple iPad Air 5');

      vm.setCategory('all');
      expect(vm.equipments.length, 3);

      // 3. Availability Filter
      vm.toggleOnlyAvailable(true);
      expect(vm.equipments.length, 2);
      expect(vm.equipments.any((e) => e.name.contains('Epson')), isFalse);

      vm.toggleOnlyAvailable(false);
      expect(vm.equipments.length, 3);

      // 4. Sorting: name_asc vs name_desc vs available_desc
      vm.setSortBy('name_asc');
      expect(vm.equipments.first.name, 'Apple iPad Air 5');
      expect(vm.equipments.last.name, 'Epson Projector EB-X06');

      vm.setSortBy('name_desc');
      expect(vm.equipments.first.name, 'Epson Projector EB-X06');
      expect(vm.equipments.last.name, 'Apple iPad Air 5');

      vm.setSortBy('available_desc');
      expect(vm.equipments.first.availableQuantity, 4); // iPad has 4
      expect(vm.equipments.last.availableQuantity, 0);  // Epson has 0
    });
  });

  group('LocaleViewModel & Localization Tests', () {
    test('LocalizationService translates keys in TH and EN with parameter interpolation', () {
      // Direct service test
      expect(LocalizationService.translate('app_title', 'th'), 'ระบบจองอุปกรณ์ไอที');
      expect(LocalizationService.translate('app_title', 'en'), 'IT Equipment Booking');

      final withParams = LocalizationService.translate('found_items', 'th', {'count': '5'});
      expect(withParams, 'พบ 5 รายการ');

      final withParamsEn = LocalizationService.translate('found_items', 'en', {'count': '5'});
      expect(withParamsEn, 'Found 5 items');
    });

    test('LocaleViewModel toggles between TH and EN and notifies listeners', () async {
      final storage = FakeTokenStorageService();
      final vm = LocaleViewModel(tokenStorage: storage);

      expect(vm.currentLocale, 'th');
      expect(vm.isThai, isTrue);
      expect(vm.isEnglish, isFalse);
      expect(vm.t('nav_equipment'), 'อุปกรณ์ไอที');

      // Toggle to English
      await vm.toggleLocale();
      expect(vm.currentLocale, 'en');
      expect(vm.isThai, isFalse);
      expect(vm.isEnglish, isTrue);
      expect(vm.t('nav_equipment'), 'IT Equipments');
      expect(await storage.loadLocale(), 'en');

      // Set to Thai directly
      await vm.setLocale('th');
      expect(vm.currentLocale, 'th');
      expect(vm.isThai, isTrue);
      expect(await storage.loadLocale(), 'th');
    });
  });

  group('Auth & Booking Permission Tests (Owner & Admin Restriction)', () {
    final sampleBooking = Booking(
      id: 101,
      userId: 2,
      username: 'narathip',
      borrowerName: 'ณราธิป นันทสุรสีห์',
      borrowerPhone: '081-234-5678',
      borrowerStudentId: '65140001',
      borrowerEmail: 'narathip@ubu.ac.th',
      quantity: 1,
      pickupDate: '2026-10-05',
      pickupTime: '10:00:00',
      returnDate: '2026-10-07',
      purpose: 'Final Project Testing',
      status: 'PENDING',
      statusDisplay: 'รอนัดรับ',
      note: '',
    );

    test('Unauthenticated user cannot manage booking', () {
      final storage = FakeTokenStorageService();
      final apiService = ApiService(client: MockClient((_) async => http.Response('{}', 200)));
      final repo = AuthRepository(apiService: apiService, tokenStorage: storage);
      final authVM = AuthViewModel(authRepository: repo);

      expect(authVM.isAuthenticated, isFalse);
      expect(authVM.canManageBooking(sampleBooking), isFalse);
      expect(authVM.isBookingOwner(sampleBooking), isFalse);
    });

    test('Booking owner ("เจ้าตัว") can manage their own booking', () async {
      final storage = FakeTokenStorageService();
      await storage.saveSession({
        'accessToken': 'dummy-token',
        'username': 'narathip',
        'claims': {
          'sub': '2',
          'preferred_username': 'narathip',
          'student_id': '65140001',
          'email': 'narathip@ubu.ac.th',
          'is_staff': false,
        }
      });
      final apiService = ApiService(client: MockClient((_) async => http.Response('{}', 200)));
      final repo = AuthRepository(apiService: apiService, tokenStorage: storage);
      final authVM = AuthViewModel(authRepository: repo);
      await authVM.initSession();

      expect(authVM.isAuthenticated, isTrue);
      expect(authVM.isAdmin, isFalse);
      expect(authVM.isBookingOwner(sampleBooking), isTrue);
      expect(authVM.canManageBooking(sampleBooking), isTrue);
    });

    test('Non-owner user cannot manage other user booking', () async {
      final storage = FakeTokenStorageService();
      await storage.saveSession({
        'accessToken': 'dummy-token',
        'username': 'sompong',
        'claims': {
          'sub': '99',
          'preferred_username': 'sompong',
          'student_id': '65999999',
          'email': 'sompong@ubu.ac.th',
          'is_staff': false,
        }
      });
      final apiService = ApiService(client: MockClient((_) async => http.Response('{}', 200)));
      final repo = AuthRepository(apiService: apiService, tokenStorage: storage);
      final authVM = AuthViewModel(authRepository: repo);
      await authVM.initSession();

      expect(authVM.isAuthenticated, isTrue);
      expect(authVM.isAdmin, isFalse);
      expect(authVM.isBookingOwner(sampleBooking), isFalse);
      expect(authVM.canManageBooking(sampleBooking), isFalse);
    });

    test('Admin user can manage any booking', () async {
      final storage = FakeTokenStorageService();
      await storage.saveSession({
        'accessToken': 'admin-token',
        'username': 'admin',
        'claims': {
          'sub': '1',
          'preferred_username': 'admin',
          'roles': ['staff'],
          'is_staff': true,
          'is_superuser': true,
        }
      });
      final apiService = ApiService(client: MockClient((_) async => http.Response('{}', 200)));
      final repo = AuthRepository(apiService: apiService, tokenStorage: storage);
      final authVM = AuthViewModel(authRepository: repo);
      await authVM.initSession();

      expect(authVM.isAuthenticated, isTrue);
      expect(authVM.isAdmin, isTrue);
      expect(authVM.canManageBooking(sampleBooking), isTrue);
    });
  });
}
