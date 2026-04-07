import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/theme/app_theme_mode.dart';
import 'package:flycode/theme/theme_mode_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    debugThemeModePreferencesLoader = SharedPreferences.getInstance;
  });

  tearDown(() {
    debugThemeModePreferencesLoader = SharedPreferences.getInstance;
  });

  test('late restore does not override a newer user theme selection', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_theme_mode_v1': 'dark',
    });

    final restoreGate = Completer<SharedPreferences>();
    debugThemeModePreferencesLoader = () => restoreGate.future;

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), AppThemeMode.system);

    await container
        .read(themeModeProvider.notifier)
        .setMode(AppThemeMode.light);
    expect(container.read(themeModeProvider), AppThemeMode.light);

    restoreGate.complete(await SharedPreferences.getInstance());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(themeModeProvider), AppThemeMode.light);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_theme_mode_v1'), 'light');
  });
}
