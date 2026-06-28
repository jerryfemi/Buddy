import 'package:buddy/models/theme_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hive/hive.dart';

final themeBoxProvider = Provider<Box<ThemePreference>>(
  (ref) => Hive.box<ThemePreference>('themeBox'),
);

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final box = ref.watch(themeBoxProvider);
  return ThemeNotifier(box);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Box<ThemePreference> _box;

  static const String _key = 'preference';

  ThemeNotifier(this._box) : super(ThemeMode.system) {
    _loadTheme();
  }

  // load saved theme from box
  void _loadTheme() {
    final pref = _box.get(_key);
    if (pref != null) {
      state = _mapStringToMode(pref.mode);
    } else {
      state = ThemeMode.system;
    }
  }

  // update theme mode
  void setTheme(ThemeMode mode) {
    state = mode;
    final pref = ThemePreference(mode: _mapModeToString(mode));
    _box.put(_key, pref);
  }

  // convert themeMode to string
  String _mapModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  // convert string mode to themeMode
  ThemeMode _mapStringToMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
