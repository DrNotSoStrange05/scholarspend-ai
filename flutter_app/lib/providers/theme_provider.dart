import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const _key = 'is_dark_mode';

  bool _isDark = true; // default: dark mode

  bool get isDark => _isDark;

  ThemeService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
  }
}
