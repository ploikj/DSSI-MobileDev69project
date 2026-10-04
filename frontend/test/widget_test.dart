import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('Route Guard displays OIDC Login view when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(const RootAppWithProviders());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Route Guard blocks content and displays OIDC Login view
    expect(find.text('ระบบจองอุปกรณ์ไอที'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบผ่าน OIDC Server'), findsOneWidget);
  });
}
