import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'backend.dart';
import 'training_library.dart';

const orange = Color(0xFFFF6B00);
const waterBlue = Color(0xFF29B6F6);
const personalWhatsApp = '5515996679148';
String today() => DateTime.now().toIso8601String().substring(0, 10);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  final backend = await initializeBackend();
  runApp(Anderfit(prefs: prefs, backend: backend));
}

class Student {
  Student(this.data);
  final Map<String, dynamic> data;
  String get name => data['name'];
  List<dynamic> get exercises => data['exercises'];
  List<dynamic> get history => data['history'];
  List<dynamic> get measures => data['measures'];
  Map<String, dynamic> get water => data['water'];
  Map<String, dynamic> get checks => data['checks'];
  int get waterToday => (water[today()] as num?)?.toInt() ?? 0;
  bool get completed => history.contains(today());
  bool get ready =>
      exercises.isNotEmpty &&
      exercises.every(
        (e) => (checks[today()] as List?)?.contains(e['id']) ?? false,
      );
  bool complete() {
    if (!ready || completed) return false;
    history.add(today());
    return true;
  }

  static Student create(String name) => Student({
    'name': name,
    'height': '',
    'objective': '',
    'profileComplete': false,
    'goalTitle': 'Defina sua meta com o personal',
    'goalStart': 0.0,
    'goalTarget': 0.0,
    'waterGoal': 2500,
    'exercises': <dynamic>[],
    'history': <dynamic>[],
    'measures': <dynamic>[],
    'water': <String, dynamic>{},
    'checks': <String, dynamic>{},
    'photos': <String, dynamic>{},
  });
}

class Anderfit extends StatelessWidget {
  const Anderfit({
    super.key,
    required this.prefs,
    this.backend,
    this.showIntro = true,
  });
  final SharedPreferences prefs;
  final BackendService? backend;
  final bool showIntro;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ANDERFIT',
    theme: ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Anderfit',
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: orange,
        onPrimary: Colors.black,
        surface: Color(0xFF17191D),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF17191D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: Color(0xFF37302A)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Anderfit',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
    home: showIntro
        ? BrandIntro(prefs: prefs, backend: backend)
        : AppShell(prefs: prefs, backend: backend),
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/logo.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    semanticLabel: 'Logo ANDERFIT',
  );
}

class BrandIntro extends StatefulWidget {
  const BrandIntro({super.key, required this.prefs, this.backend});
  final SharedPreferences prefs;
  final BackendService? backend;
  @override
  State<BrandIntro> createState() => _BrandIntroState();
}

class _BrandIntroState extends State<BrandIntro> {
  Timer? timer;
  bool ready = false;
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => ready = true);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 350),
    child: ready
        ? AppShell(
            key: const ValueKey('app'),
            prefs: widget.prefs,
            backend: widget.backend,
          )
        : const Scaffold(
            key: ValueKey('intro'),
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandMark(size: 240),
                    SizedBox(height: 20),
                    Text(
                      'ANDERFIT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Força, foco, evolução.',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.3,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.prefs, this.backend});
  final SharedPreferences prefs;
  final BackendService? backend;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late List<Student> students;
  int selected = 0, page = 0;
  bool entered = false, admin = false, loading = false, obscurePassword = true;
  String phone = personalWhatsApp, metric = 'Peso';
  Map<String, dynamic>? account;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  Student get student => students[selected];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.backend != null) {
      students = [];
      WidgetsBinding.instance.addPostFrameCallback((_) => restoreRemote());
      return;
    }
    final saved = widget.prefs.getString('anderfit.v1');
    try {
      final decoded = saved == null
          ? null
          : jsonDecode(saved) as Map<String, dynamic>;
      students = decoded == null
          ? [Student.create('Aluno')]
          : (decoded['students'] as List)
                .map((e) => Student(Map<String, dynamic>.from(e)))
                .toList();
      if (students.isNotEmpty) {
        selected = selected.clamp(0, students.length - 1);
      }
      final savedPhone = decoded?['phone'] as String?;
      phone = savedPhone == null || savedPhone.trim().isEmpty
          ? personalWhatsApp
          : savedPhone;
    } catch (_) {
      students = [Student.create('Aluno')];
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && entered && !loading) {
      refreshRemoteData();
    }
  }

  Future<void> refreshRemoteData({bool announce = false}) async {
    if (widget.backend == null || !entered || loading) return;
    final selectedId = students.isEmpty ? null : student.data['id'];
    setState(() => loading = true);
    try {
      final refreshed = (await widget.backend!.loadStudents(
        admin: admin,
      )).map((data) => Student(data)).toList();
      var nextSelected = selectedId == null
          ? 0
          : refreshed.indexWhere((item) => item.data['id'] == selectedId);
      if (nextSelected < 0) nextSelected = 0;
      if (!mounted) return;
      setState(() {
        students = refreshed;
        selected = nextSelected;
      });
      if (announce) notify('Dados atualizados.');
    } on BackendException catch (e) {
      if (announce) notify(e.message);
    } catch (_) {
      if (announce) notify('Não foi possível atualizar os dados.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> restoreRemote() async {
    final restored = await widget.backend!.restore();
    if (restored == null || !mounted) return;
    await enterRemote(restored);
  }

  Future<void> enterRemote(LoginResult result) async {
    setState(() => loading = true);
    try {
      account = result.profile;
      admin = result.isAdmin;
      students = (await widget.backend!.loadStudents(
        admin: admin,
      )).map((data) => Student(data)).toList();
      selected = 0;
      entered = true;
      page = 0;
      if (result.mustChangePassword && mounted) await requireNewPassword();
      if (!admin && students.isNotEmpty && mounted) {
        if (!await completeFirstAccess()) {
          await widget.backend!.logout();
          entered = false;
          return;
        }
        if (!kIsWeb) await widget.backend!.registerDeviceToken();
      }
    } on BackendException catch (e) {
      notify(e.message);
      entered = false;
    } catch (_) {
      notify('Não foi possível carregar os dados da conta.');
      entered = false;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loginRemote() async {
    if (usernameController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      notify('Preencha usuário e senha.');
      return;
    }
    setState(() => loading = true);
    try {
      final result = await widget.backend!.login(
        usernameController.text,
        passwordController.text,
      );
      passwordController.clear();
      await enterRemote(result);
    } on BackendException catch (e) {
      notify(
        e.retryAfter == null
            ? e.message
            : '${e.message} Tente novamente em ${e.retryAfter! ~/ 60 + 1} min.',
      );
    } catch (_) {
      notify('Não foi possível conectar. Confira sua internet.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> requireNewPassword() async {
    final values = await form('Crie uma nova senha', {'Nova senha': ''});
    if (values == null) {
      throw BackendException('A troca de senha é obrigatória.');
    }
    final password = values['Nova senha']!;
    if (password.length < 8) {
      throw BackendException('Use uma senha com pelo menos 8 caracteres.');
    }
    await widget.backend!.changePassword(password);
    account!['must_change_password'] = false;
  }

  Future<bool> save() async {
    setState(() {});
    if (widget.backend != null) {
      try {
        await widget.backend!.syncStudent(student.data, admin: admin);
        return true;
      } on BackendException catch (e) {
        notify(e.message);
      } catch (_) {
        notify('Não foi possível sincronizar. Confira sua internet.');
      }
      return false;
    }
    try {
      final ok = await widget.prefs.setString(
        'anderfit.v1',
        jsonEncode({
          'students': students.map((e) => e.data).toList(),
          'phone': phone,
        }),
      );
      if (!ok) notify('Não foi possível salvar neste dispositivo.');
      return ok;
    } catch (_) {
      notify('Não foi possível salvar. Verifique o espaço disponível.');
      return false;
    }
  }

  void notify(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> logoutAccess() async {
    if (widget.backend != null) await widget.backend!.logout();
    if (!mounted) return;
    setState(() {
      entered = false;
      admin = false;
      page = 0;
      students = widget.backend == null ? students : [];
      account = null;
    });
  }

  Future<Map<String, String>?> form(
    String title,
    Map<String, String> fields, {
    Set<String> numeric = const {},
  }) async {
    final controllers = fields.map(
      (k, v) => MapEntry(k, TextEditingController(text: v)),
    );
    final key = GlobalKey<FormState>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: controllers.entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TextFormField(
                          controller: e.value,
                          keyboardType: numeric.contains(e.key)
                              ? const TextInputType.numberWithOptions(
                                  decimal: true,
                                )
                              : TextInputType.text,
                          decoration: InputDecoration(labelText: e.key),
                          validator: (v) {
                            if (e.key.contains('opcional')) return null;
                            if (v == null || v.trim().isEmpty) {
                              return 'Preencha este campo';
                            }
                            if (numeric.contains(e.key)) {
                              final n = double.tryParse(v.replaceAll(',', '.'));
                              if (n == null || !n.isFinite || n <= 0) {
                                return 'Informe um número maior que zero';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(
                  context,
                  controllers.map((k, v) => MapEntry(k, v.text.trim())),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(seconds: 1), () {
      for (final c in controllers.values) {
        c.dispose();
      }
    });
    return result;
  }

  Future<bool> completeFirstAccess() async {
    if (student.data['profileComplete'] == true) return true;
    final Map<String, String> fields = widget.backend == null
        ? {
            'Nome completo': student.name == 'Aluno' ? '' : student.name,
            'Altura (cm)': student.data['height']?.toString() ?? '',
            'Peso (kg)': '',
            'Objetivo principal': student.data['objective']?.toString() ?? '',
          }
        : {
            'Altura (cm)': student.data['height']?.toString() ?? '',
            'Peso (kg)': '',
            'Objetivo principal': student.data['objective']?.toString() ?? '',
          };
    final values = await form(
      'Seu primeiro acesso',
      fields,
      numeric: {'Altura (cm)', 'Peso (kg)'},
    );
    if (values == null) return false;
    final weight = double.parse(values['Peso (kg)']!.replaceAll(',', '.'));
    student.data.addAll({
      if (values['Nome completo'] != null) 'name': values['Nome completo'],
      'height': values['Altura (cm)'],
      'objective': values['Objetivo principal'],
      'profileComplete': true,
      'goalStart': weight,
      'goalTarget': weight,
    });
    student.measures.add({
      'date': today(),
      'Peso': weight,
      'Peito': 0.0,
      'Braço': 0.0,
      'Cintura': 0.0,
      'Quadril': 0.0,
      'Coxa': 0.0,
    });
    return save();
  }

  Widget panel(Widget child, {Color? color}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color ?? const Color(0xFF17191D),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: .06)),
    ),
    child: child,
  );
  Widget title(String eyebrow, String text, {bool centered = false}) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 24),
    child: Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            color: orange,
            fontSize: 11,
            letterSpacing: 2.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          text,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    ),
  );
  Widget section(String text) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 16),
    child: Text(
      text,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
    ),
  );
  Widget button(
    String text,
    VoidCallback? action, {
    IconData icon = Icons.arrow_forward_rounded,
  }) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: action,
      icon: Icon(icon, size: 19),
      label: Text(text),
    ),
  );
  Widget stat(String number, String caption, IconData icon) => Expanded(
    child: panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: orange, size: 22),
          const SizedBox(height: 16),
          Text(
            number,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
          ),
          Text(
            caption,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    ),
  );
  Widget home() {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final week = student.history
        .where((d) => !DateTime.parse(d).isBefore(monday))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title(
          'Seu próximo nível começa aqui',
          'Vamos pra cima,\n${student.name.split(' ').first}.',
        ),
        Row(
          children: [
            stat(
              '$week',
              'treinos nesta semana',
              Icons.local_fire_department_outlined,
            ),
            const SizedBox(width: 12),
            stat(
              '${(student.waterToday / 1000).toStringAsFixed(2)} L',
              'água hoje',
              Icons.water_drop_outlined,
            ),
          ],
        ),
        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt, color: orange),
                  SizedBox(width: 6),
                  Text(
                    'SEU TREINO DE HOJE',
                    style: TextStyle(
                      color: orange,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Construa sua\nmelhor versão.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${student.exercises.length} exercícios  •  No seu ritmo',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 24),
              button(
                student.completed ? 'TREINO CONCLUÍDO' : 'COMEÇAR TREINO',
                () => setState(() => page = 1),
              ),
            ],
          ),
          color: const Color(0xFF242019),
        ),
        section('Consistência é o que transforma.'),
        const Text(
          'Um treino de cada vez. Cada repetição conta.',
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 20),
        hydration(),
      ],
    );
  }

  Widget hydration() => panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.water_drop_rounded, color: waterBlue),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Hidratação',
                style: TextStyle(
                  color: orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${student.waterToday} ml',
              style: const TextStyle(
                color: waterBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: (student.waterToday / (student.data['waterGoal'] as num))
              .clamp(0, 1),
          minHeight: 6,
          color: waterBlue,
          backgroundColor: orange.withValues(alpha: .2),
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 12),
        Text(
          'Meta diária: ${student.data['waterGoal']} ml',
          style: const TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  student.water[today()] = (student.waterToday - 250).clamp(
                    0,
                    100000,
                  );
                  save();
                },
                child: const Text('− 250 ml'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  student.water[today()] = student.waterToday + 250;
                  save();
                },
                child: const Text('+ 250 ml'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Widget workout() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      title('Foco na execução', 'Treino do dia'),
      Text(
        student.completed
            ? 'Treino registrado. Até o próximo!'
            : 'Marque cada exercício ao terminar todas as séries.',
        style: const TextStyle(color: Colors.white60),
      ),
      const SizedBox(height: 20),
      if (student.exercises.isEmpty)
        panel(const Text('Seu personal ainda não montou este treino.')),
      ...student.exercises.asMap().entries.map((entry) {
        final e = entry.value;
        final checked =
            (student.checks[today()] as List?)?.contains(e['id']) ?? false;
        return panel(
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: orange.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${entry.key + 1}'.padLeft(2, '0'),
                      style: const TextStyle(
                        color: orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e['name'],
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${e['sets']}   •   ${e['rest']}s descanso',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: checked,
                    onChanged: student.completed
                        ? null
                        : (v) {
                            final checks =
                                student.checks.putIfAbsent(
                                      today(),
                                      () => <dynamic>[],
                                    )
                                    as List;
                            v! ? checks.add(e['id']) : checks.remove(e['id']);
                            save();
                          },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if ((e['media'] as String).isEmpty) {
                        notify('O personal ainda não adicionou o vídeo.');
                      } else {
                        openLink(e['media']);
                      }
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: const Text('Ver execução'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Cronometrar descanso',
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          RestDialog(seconds: int.tryParse(e['rest']) ?? 60),
                    ),
                    icon: const Icon(Icons.timer_outlined, size: 21),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
      button(
        student.completed ? 'TREINO CONCLUÍDO ✓' : 'CONCLUIR TREINO',
        student.ready && !student.completed
            ? () {
                student.complete();
                save();
                notify('Boa! Mais um treino na sua história.');
              }
            : null,
        icon: Icons.check_circle_outline,
      ),
      const SizedBox(height: 24),
      section('Histórico de treinos'),
      Text(
        '${student.history.where((e) => e.toString().startsWith(today().substring(0, 7))).length} treinos concluídos neste mês',
        style: const TextStyle(color: Colors.white60),
      ),
      const SizedBox(height: 16),
      panel(
        Wrap(
          spacing: 7,
          runSpacing: 8,
          children: List.generate(
            DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month),
            (i) {
              final key =
                  '${today().substring(0, 7)}-${(i + 1).toString().padLeft(2, '0')}';
              return Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: student.history.contains(key)
                      ? orange
                      : Colors.white.withValues(alpha: .04),
                  borderRadius: BorderRadius.circular(8),
                  border: key == today() ? Border.all(color: orange) : null,
                ),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: student.history.contains(key)
                        ? Colors.black
                        : Colors.white60,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      ...student.history.reversed.map(
        (d) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '$d • Treino concluído',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      ),
    ],
  );
  Future<void> openLink(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      notify('Informe um link HTTPS válido.');
      return;
    }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        notify('Não foi possível abrir o link.');
      }
    } catch (_) {
      notify('Não foi possível abrir o link.');
    }
  }

  Future<void> addMeasures() async {
    final fields = {
      for (final key in [
        'Peso',
        'Peito',
        'Braço',
        'Cintura',
        'Quadril',
        'Coxa',
      ])
        key: student.measures.isEmpty ? '' : '${student.measures.last[key]}',
    };
    final values = await form(
      'Medidas de hoje (kg / cm)',
      fields,
      numeric: fields.keys.toSet(),
    );
    if (values == null) return;
    student.measures.removeWhere((e) => e['date'] == today());
    student.measures.add({
      'date': today(),
      ...values.map(
        (k, v) => MapEntry(k, double.parse(v.replaceAll(',', '.'))),
      ),
    });
    save();
  }

  Widget evolution() {
    final values = student.measures
        .map((e) => (e[metric] as num).toDouble())
        .toList();
    final current = student.measures.isEmpty
        ? (student.data['goalStart'] as num).toDouble()
        : (student.measures.last['Peso'] as num).toDouble();
    final start = (student.data['goalStart'] as num).toDouble(),
        target = (student.data['goalTarget'] as num).toDouble();
    final progress = start == target
        ? (current == target ? 1.0 : 0.0)
        : ((current - start) / (target - start)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title('Cada passo aparece', 'Sua evolução'),
        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<String>(
                value: metric,
                isExpanded: true,
                items: ['Peso', 'Peito', 'Braço', 'Cintura', 'Quadril', 'Coxa']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => metric = v!),
              ),
              Text(
                values.isEmpty
                    ? 'Sem registros'
                    : '${values.last} ${metric == 'Peso' ? 'kg' : 'cm'}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 110,
                width: double.infinity,
                child: CustomPaint(painter: TrendPainter(values)),
              ),
              const SizedBox(height: 14),
              if (student.measures.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      student.measures.first['date'],
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      student.measures.last['date'],
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        button('REGISTRAR MEDIDAS', addMeasures, icon: Icons.add),
        const SizedBox(height: 24),
        section('Sua meta'),
        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.data['goalTitle'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 12),
              Text(
                '${(progress * 100).round()}%  •  De $start kg para $target kg',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
        section('Fotos de evolução'),
        panel(
          const Row(
            children: [
              Icon(Icons.lock_clock_outlined, color: orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Em breve',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              Text('Indisponível', style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
        section('Registros'),
        ...student.measures.reversed.map(
          (e) => panel(
            Text(
              '${e['date']}\nPeso ${e['Peso']} kg  •  Cintura ${e['Cintura']} cm\nPeito ${e['Peito']}  •  Braço ${e['Braço']}\nQuadril ${e['Quadril']}  •  Coxa ${e['Coxa']} cm',
              style: const TextStyle(height: 1.7, color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }

  Widget profile() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      title('Seu compromisso com você', 'Meu perfil'),
      panel(
        Column(
          children: [
            const CircleAvatar(
              radius: 38,
              backgroundColor: orange,
              child: Icon(Icons.person_outline, color: Colors.black, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              student.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${student.data['height']} cm  •  ${student.measures.isEmpty ? 'Peso não informado' : '${student.measures.last['Peso']} kg'}',
            ),
            const SizedBox(height: 12),
            Text(
              student.data['objective'],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () async {
                final Map<String, String> profileFields = widget.backend == null
                    ? {
                        'Nome': student.name,
                        'Altura (cm)': student.data['height'].toString(),
                        'Peso (kg)': student.measures.isEmpty
                            ? ''
                            : student.measures.last['Peso'].toString(),
                        'Objetivo': student.data['objective'].toString(),
                      }
                    : {
                        'Altura (cm)': student.data['height'].toString(),
                        'Peso (kg)': student.measures.isEmpty
                            ? ''
                            : student.measures.last['Peso'].toString(),
                        'Objetivo': student.data['objective'].toString(),
                      };
                final v = await form(
                  'Editar perfil',
                  profileFields,
                  numeric: {'Altura (cm)', 'Peso (kg)'},
                );
                if (v != null) {
                  final weight = double.parse(
                    v['Peso (kg)']!.replaceAll(',', '.'),
                  );
                  student.data.addAll({
                    if (v['Nome'] != null) 'name': v['Nome'],
                    'height': v['Altura (cm)'],
                    'objective': v['Objetivo'],
                    'profileComplete': true,
                  });
                  if (student.measures.isEmpty) {
                    student.measures.add({
                      'date': today(),
                      'Peso': weight,
                      'Peito': 0.0,
                      'Braço': 0.0,
                      'Cintura': 0.0,
                      'Quadril': 0.0,
                      'Coxa': 0.0,
                    });
                  } else {
                    student.measures.last['Peso'] = weight;
                  }
                  save();
                }
              },
              child: const Text('Editar perfil'),
            ),
          ],
        ),
      ),
      hydration(),
      panel(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ANDERFIT', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Força. Foco. Evolução.',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
      OutlinedButton(
        onPressed: logoutAccess,
        child: const Text('Sair da conta'),
      ),
    ],
  );
  Future<void> editExercise([Map<String, dynamic>? exercise]) async {
    final v = await form(
      exercise == null ? 'Novo exercício' : 'Editar exercício',
      {
        'Nome': exercise?['name'] ?? '',
        'Séries × repetições': exercise?['sets'] ?? '3 × 12',
        'Descanso (segundos)': exercise?['rest'] ?? '60',
        'Vídeo HTTPS (opcional)': exercise?['media'] ?? '',
      },
      numeric: {'Descanso (segundos)'},
    );
    if (v == null) return;
    final link = v['Vídeo HTTPS (opcional)']!;
    if (link.isNotEmpty && !(Uri.tryParse(link)?.isScheme('https') ?? false)) {
      notify('Use um endereço HTTPS para o vídeo.');
      return;
    }
    final data = {
      'id': exercise?['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
      'name': v['Nome'],
      'sets': v['Séries × repetições'],
      'rest': double.parse(
        v['Descanso (segundos)']!.replaceAll(',', '.'),
      ).round().toString(),
      'media': link,
    };
    if (exercise == null) {
      student.exercises.add(data);
    } else {
      exercise.addAll(data);
    }
    save();
  }

  Future<void> addStudent() async {
    final v = await form(
      'Cadastrar aluno',
      widget.backend == null ? {'Nome': ''} : {'Nome': '', 'Usuário': ''},
    );
    if (v == null) return;
    if (widget.backend != null) {
      try {
        final credentials = await widget.backend!.createStudent(
          v['Nome']!,
          v['Usuário']!,
        );
        students = (await widget.backend!.loadStudents(
          admin: true,
        )).map((data) => Student(data)).toList();
        selected = students.indexWhere(
          (item) => item.data['id'] == credentials['id'],
        );
        if (selected < 0) selected = 0;
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Aluno criado'),
            content: SelectableText(
              'Passe estes dados ao aluno:\n\nUsuário: ${credentials['username']}\nSenha temporária: ${credentials['password']}\n\nA senha deverá ser trocada no primeiro acesso.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Concluir'),
              ),
            ],
          ),
        );
        setState(() {});
      } on BackendException catch (e) {
        notify(e.message);
      }
      return;
    }
    students.add(Student.create(v['Nome']!));
    selected = students.length - 1;
    await save();
  }

  Future<void> deleteStudent() async {
    final current = student;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir aluno?'),
        content: Text(
          'Tem certeza de que deseja excluir o perfil de ${current.name}? Todos os dados locais desse aluno serão apagados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir perfil'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    if (widget.backend != null) {
      try {
        await widget.backend!.deleteStudent(current.data['id']);
      } on BackendException catch (e) {
        notify(e.message);
        return;
      }
    }
    students.remove(current);
    selected = students.isEmpty ? 0 : selected.clamp(0, students.length - 1);
    page = 0;
    await save();
    notify('Perfil excluído.');
  }

  Widget dashboard() {
    if (students.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title('Gestão de alunos', 'Painel do personal'),
          panel(
            const Text(
              'Nenhum aluno cadastrado. Crie o primeiro perfil para começar.',
              style: TextStyle(color: Colors.white60, height: 1.5),
            ),
          ),
          button(
            'CADASTRAR ALUNO',
            addStudent,
            icon: Icons.person_add_outlined,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title('Gestão de alunos', 'Painel do personal'),
        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ALUNO SELECIONADO',
                style: TextStyle(color: orange, fontSize: 11, letterSpacing: 2),
              ),
              DropdownButton<int>(
                value: selected,
                isExpanded: true,
                items: students
                    .asMap()
                    .entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selected = v!),
              ),
              Text(
                '${student.history.length} treinos concluídos  •  ${student.waterToday} ml hoje',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 4),
              Text(
                student.measures.isEmpty
                    ? 'Nenhuma medida registrada'
                    : '${student.measures.length} registros de medidas  •  Último peso: ${student.measures.last['Peso']} kg',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: loading
                    ? null
                    : () => refreshRemoteData(announce: true),
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Atualizar dados dos alunos'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: addStudent,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Novo aluno'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: deleteStudent,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir aluno'),
              ),
              if (widget.backend != null)
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final credentials = await widget.backend!.resetPassword(
                        student.data['id'],
                      );
                      if (!mounted) return;
                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          title: const Text('Nova senha temporária'),
                          content: SelectableText(
                            'Usuário: ${credentials['username']}\nSenha: ${credentials['password']}',
                          ),
                          actions: [
                            FilledButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Concluir'),
                            ),
                          ],
                        ),
                      );
                    } on BackendException catch (e) {
                      notify(e.message);
                    }
                  },
                  icon: const Icon(Icons.key_outlined),
                  label: const Text('Gerar nova senha'),
                ),
            ],
          ),
        ),
        section('Prescrição de treino'),
        ...student.exercises.map(
          (e) => panel(
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${e['name']}\n${e['sets']} • ${e['rest']}s',
                    style: const TextStyle(height: 1.7),
                  ),
                ),
                IconButton(
                  tooltip: 'Editar exercício',
                  onPressed: () => editExercise(e),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Excluir exercício',
                  onPressed: () async {
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Excluir exercício?'),
                        content: Text(e['name']),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );
                    if (yes == true) {
                      student.exercises.remove(e);
                      save();
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
        button('ADICIONAR EXERCÍCIO', () => editExercise(), icon: Icons.add),
        const SizedBox(height: 16),
        button('DEFINIR META', () async {
          final v = await form(
            'Meta do aluno',
            {
              'Descrição': student.data['goalTitle'],
              'Peso inicial': student.data['goalStart'].toString(),
              'Peso alvo': student.data['goalTarget'].toString(),
              'Água diária (ml)': student.data['waterGoal'].toString(),
            },
            numeric: {'Peso inicial', 'Peso alvo', 'Água diária (ml)'},
          );
          if (v != null) {
            student.data.addAll({
              'goalTitle': v['Descrição'],
              'goalStart': double.parse(
                v['Peso inicial']!.replaceAll(',', '.'),
              ),
              'goalTarget': double.parse(v['Peso alvo']!.replaceAll(',', '.')),
              'waterGoal': double.parse(
                v['Água diária (ml)']!.replaceAll(',', '.'),
              ),
            });
            save();
          }
        }, icon: Icons.flag_outlined),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            final v = await form('WhatsApp do personal', {
              'Número com país e DDD': phone,
            });
            if (v != null) {
              final digits = v.values.first.replaceAll(RegExp(r'\D'), '');
              if (digits.length < 10 || digits.length > 15) {
                notify('Confira o número com país e DDD.');
                return;
              }
              phone = digits;
              save();
            }
          },
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Configurar WhatsApp'),
        ),
        section('Notificações'),
        widget.backend == null
            ? panel(
                const Text(
                  'As notificações ficam disponíveis com as contas conectadas.',
                  style: TextStyle(color: Colors.white60),
                ),
              )
            : button('ENVIAR NOTIFICAÇÃO PARA ESTE ALUNO', () async {
                final values = await form('Enviar notificação', {
                  'Título': 'ANDERFIT',
                  'Mensagem': '',
                });
                if (values == null) return;
                try {
                  final devices = await widget.backend!.sendNotification(
                    [student.data['id']],
                    values['Título']!,
                    values['Mensagem']!,
                  );
                  notify(
                    devices == 0
                        ? 'Mensagem registrada. O aluno ainda não autorizou notificações neste aparelho.'
                        : 'Notificação enviada.',
                  );
                } on BackendException catch (e) {
                  notify(e.message);
                }
              }, icon: Icons.notifications_active_outlined),
      ],
    );
  }

  Widget accessPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Center(child: BrandMark(size: 156)),
      title('ANDERFIT', 'Seu resultado.\nNosso compromisso.', centered: true),
      const Text(
        'Treino, evolução e acompanhamento em um só lugar.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white60, fontSize: 16, height: 1.6),
      ),
      const SizedBox(height: 32),
      if (widget.backend != null) ...[
        TextField(
          controller: usernameController,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'Usuário',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          onSubmitted: (_) => loading ? null : loginRemote(),
          decoration: InputDecoration(
            labelText: 'Senha',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
              onPressed: () =>
                  setState(() => obscurePassword = !obscurePassword),
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        button(
          loading ? 'ENTRANDO...' : 'ENTRAR',
          loading ? null : loginRemote,
        ),
        const SizedBox(height: 16),
        const Text(
          'Se você perdeu o acesso, solicite uma nova senha ao personal.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
        ),
      ] else ...[
        DropdownButtonFormField<int>(
          initialValue: students.isEmpty ? null : selected,
          decoration: const InputDecoration(labelText: 'Aluno'),
          items: students
              .asMap()
              .entries
              .map(
                (e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value.name)),
              )
              .toList(),
          onChanged: (v) => setState(() => selected = v!),
        ),
        const SizedBox(height: 20),
        button(
          'ENTRAR COMO ALUNO',
          students.isEmpty
              ? null
              : () async {
                  if (!await completeFirstAccess() || !mounted) return;
                  setState(() {
                    entered = true;
                    admin = false;
                    page = 0;
                  });
                },
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() {
            entered = true;
            admin = true;
            page = 0;
          }),
          child: const Text('ÁREA DO PERSONAL'),
        ),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final wide = entered && MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            BrandMark(size: 44),
            SizedBox(width: 8),
            Text(
              'ANDERFIT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                fontSize: 19,
              ),
            ),
          ],
        ),
        actions: [
          if (entered)
            IconButton(
              tooltip: 'Trocar acesso',
              onPressed: logoutAccess,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              extended: true,
              selectedIndex: page,
              onDestinationSelected: (v) => setState(() => page = v),
              backgroundColor: const Color(0xFF111316),
              indicatorColor: orange.withValues(alpha: .16),
              destinations: [
                NavigationRailDestination(
                  icon: Icon(
                    admin ? Icons.dashboard_outlined : Icons.home_outlined,
                  ),
                  label: Text(admin ? 'Painel' : 'Início'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.fitness_center),
                  label: Text('Treino'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  label: Text('Aulas'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.insights),
                  label: Text('Evolução'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  label: Text('Perfil'),
                ),
              ],
              trailing: admin
                  ? null
                  : TextButton.icon(
                      onPressed: () => openLink('https://wa.me/$phone'),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Falar com o Personal'),
                    ),
            ),
          Expanded(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: RefreshIndicator(
                    color: orange,
                    onRefresh: refreshRemoteData,
                    child: ListView(
                      key: ValueKey('$entered-$admin-$page-$selected'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                      children: [
                        if (!entered)
                          accessPage()
                        else
                          (admin && students.isEmpty
                              ? dashboard()
                              : page == 0
                              ? (admin ? dashboard() : home())
                              : page == 1
                              ? workout()
                              : page == 2
                              ? TrainingLibraryPage(isAdmin: admin)
                              : page == 3
                              ? evolution()
                              : profile()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !entered || wide
          ? null
          : SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!admin)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 4),
                      child: TextButton.icon(
                        onPressed: () {
                          if (phone.isEmpty) {
                            notify(
                              'O personal precisa configurar o número no painel.',
                            );
                          } else {
                            openLink('https://wa.me/$phone');
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Falar com o Personal'),
                      ),
                    ),
                  NavigationBar(
                    selectedIndex: page,
                    onDestinationSelected: (v) => setState(() => page = v),
                    backgroundColor: const Color(0xFF111316),
                    indicatorColor: orange.withValues(alpha: .16),
                    destinations: [
                      NavigationDestination(
                        icon: Icon(
                          admin
                              ? Icons.dashboard_outlined
                              : Icons.home_outlined,
                        ),
                        label: admin ? 'Painel' : 'Início',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.fitness_center),
                        label: 'Treino',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.menu_book_outlined),
                        label: 'Aulas',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.insights),
                        label: 'Evolução',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        label: 'Perfil',
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class RestDialog extends StatefulWidget {
  const RestDialog({super.key, required this.seconds});
  final int seconds;
  @override
  State<RestDialog> createState() => _RestDialogState();
}

class _RestDialogState extends State<RestDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController timer = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.seconds),
  )..forward();
  @override
  void dispose() {
    timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: timer,
    builder: (context, child) => AlertDialog(
      title: Text(
        timer.isCompleted ? 'Vamos para a próxima série' : 'Respire. Recupere.',
      ),
      content: Text(
        '${(widget.seconds * (1 - timer.value)).ceil()}s',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 56,
          color: orange,
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
}

class TrendPainter extends CustomPainter {
  TrendPainter(this.values);
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final y = i * size.height / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;
    final min = values.reduce((a, b) => a < b ? a : b) - 1,
        max = values.reduce((a, b) => a > b ? a : b) + 1;
    final points = List.generate(
      values.length,
      (i) => Offset(
        values.length == 1
            ? size.width / 2
            : i * size.width / (values.length - 1),
        size.height - (values[i] - min) / (max - min) * size.height,
      ),
    );
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = orange
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = orange);
    }
  }

  @override
  bool shouldRepaint(covariant TrendPainter oldDelegate) => true;
}
