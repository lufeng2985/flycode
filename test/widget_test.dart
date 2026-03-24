import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/app.dart';

void main() {
  testWidgets('App boots with ProviderScope', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('连接服务器'), findsOneWidget);
  });
}
