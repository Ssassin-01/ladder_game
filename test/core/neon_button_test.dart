import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ladder_game/core/neon_button.dart';
import 'package:ladder_game/core/neon_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('NeonButton renders text and triggers onPressed on tap', (WidgetTester tester) async {
    bool isPressed = false;
    const buttonText = '테스트 버튼';

    // Build the NeonButton widget wrapped in ThemeProvider
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: buttonText,
              onPressed: () {
                isPressed = true;
              },
            ),
          ),
        ),
      ),
    );

    // 1. Verify that the button text is rendered
    expect(find.text(buttonText), findsOneWidget);

    // 2. Tap the button
    await tester.tap(find.byType(NeonButton));
    
    // 애니메이션(150ms) 이후 동작을 위해 시간을 흐르게 함
    await tester.pumpAndSettle();

    // 3. Verify that the onPressed callback was triggered
    expect(isPressed, isTrue);
  });
}
