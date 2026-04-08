import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/shared_preferences_provider.dart';
import 'app_theme_mode.dart';

part 'theme_mode_provider.g.dart';

const _kThemeModeKey = 'app_theme_mode_v1';

@Riverpod(keepAlive: true)
class ThemeMode extends _$ThemeMode {
  bool _isRestoring = false;
  int _restoreGeneration = 0;
  AppThemeMode? _pendingMode;

  @override
  AppThemeMode build() {
    _startRestore();
    return AppThemeMode.system;
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (state == mode && _pendingMode == null) return;
    state = mode;

    if (_isRestoring) {
      _pendingMode = mode;
      return;
    }

    await _persist(mode);
    _pendingMode = null;
  }

  void _startRestore() {
    _isRestoring = true;
    final generation = ++_restoreGeneration;
    unawaited(_restore(generation));
  }

  Future<void> _restore(int generation) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final restoredMode = AppThemeModeX.fromStorageValue(
      prefs.getString(_kThemeModeKey),
    );
    if (!ref.mounted) return;
    if (_restoreGeneration != generation) return;

    final nextMode = _pendingMode ?? restoredMode;
    _isRestoring = false;
    _restoreGeneration = 0;
    _pendingMode = null;

    if (state != nextMode) {
      state = nextMode;
    }

    await _persist(nextMode);
  }

  Future<void> _persist(AppThemeMode mode) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_kThemeModeKey, mode.storageValue);
  }
}
