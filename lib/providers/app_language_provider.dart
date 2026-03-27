import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';

const _kAppLanguageKey = 'app_language_v1';

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, AppLanguage>(
  AppLanguageNotifier.new,
);

class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    unawaited(_restore());
    return AppLanguage.system;
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppLanguageKey, language.storageValue);
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kAppLanguageKey);
    if (!ref.mounted) return;
    state = AppLanguageX.fromStorageValue(value);
  }
}
