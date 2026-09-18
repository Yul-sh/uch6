import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_y/models/app_user.dart';
import 'package:fly_y/models/role.dart';
import 'package:fly_y/repositories/auth_api.dart';
import 'package:fly_y/state/auth_notifier.dart';
import 'package:fly_y/validation/validators.dart';
import 'package:fly_y/widgets/can.dart';
import 'package:fly_y/widgets/list_status_views.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Состояние загрузки показывает индикатор', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LoadingView())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Пустой результат показывает сообщение', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EmptyResultView())),
    );
    expect(find.textContaining('ничего не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Ошибка показывает текст и кнопку повтора', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorResultView(
            message: 'Сервер недоступен',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    expect(find.textContaining('Сервер недоступен'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('Валидация пароля срабатывает при вводе', (tester) async {
    final key = GlobalKey<FormState>();
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: key,
            child: TextFormField(
              controller: controller,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: Validators.passwordLive,
              decoration: const InputDecoration(labelText: 'Пароль'),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '123');
    await tester.pump();
    expect(key.currentState!.validate(), isFalse);
    await tester.enterText(find.byType(TextFormField), 'Pass123!');
    await tester.pump();
    expect(key.currentState!.validate(), isTrue);
  });

  testWidgets('Недоступный элемент скрыт при роли клиента', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthNotifier(prefs, AuthApi(Dio()));
    auth.debugSetSession(
      const AppUser(
        id: 'abc123xyz45678',
        username: 'client',
        displayName: 'Анна',
        role: Role.client,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          home: Scaffold(
            body: Can(
              op: AppOp.manageUsers,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Пользователи'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Пользователи'), findsNothing);

    auth.debugSetSession(
      const AppUser(
        id: 'admin00xyz45678',
        username: 'admin',
        displayName: 'Елена',
        role: Role.admin,
      ),
    );
    await tester.pump();
    expect(find.text('Пользователи'), findsOneWidget);
  });
}
