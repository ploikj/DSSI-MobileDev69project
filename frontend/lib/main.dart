import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1. Services
import 'services/api_service.dart';
import 'services/token_storage_service.dart';

// 2. Repositories
import 'repositories/auth_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/equipment_repository.dart';

// 3. ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/booking_viewmodel.dart';
import 'viewmodels/equipment_viewmodel.dart';

// 4. Views
import 'views/login_oidc_view.dart';
import 'views/main_navigation_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RootAppWithProviders());
}

/// Root Widget ที่กำหนด Dependency Injection ผ่าน MultiProvider
class RootAppWithProviders extends StatelessWidget {
  final Widget? child;

  const RootAppWithProviders({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- 1. Services Layer (Network & Secure Storage) ---
        Provider<TokenStorageService>(
          create: (_) => TokenStorageService(),
        ),
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),

        // --- 2. Repository Layer (Result Pattern & Data Abstraction) ---
        ProxyProvider2<ApiService, TokenStorageService, AuthRepository>(
          update: (_, apiService, tokenStorage, prev) => AuthRepository(
            apiService: apiService,
            tokenStorage: tokenStorage,
          ),
        ),
        ProxyProvider<ApiService, EquipmentRepository>(
          update: (_, apiService, prev) => EquipmentRepository(
            apiService: apiService,
          ),
        ),
        ProxyProvider<ApiService, BookingRepository>(
          update: (_, apiService, prev) => BookingRepository(
            apiService: apiService,
          ),
        ),

        // --- 3. ViewModel Layer (State Management via ChangeNotifier) ---
        ChangeNotifierProxyProvider<AuthRepository, AuthViewModel>(
          create: (ctx) => AuthViewModel(
            authRepository: ctx.read<AuthRepository>(),
          ),
          update: (_, authRepo, vm) => (vm ?? AuthViewModel(authRepository: authRepo))
            ..updateRepository(authRepo),
        ),
        ChangeNotifierProxyProvider<EquipmentRepository, EquipmentViewModel>(
          create: (ctx) => EquipmentViewModel(
            equipmentRepository: ctx.read<EquipmentRepository>(),
          ),
          update: (_, eqRepo, vm) => (vm ?? EquipmentViewModel(equipmentRepository: eqRepo))
            ..updateRepository(eqRepo),
        ),
        ChangeNotifierProxyProvider<BookingRepository, BookingViewModel>(
          create: (ctx) => BookingViewModel(
            bookingRepository: ctx.read<BookingRepository>(),
          ),
          update: (_, bookingRepo, vm) => (vm ?? BookingViewModel(bookingRepository: bookingRepo))
            ..updateRepository(bookingRepo),
        ),
      ],
      child: child ?? const ITBookingApp(),
    );
  }
}

class ITBookingApp extends StatelessWidget {
  const ITBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UBU IT Equipment Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Indigo / Deep Blue
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 1.5,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const RouteGuardRoot(),
    );
  }
}

/// Route Guard Root:
/// - ตรวจสอบ Session จาก flutter_secure_storage อัตโนมัติเมื่อเปิดแอปผ่าน AuthViewModel
/// - หากยังไม่ล็อกอิน: บล็อกเนื้อหาทุกหน้าและแสดง LoginOidcView ทันที
/// - หากล็อกอินแล้ว: ปลดล็อกหน้าจอเนื้อหาทั้งหมด (MainNavigationView)
class RouteGuardRoot extends StatefulWidget {
  const RouteGuardRoot({super.key});

  @override
  State<RouteGuardRoot> createState() => _RouteGuardRootState();
}

class _RouteGuardRootState extends State<RouteGuardRoot> {
  @override
  void initState() {
    super.initState();
    // เริ่มต้นตรวจสอบ Token จาก Secure Storage เมื่อ Widget ถูกสร้าง
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().initSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    // 1. กำลังตรวจสอบ Token จาก Secure Storage
    if (!authVM.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'กำลังตรวจสอบ Session ใน flutter_secure_storage...',
                style: TextStyle(color: Colors.blueGrey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // 2. ROUTE GUARD: หากยังไม่ล็อกอิน ไม่อนุญาตให้เข้าถึงเนื้อหาใดๆ
    if (!authVM.isAuthenticated) {
      return const LoginOidcView();
    }

    // 3. เข้าสู่ระบบสำเร็จแล้ว ปลดล็อกหน้าจอเนื้อหาทั้งหมด
    return const MainNavigationView();
  }
}
