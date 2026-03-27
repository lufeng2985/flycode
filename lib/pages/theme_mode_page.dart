import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme_mode.dart';
import '../theme/theme_mode_provider.dart';

class ThemeModePage extends ConsumerWidget {
  const ThemeModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.themeModeTitle)),
      body: RadioGroup<AppThemeMode>(
        groupValue: selected,
        onChanged: (value) {
          if (value == null) return;
          ref.read(themeModeProvider.notifier).setMode(value);
        },
        child: ListView(
          children: [
            const SizedBox(height: 8),
            for (final mode in AppThemeMode.values)
              RadioListTile<AppThemeMode>(
                value: mode,
                title: Text(mode.label(l10n)),
              ),
          ],
        ),
      ),
    );
  }
}
