import 'package:flutter/material.dart';
import 'package:mobile_app_project/themes/dark_mode.dart';
import 'package:mobile_app_project/themes/light_mode.dart';

class ThemeProvider extends ChangeNotifier {
  // current theme data
  ThemeData _themeData = lightMode;
  String _themeMode = 'system'; // 'light', 'dark', 'system'

  // getters
  ThemeData get themeData => _themeData;
  String get themeMode => _themeMode;
  bool get isDarkMode => _themeData == darkMode;

  // set theme mode
  void setThemeMode(String mode, {Brightness? systemBrightness}) {
    _themeMode = mode;
    _updateTheme(systemBrightness: systemBrightness);
    notifyListeners();
  }

  // force light mode
  void setLightMode() {
    _themeMode = 'light';
    _themeData = lightMode;
    notifyListeners();
  }

  // force dark mode
  void setDarkMode() {
    _themeMode = 'dark';
    _themeData = darkMode;
    notifyListeners();
  }

  // toggle between light and dark (not system)
  void toggleTheme() {
    if (_themeMode == 'system') {
      // if currently system, switch to opposite of current appearance
      _themeMode = isDarkMode ? 'light' : 'dark';
    } else {
      // toggle between light and dark
      _themeMode = _themeMode == 'light' ? 'dark' : 'light';
    }
    _updateTheme();
    notifyListeners();
  }

  // update theme based on system brightness (for system mode)
  void updateSystemTheme(Brightness systemBrightness) {
    if (_themeMode == 'system') {
      _updateTheme(systemBrightness: systemBrightness);
      notifyListeners();
    }
  }

  // internal method to update theme data
  void _updateTheme({Brightness? systemBrightness}) {
    switch (_themeMode) {
      case 'light':
        _themeData = lightMode;
        break;
      case 'dark':
        _themeData = darkMode;
        break;
      case 'system':
        final brightness = systemBrightness ?? 
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        _themeData = brightness == Brightness.dark ? darkMode : lightMode;
        break;
    }
  }

  // get theme mode display text
  String get themeModeDisplayText {
    switch (_themeMode) {
      case 'light':
        return 'Light Mode';
      case 'dark':
        return 'Dark Mode';
      case 'system':
        return 'System Mode';
      default:
        return 'System Mode';
    }
  }

  // get appropriate icon for current theme mode
  IconData get themeModeIcon {
    switch (_themeMode) {
      case 'light':
        return Icons.light_mode;
      case 'dark':
        return Icons.dark_mode;
      case 'system':
        return Icons.brightness_auto;
      default:
        return Icons.brightness_auto;
    }
  }
} 