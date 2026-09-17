import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://iwfseipaztmxwmecbboc.supabase.co';
const supabasePublishableKey = 'sb_publishable_EdmVtQginRl0OmW3R3Z5bQ_VsieVm82';

Future<BackendService> initializeBackend() async {
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  return BackendService(Supabase.instance.client);
}

class BackendException implements Exception {
  BackendException(this.message, {this.retryAfter});
  final String message;
  final int? retryAfter;
  @override
  String toString() => message;
}

class LoginResult {
  LoginResult(this.profile);
  final Map<String, dynamic> profile;
  bool get isAdmin => profile['role'] == 'admin';
  bool get mustChangePassword => profile['must_change_password'] == true;
}

class BackendService {
  BackendService(this.client);
  final SupabaseClient client;

  Session? get session => client.auth.currentSession;

  Future<LoginResult> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/login'),
      headers: {
        'apikey': supabasePublishableKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'username': username, 'password': password}),
    );
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendException(
        payload['error'] ?? 'Não foi possível entrar.',
        retryAfter: (payload['retryAfter'] as num?)?.toInt(),
      );
    }
    await client.auth.setSession(payload['session']['refresh_token']);
    return LoginResult(Map<String, dynamic>.from(payload['user']));
  }

  Future<LoginResult?> restore() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final profile = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return profile == null
        ? null
        : LoginResult(Map<String, dynamic>.from(profile));
  }

  Future<void> logout() => client.auth.signOut();

  Future<void> changePassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
    await client.rpc('complete_password_change');
  }

  Future<List<Map<String, dynamic>>> loadStudents({required bool admin}) async {
    final userId = client.auth.currentUser!.id;
    final profiles = admin
        ? await client
              .from('profiles')
              .select()
              .eq('role', 'student')
              .order('display_name')
        : await client.from('profiles').select().eq('id', userId);
    final result = <Map<String, dynamic>>[];
    for (final raw in profiles as List) {
      final profile = Map<String, dynamic>.from(raw);
      result.add(await _loadStudent(profile));
    }
    return result;
  }

  Future<Map<String, dynamic>> _loadStudent(
    Map<String, dynamic> profile,
  ) async {
    final id = profile['id'] as String;
    final details = await client
        .from('student_profiles')
        .select()
        .eq('user_id', id)
        .maybeSingle();
    final workouts = await client
        .from('workouts')
        .select()
        .eq('student_id', id)
        .eq('active', true)
        .limit(1);
    final workout = (workouts as List).isEmpty
        ? null
        : Map<String, dynamic>.from(workouts.first);
    final exercises = workout == null
        ? <dynamic>[]
        : await client
              .from('exercises')
              .select()
              .eq('workout_id', workout['id'])
              .order('sort_order');
    final completions = await client
        .from('workout_completions')
        .select('completed_on')
        .eq('student_id', id)
        .order('completed_on');
    final measurements = await client
        .from('measurements')
        .select()
        .eq('student_id', id)
        .order('measured_on');
    final hydration = await client
        .from('hydration')
        .select()
        .eq('student_id', id);
    final checks = await client
        .from('exercise_checks')
        .select('exercise_id,checked_on')
        .eq('student_id', id);
    final water = <String, dynamic>{};
    for (final item in hydration as List) {
      water[item['consumed_on']] = item['amount_ml'];
    }
    final checked = <String, dynamic>{};
    for (final item in checks as List) {
      (checked[item['checked_on']] ??= <dynamic>[]).add(item['exercise_id']);
    }
    return {
      'id': id,
      'username': profile['username'],
      'name': profile['display_name'],
      'profileComplete':
          details?['height_cm'] != null && measurements.isNotEmpty,
      'height': details?['height_cm']?.toString() ?? '',
      'objective': details?['objective'] ?? '',
      'goalTitle': details?['goal_title'] ?? 'Defina sua meta com o personal',
      'goalStart': (details?['goal_start'] as num?)?.toDouble() ?? 0.0,
      'goalTarget': (details?['goal_target'] as num?)?.toDouble() ?? 0.0,
      'waterGoal': details?['water_goal_ml'] ?? 2500,
      'workoutId': workout?['id'],
      'exercises': exercises
          .map(
            (e) => {
              'id': e['id'],
              'name': e['name'],
              'sets': e['sets_reps'],
              'rest': e['rest_seconds'].toString(),
              'media': e['video_url'],
            },
          )
          .toList(),
      'history': (completions as List).map((e) => e['completed_on']).toList(),
      'measures': (measurements as List)
          .map(
            (e) => {
              'date': e['measured_on'],
              'Peso': (e['weight'] as num).toDouble(),
              'Peito': (e['chest'] as num).toDouble(),
              'Braço': (e['arm'] as num).toDouble(),
              'Cintura': (e['waist'] as num).toDouble(),
              'Quadril': (e['hip'] as num).toDouble(),
              'Coxa': (e['thigh'] as num).toDouble(),
            },
          )
          .toList(),
      'water': water,
      'checks': checked,
      'photos': <String, dynamic>{},
    };
  }

  Future<Map<String, dynamic>> createStudent(String name, String username) =>
      _admin({
        'action': 'create_student',
        'displayName': name,
        'username': username,
      });

  Future<Map<String, dynamic>> resetPassword(String id) =>
      _admin({'action': 'reset_password', 'studentId': id});

  Future<void> deleteStudent(String id) async {
    await _admin({'action': 'delete_student', 'studentId': id});
  }

  Future<Map<String, dynamic>> _admin(Map<String, dynamic> body) async {
    final response = await client.functions.invoke('admin-api', body: body);
    final data = Map<String, dynamic>.from(response.data as Map);
    if (response.status < 200 ||
        response.status >= 300 ||
        data['error'] != null) {
      throw BackendException(data['error'] ?? 'Operação não concluída.');
    }
    return data;
  }

  Future<void> syncStudent(
    Map<String, dynamic> data, {
    required bool admin,
  }) async {
    final id = data['id'] as String;
    await client.from('student_profiles').upsert({
      'user_id': id,
      'height_cm': data['height'].toString().isEmpty
          ? null
          : double.parse(data['height'].toString().replaceAll(',', '.')),
      'objective': data['objective'],
      'water_goal_ml': (data['waterGoal'] as num).round(),
      'goal_title': data['goalTitle'],
      'goal_start': data['goalStart'],
      'goal_target': data['goalTarget'],
      'updated_at': DateTime.now().toIso8601String(),
    });
    for (final item in data['measures'] as List) {
      await client.from('measurements').upsert({
        'student_id': id,
        'measured_on': item['date'],
        'weight': item['Peso'],
        'chest': item['Peito'],
        'arm': item['Braço'],
        'waist': item['Cintura'],
        'hip': item['Quadril'],
        'thigh': item['Coxa'],
      }, onConflict: 'student_id,measured_on');
    }
    for (final entry in (data['water'] as Map).entries) {
      await client.from('hydration').upsert({
        'student_id': id,
        'consumed_on': entry.key,
        'amount_ml': entry.value,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    for (final date in data['history'] as List) {
      await client.from('workout_completions').upsert({
        'student_id': id,
        'workout_id': data['workoutId'],
        'completed_on': date,
      }, onConflict: 'student_id,completed_on');
    }
    if (!admin) {
      final todayChecks =
          ((data['checks'] as Map)[DateTime.now().toIso8601String().substring(
                0,
                10,
              )]
              as List?) ??
          [];
      await client
          .from('exercise_checks')
          .delete()
          .eq('student_id', id)
          .eq('checked_on', DateTime.now().toIso8601String().substring(0, 10));
      if (todayChecks.isNotEmpty) {
        await client
            .from('exercise_checks')
            .insert(
              todayChecks
                  .map(
                    (exerciseId) => {
                      'student_id': id,
                      'exercise_id': exerciseId,
                      'checked_on': DateTime.now().toIso8601String().substring(
                        0,
                        10,
                      ),
                    },
                  )
                  .toList(),
            );
      }
    }
    if (admin) await _syncWorkout(data);
  }

  Future<void> _syncWorkout(Map<String, dynamic> data) async {
    var workoutId = data['workoutId'];
    if (workoutId == null) {
      final created = await client
          .from('workouts')
          .insert({'student_id': data['id'], 'title': 'Treino do dia'})
          .select()
          .single();
      workoutId = created['id'];
      data['workoutId'] = workoutId;
    }
    await client.from('exercises').delete().eq('workout_id', workoutId);
    final exercises = data['exercises'] as List;
    if (exercises.isNotEmpty) {
      final inserted = await client
          .from('exercises')
          .insert(
            exercises
                .asMap()
                .entries
                .map(
                  (entry) => {
                    'workout_id': workoutId,
                    'name': entry.value['name'],
                    'sets_reps': entry.value['sets'],
                    'rest_seconds': int.parse(entry.value['rest']),
                    'video_url': entry.value['media'],
                    'sort_order': entry.key,
                  },
                )
                .toList(),
          )
          .select();
      data['exercises'] = (inserted as List)
          .map(
            (e) => {
              'id': e['id'],
              'name': e['name'],
              'sets': e['sets_reps'],
              'rest': e['rest_seconds'].toString(),
              'media': e['video_url'],
            },
          )
          .toList();
    }
  }

  Future<int> sendNotification(
    List<String> recipients,
    String title,
    String body,
  ) async {
    final response = await client.functions.invoke(
      'send-notification',
      body: {'recipientIds': recipients, 'title': title, 'body': body},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['error'] != null) throw BackendException(data['error']);
    return (data['devices'] as num?)?.toInt() ?? 0;
  }
}
