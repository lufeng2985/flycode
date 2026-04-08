import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../l10n/app_language.dart' as app_language;
import 'shared_preferences_provider.dart';

part 'app_language_provider.g.dart';

const _kAppLanguageKey = 'app_language_v1';

@Riverpod(keepAlive: true, name: 'appLanguageProvider')
class AppLanguageNotifier extends _$AppLanguageNotifier {
  @override
  app_language.AppLanguage build() {
    unawaited(_restore());
    return app_language.AppLanguage.system;
  }

  Future<void> setLanguage(app_language.AppLanguage language) async {
    if (state == language) return;
    state = language;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_kAppLanguageKey, language.storageValue);
  }

  Future<void> _restore() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final value = prefs.getString(_kAppLanguageKey);
    if (!ref.mounted) return;
    state = app_language.AppLanguageX.fromStorageValue(value);
  }
}
