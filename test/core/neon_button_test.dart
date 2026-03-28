import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:betting_app/core/neon_button.dart';

void main() {
  testWidgets('NeonButton renders text and triggers onPressed on tap', (WidgetTester tester) async {
    bool isPressed = false;
    const buttonText = '테스트 버튼';

    // Build the NeonButton widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NeonButton(
            text: buttonText,
            onPressed: () {
              isPressed = true;
            },
          ),
        ),
      ),
    );

    // 1. Verify that the button text is rendered
    expect(find.text(buttonText), findsOneWidget);

    // 2. Tap the button
    await tester.tap(find.byType(NeonButton));
    
    // Tap 애니메이션(150ms)과 이후 동작을 위해 시간을 흐르게 함
    await tester.pumpAndSettle();

    // 3. Verify that the onPressed callback was triggered
    expect(isPressed, isTrue);
  });
}
