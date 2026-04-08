import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../l10n/app_language.dart' as app_language;
import 'local_preferences_repository.dart';

part 'app_language_provider.g.dart';

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
    final repository = ref.read(localPreferencesRepositoryProvider);
    await repository.saveAppLanguage(language);
  }

  Future<void> _restore() async {
    final repository = ref.read(localPreferencesRepositoryProvider);
    final value = await repository.loadAppLanguage();
    if (!ref.mounted) return;
    state = value;
  }
}
