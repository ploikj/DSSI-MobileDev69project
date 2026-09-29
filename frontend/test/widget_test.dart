import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('ITBookingApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ITBookingApp());
    expect(find.text('อุปกรณ์ไอที'), findsWidgets);
  });
}
