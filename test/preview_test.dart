import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anderfit/main.dart';

void main() {
  testWidgets('Renderiza a prévia da tela inicial', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final fonts = FontLoader('Anderfit')
      ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/roboto-bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/roboto-black.ttf'));
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'Roboto',
    )..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'))).load();
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: Anderfit(prefs: await SharedPreferences.getInstance()),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/logo.png'),
        boundary.currentContext!,
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) => tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('../$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await capture('anderfit-abertura');
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    await capture('anderfit-acesso');
    await tester.ensureVisible(find.text('ENTRAR COMO ALUNO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ENTRAR COMO ALUNO'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Lucas Ferreira');
    await tester.enterText(fields.at(1), '178');
    await tester.enterText(fields.at(2), '82,5');
    await tester.enterText(fields.at(3), 'Ganhar condicionamento');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aulas'));
    await tester.pumpAndSettle();
    await capture('anderfit-biblioteca');
    await tester.tap(find.text('Masculino'));
    await tester.pumpAndSettle();
    await capture('anderfit-biblioteca-masculino');
    await tester.tap(find.text('Iniciante'));
    await tester.pumpAndSettle();
    await capture('anderfit-biblioteca-iniciante-masculino');
    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '../anderfit-preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
