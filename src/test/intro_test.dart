import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anderfit/main.dart';

void main() {
  testWidgets('Abertura mostra marca no preto e segue para o acesso', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      Anderfit(prefs: await SharedPreferences.getInstance()),
    );
    expect(find.byKey(const ValueKey('intro')), findsOneWidget);
    expect(find.text('ANDERFIT'), findsOneWidget);
    expect(find.text('Força, foco, evolução.'), findsOneWidget);
    expect(find.textContaining('CREF'), findsNothing);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.black,
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('intro')), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
