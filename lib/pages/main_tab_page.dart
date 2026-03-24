import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'project_list_page.dart';
import 'settings_page.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _index = 0;

  void _onTabSelected(int value) {
    if (_index == value) return;
    setState(() {
      _index = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [ProjectListPage(), SettingsPage()],
      ),
      bottomNavigationBar: Container(
        color: colorScheme.surface,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                _BottomNavItem(
                  label: '项目',
                  selected: _index == 0,
                  selectedIcon: Icons.folder_rounded,
                  icon: Icons.folder_outlined,
                  activeColor: colorScheme.primary,
                  inactiveColor: tokens.mutedForeground,
                  onTap: () => _onTabSelected(0),
                ),
                _BottomNavItem(
                  label: '设置',
                  selected: _index == 1,
                  selectedIcon: Icons.settings,
                  icon: Icons.settings_outlined,
                  activeColor: colorScheme.primary,
                  inactiveColor: tokens.mutedForeground,
                  onTap: () => _onTabSelected(1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 24,
                color: selected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                  color: selected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
