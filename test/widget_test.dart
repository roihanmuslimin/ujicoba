import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/main.dart';

void main() {
  testWidgets('App loads and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const QuranApp());
    expect(find.text('Al-Qur\'an'), findsOneWidget);
  });
}
