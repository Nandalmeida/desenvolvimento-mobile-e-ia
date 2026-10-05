import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tarefa_ia/main.dart';

void main() {
  setUp(() {
    // Começa cada teste com o armazenamento local vazio.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Mostra o estado vazio ao abrir o app', (WidgetTester tester) async {
    await tester.pumpWidget(const TarefaIaApp());
    await tester.pumpAndSettle();

    expect(find.text('Minhas tarefas'), findsOneWidget);
    expect(find.text('Nenhuma tarefa ainda'), findsOneWidget);
  });

  testWidgets('Adiciona uma tarefa pelo botão +', (WidgetTester tester) async {
    await tester.pumpWidget(const TarefaIaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Estudar Flutter');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Estudar Flutter'), findsOneWidget);
    expect(find.text('Nenhuma tarefa ainda'), findsNothing);
  });
}
