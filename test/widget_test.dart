import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivin/constant/app_strings.dart';
import 'package:vivin/main.dart';

void main() {
  testWidgets('CompanionApp loads LoginScreen with logo and credential fields',
      (WidgetTester tester) async {
    // Set a realistic mobile screen size (400 x 900)
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const CompanionApp());

    // Verify App Name is present
    expect(find.text(AppStrings.appName), findsOneWidget);

    // Verify Welcome Back text
    expect(find.text(AppStrings.loginTitle), findsOneWidget);

    // Verify Username and Password input labels
    expect(find.text(AppStrings.usernameLabel), findsOneWidget);
    expect(find.text(AppStrings.passwordLabel), findsOneWidget);

    // Verify Login button
    expect(find.text(AppStrings.loginButton), findsOneWidget);
  });
}
