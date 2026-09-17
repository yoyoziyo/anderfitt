import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anderfit/main.dart';
import 'package:anderfit/backend.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('Desktop usa menu lateral e abre evolução sem overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      Anderfit(showIntro: false, prefs: await SharedPreferences.getInstance()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ÁREA DO PERSONAL'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('Evolução'));
    await tester.pumpAndSettle();
    expect(find.text('Sua evolução'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Produção exige usuário e senha sem seletor de função', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final client = SupabaseClient(supabaseUrl, supabasePublishableKey);
    final backend = BackendService(client);
    await tester.pumpWidget(
      Anderfit(
        showIntro: false,
        prefs: await SharedPreferences.getInstance(),
        backend: backend,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Usuário'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
    expect(find.text('ENTRAR COMO ALUNO'), findsNothing);
    expect(find.text('ÁREA DO PERSONAL'), findsNothing);
    client.auth.stopAutoRefresh();
  });

  testWidgets('Personal cadastra aluno e prescreve exercício', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(Anderfit(showIntro: false, prefs: prefs));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ÁREA DO PERSONAL'));
    await tester.tap(find.text('ÁREA DO PERSONAL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo aluno'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Marina');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ADICIONAR EXERCÍCIO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ADICIONAR EXERCÍCIO'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Agachamento');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(prefs.getString('anderfit.v1'), contains('Marina'));
    expect(prefs.getString('anderfit.v1'), contains('Agachamento'));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
  test('Treino exige todos os exercícios e só contabiliza uma vez por dia', () {
    final student = Student.create('Aluno');
    expect(student.complete(), false);
    student.exercises.add({'id': '1'});
    student.exercises.add({'id': '2'});
    student.checks[today()] = ['1'];
    expect(student.complete(), false);
    (student.checks[today()] as List).add('2');
    expect(student.complete(), true);
    expect(student.complete(), false);
    expect(student.history, [today()]);
  });
  test('Hidratação e exercícios são separados por aluno e dia', () {
    final a = Student.create('A');
    final b = Student.create('B');
    a.water['2000-01-01'] = 1500;
    expect(a.waterToday, 0);
    a.water[today()] = 250;
    expect(a.waterToday, 250);
    expect(b.waterToday, 0);
  });
  testWidgets('Acesso, navegação e hidratação persistida em tela estreita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(Anderfit(showIntro: false, prefs: prefs));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ENTRAR COMO ALUNO'));
    await tester.tap(find.text('ENTRAR COMO ALUNO'));
    await tester.pumpAndSettle();
    expect(find.text('Seu primeiro acesso'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Lucas Ferreira');
    await tester.enterText(fields.at(1), '178');
    await tester.enterText(fields.at(2), '82,5');
    await tester.enterText(fields.at(3), 'Ganhar condicionamento');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Vamos pra cima,\nLucas.'), findsOneWidget);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('+ 250 ml'));
    await tester.tap(find.text('+ 250 ml'));
    await tester.pumpAndSettle();
    expect(find.text('250 ml'), findsOneWidget);
    expect(prefs.getString('anderfit.v1'), contains('250'));
    await tester.tap(find.text('Evolução'));
    await tester.pumpAndSettle();
    expect(find.text('Sua evolução'), findsOneWidget);
    await tester.tap(find.text('Treino'));
    await tester.pumpAndSettle();
    expect(find.text('Treino do dia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Biblioteca organiza os PDFs por perfil e nível', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      Anderfit(showIntro: false, prefs: await SharedPreferences.getInstance()),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ENTRAR COMO ALUNO'));
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
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Todos'), findsNothing);
    expect(find.text('Masculino'), findsOneWidget);
    expect(find.text('Feminino'), findsOneWidget);
    expect(find.text('Treino em casa'), findsOneWidget);
    expect(find.text('Receitas'), findsOneWidget);
    await tester.tap(find.text('Masculino'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciante'), findsOneWidget);
    expect(find.text('Intermediário'), findsOneWidget);
    expect(find.text('Avançado'), findsOneWidget);
    await tester.tap(find.text('Iniciante'));
    await tester.pumpAndSettle();
    expect(find.text('Treino Iniciante 01 - Masculino'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNWidgets(7));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Personal confirma antes de excluir um aluno', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      Anderfit(showIntro: false, prefs: await SharedPreferences.getInstance()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ÁREA DO PERSONAL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir aluno'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir aluno?'), findsOneWidget);
    expect(find.textContaining('Tem certeza'), findsOneWidget);
    await tester.tap(find.text('Excluir perfil'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nenhum aluno cadastrado.'), findsOneWidget);
    expect(find.text('CADASTRAR ALUNO'), findsOneWidget);
  });
}
