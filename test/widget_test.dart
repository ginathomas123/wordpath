import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:my_app/features/splash/splash_screen.dart';

void main() {
  testWidgets('Splash shows the WordPath wordmark', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump();

    expect(find.text('WordPath'), findsOneWidget);
  });
}
