import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:microtask_project/screens/auth/register_screen.dart';

void main() {
  testWidgets('OTP field appears after Register and countdown runs', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    expect(find.byKey(const Key('otpField')), findsNothing);
    expect(find.byKey(const Key('resendOtpButton')), findsNothing);

    await tester.enterText(find.byKey(const Key('nameField')), 'John');
    await tester.enterText(find.byKey(const Key('emailField')), 'john@example.com');
    await tester.enterText(find.byKey(const Key('phoneField')), '1234567890');
    await tester.enterText(find.byKey(const Key('locationField')), 'City');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
    await tester.enterText(find.byKey(const Key('confirmPasswordField')), 'password123');

    await tester.ensureVisible(find.byKey(const Key('registerButton')));
    await tester.tap(find.byKey(const Key('registerButton')));
    await tester.pump();

    expect(find.byKey(const Key('otpField')), findsOneWidget);
    expect(find.textContaining('Resend in'), findsOneWidget);

    await tester.pump(const Duration(seconds: 61));
    expect(find.text('You can resend now'), findsOneWidget);

    final ElevatedButton resend =
        tester.widget(find.byKey(const Key('resendOtpButton')));
    expect(resend.onPressed != null, true);
  });
}
