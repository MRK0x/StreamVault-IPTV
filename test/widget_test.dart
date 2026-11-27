import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mrk0slive/l10n/app_text.dart';
import 'package:mrk0slive/state/locale_controller.dart';
import 'package:mrk0slive/ui/auth/login_screen.dart';

void main() {
  testWidgets('login screen shows the brand name and login fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        // Strings come from AppText, so the delegates are required, as in the
        // real app.
        child: MaterialApp(
          locale: Locale('ar'),
          supportedLocales: LocaleController.supported,
          localizationsDelegates: [
            AppText.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: LoginScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    // The brand name is fixed (not translated); the login button comes from
    // the Arabic translation.
    expect(find.text('MRK0sLivE'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
