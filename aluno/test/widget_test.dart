import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peci_project/main.dart';

void main() {
  testWidgets('App renders with bottom navigation (3 tabs)', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PECIApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
  });

  testWidgets('Initial tab is Cursos with course list', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PECIApp()));
    await tester.pumpAndSettle();

    // Tab inicial é Cursos — verifica que a AppBar e os cursos estão presentes
    expect(find.text('Cursos'), findsWidgets);
    expect(find.text('Sistemas Digitais'), findsOneWidget);
    expect(find.text('Arquitetura de Computadores'), findsOneWidget);
    expect(find.text('Sistemas Embutidos'), findsOneWidget);
  });

  testWidgets('Navigate to Prática tab shows filter bar', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PECIApp()));
    await tester.pumpAndSettle();

    // Navegar para Prática
    await tester.tap(find.byIcon(Icons.bolt_outlined));
    await tester.pumpAndSettle();

    // Verifica que a barra de filtros e o título estão presentes
    expect(find.text('Prática'), findsWidgets);
    expect(find.text('Todos'), findsOneWidget);
  });

  testWidgets('Navigate to Perfil tab shows profile info', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PECIApp()));
    await tester.pumpAndSettle();

    // Navegar para Perfil
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    // Verifica dados do perfil mock
    expect(find.text('Tiago Martins'), findsOneWidget);
    expect(find.text('Cursos Inscritos'), findsOneWidget);
  });
}
