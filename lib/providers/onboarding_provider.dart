import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kServerSetupCompletedKey = 'server_setup_completed_v1';
const String _kServerConfigKey = 'server_config';

final serverSetupCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();

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
});

final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  return OnboardingController(ref);
});

class OnboardingController {
  OnboardingController(this._ref);

  final Ref _ref;

  Future<void> markServerSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kServerSetupCompletedKey, true);
    _ref.invalidate(serverSetupCompletedProvider);
  }
}
