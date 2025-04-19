// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:chrono_dart/chrono_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_secretary/util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_secretary/main.dart';

void main() {
  setUpAll(() async {
    // Mock shared_preferences
    SharedPreferences.setMockInitialValues({});

    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize Supabase for testing
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  });

  testWidgets('App should render successfully', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle(); // Ensure all animations complete

    // Verify that app renders without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App should have basic structure', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle(); // Ensure all animations complete

    // Check for common Flutter widgets that should be in almost any app
    expect(find.byType(Text), findsWidgets);
    expect(find.byType(Container), findsWidgets);

    // Instead of looking for specific text, check for widgets by type
    expect(find.byType(Scaffold), findsWidgets); // Most apps have a Scaffold

    // Print all text in the app to help debug what text is actually available
    final textWidgets = tester.widgetList(find.byType(Text));
    debugPrint('Found ${textWidgets.length} Text widgets in the app:');
    for (final widget in textWidgets) {
      final textWidget = widget as Text;
      debugPrint('- Text: "${textWidget.data}"');
    }
  });

  test("eventParseing", () {
    /*
      title: Soccer
      description: 
      location: Sage Park
      start_time_expression: 5:00 PM
      end_time_expression: 7:00 PM
      is_recurring: false
      recurrence_frequency: 
      recurrence_interval: 
      recurrence_days:
     */

    String data =
        "title: Soccer \ndescription: \nlocation: Sage Park \nstart_time_expression: 5:00 PM \nend_time_expression: 7:00 PM \nis_recurring: false \nrecurrence_frequency: \nrecurrence_interval: \nrecurrence_days:";

    Map<String, dynamic> expectedResult = {
      "title": "Soccer",
      "description": "",
      "location": "Sage Park",
      "start_time_expression": Chrono.parseDate("5:00 PM"),
      "end_time_expression": Chrono.parseDate("7:00 PM"),
      "is_recurring": "false",
      "recurrence_frequency": "",
      "recurrence_interval": "",
      "recurrence_days": ""
    };

    expect(eventParseing(data), equals(expectedResult));
  });
}
