import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme_mode.dart';
import '../theme/theme_mode_provider.dart';

class ThemeModePage extends ConsumerWidget {
  const ThemeModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('色彩主题')),
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
              RadioListTile<AppThemeMode>(value: mode, title: Text(mode.label)),
          ],
        ),
      ),
    );
  }
}
