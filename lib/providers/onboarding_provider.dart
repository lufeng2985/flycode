import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'shared_preferences_provider.dart';

part 'onboarding_provider.g.dart';

const String _kServerSetupCompletedKey = 'server_setup_completed_v1';
const String _kServerConfigKey = 'server_config';

@riverpod
Future<bool> serverSetupCompleted(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);

  final completed = prefs.getBool(_kServerSetupCompletedKey);
  if (completed != null) {
    return completed;
  }

  final hasLegacyConfig =
      prefs.containsKey(_kServerConfigKey) &&
      (prefs.getString(_kServerConfigKey)?.isNotEmpty ?? false);
  if (hasLegacyConfig) {
    await prefs.setBool(_kServerSetupCompletedKey, true);
    return true;
  }

  return false;
}

@riverpod
OnboardingController onboardingController(Ref ref) {
  return OnboardingController(ref);
}

class OnboardingController {
  OnboardingController(this._ref);

  final Ref _ref;

  Future<void> markServerSetupCompleted() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kServerSetupCompletedKey, true);
    _ref.invalidate(serverSetupCompletedProvider);
  }
}
