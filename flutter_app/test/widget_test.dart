// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kisaan_mitra/main.dart';
import 'package:kisaan_mitra/services/auth_session_manager.dart';

void main() {
  testWidgets('App splash screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const KisaanMitraApp());
    await tester.pump();

    // Verify that splash screen title is displayed.
    expect(find.textContaining('Farm Smarter'), findsOneWidget);

    // Cancel periodic keep-alive timer
    AuthSessionManager().dispose();
  });
}
