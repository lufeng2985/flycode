import 'package:flycode/service/api/models/command.dart';
import 'package:flycode/theme/app_theme.dart';
import 'package:flycode/widgets/message/chat_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness({required Brightness brightness, required Widget child}) {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    );
  }

  const initCommand = Command(
    name: 'init',
    description: 'create or update AGENTS.md',
    template: 'template',
    hints: <String>[],
  );

  const reviewCommand = Command(
    name: 'review',
    description: 'review changes in commit, branch, or PR',
    template: 'template',
    hints: <String>[],
  );

  testWidgets('renders command title and description in vertical hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.light,
        child: buildCommandSuggestionListForTest(
          commands: const [initCommand, reviewCommand],
          onSelect: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('/init'), findsOneWidget);
    expect(find.text('create or update AGENTS.md'), findsOneWidget);

    final title = tester.widget<Text>(find.text('/init'));
    final description = tester.widget<Text>(
      find.text('create or update AGENTS.md'),
    );

    expect(title.style?.fontFamily, 'PlusJakartaSans');
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(description.style?.fontFamily, 'Inter');
    expect(description.style?.fontSize, 11);

    final titleTop = tester.getTopLeft(find.text('/init')).dy;
    final descriptionTop = tester
        .getTopLeft(find.text('create or update AGENTS.md'))
        .dy;
    expect(descriptionTop, greaterThan(titleTop));
  });

  testWidgets('keeps layout stable when description is missing', (
    tester,
  ) async {
    const noDescriptionCommand = Command(
      name: 'plain',
      template: 'template',
      hints: <String>[],
    );

    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.light,
        child: buildCommandSuggestionListForTest(
          commands: const [noDescriptionCommand],
          onSelect: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('/plain'), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);
    expect(find.text('create or update AGENTS.md'), findsNothing);
  });

  testWidgets('selects command on tap', (tester) async {
    Command? selected;

    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.dark,
        child: buildCommandSuggestionListForTest(
          commands: const [initCommand, reviewCommand],
          onSelect: (command) => selected = command,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('/review'));
    await tester.pump();

    expect(selected?.name, 'review');
  });
}
