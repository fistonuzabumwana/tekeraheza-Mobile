import 'package:flutter_test/flutter_test.dart';
import 'package:tekeraheza_mobile/main.dart';

void main() {
  testWidgets('App starts with Role Selection screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TekerahezaApp());

    // Verify that the title is present.
    expect(find.text('TEKERAHEZA'), findsOneWidget);
    
    // Verify that the role options are present.
    expect(find.text('I am a Customer'), findsOneWidget);
    expect(find.text('I am a Driver'), findsOneWidget);
  });
}
