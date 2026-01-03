import 'package:flutter_test/flutter_test.dart';
import 'package:luckyeta/app.dart';

void main() {
  testWidgets('SplashScreen is displayed', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const LuckyEtaApp());

    // Trigger a frame
    await tester.pump();

    // Verify that SplashScreen placeholder is present
    expect(find.text('SplashScreen placeholder'), findsOneWidget);
  });
}

