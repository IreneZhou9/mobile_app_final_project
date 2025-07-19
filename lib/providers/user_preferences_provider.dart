import 'package:flutter/material.dart';
import '../database/firestore.dart';

class UserPreferencesProvider extends ChangeNotifier {
  // default preferences
  double _fontSize = 16.0;
  String _themeMode = 'system'; // 'light', 'dark', 'system'
  String _accentColor = 'blue';
  bool _notificationsEnabled = true;
  bool _isLoaded = false;

  // database instance
  final FirestoreDatabase _database = FirestoreDatabase();

  // getters
  double get fontSize => _fontSize;
  String get themeMode => _themeMode;
  String get accentColor => _accentColor;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoaded => _isLoaded;

  // font size options
  static const List<double> fontSizeOptions = [12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0];
  
  // theme mode options
  static const List<String> themeModeOptions = ['light', 'dark', 'system'];
  
  // accent color options
  static const Map<String, Color> accentColorOptions = {
    'blue': Colors.blue,
    'green': Colors.green,
    'purple': Colors.purple,
    'orange': Colors.orange,
    'pink': Colors.pink,
    'teal': Colors.teal,
  };

  // load user preferences from database
  Future<void> loadPreferences() async {
    try {
      var doc = await _database.getUserPreferences();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        _fontSize = (data['fontSize'] ?? 16.0).toDouble();
        _themeMode = data['themeMode'] ?? 'system';
        _accentColor = data['accentColor'] ?? 'blue';
        _notificationsEnabled = data['notificationsEnabled'] ?? true;
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error loading preferences: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  // save preferences to database
  Future<void> savePreferences() async {
    try {
      await _database.saveUserPreferences(
        fontSize: _fontSize,
        themeMode: _themeMode,
        accentColor: _accentColor,
        notificationsEnabled: _notificationsEnabled,
      );
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }

  // update font size
  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
    savePreferences();
  }

  // update theme mode
  void setThemeMode(String mode) {
    _themeMode = mode;
    notifyListeners();
    savePreferences();
  }

  // update accent color
  void setAccentColor(String color) {
    _accentColor = color;
    notifyListeners();
    savePreferences();
  }

  // update notifications setting
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    notifyListeners();
    savePreferences();
  }

  // get current accent color
  Color get currentAccentColor => accentColorOptions[_accentColor] ?? Colors.blue;

  // get text style with current font size
  TextStyle getTextStyle({
    FontWeight? fontWeight,
    Color? color,
    double? multiplier,
  }) {
    return TextStyle(
      fontSize: _fontSize * (multiplier ?? 1.0),
      fontWeight: fontWeight,
      color: color,
    );
  }

  // reset to defaults
  void resetToDefaults() {
    _fontSize = 16.0;
    _themeMode = 'system';
    _accentColor = 'blue';
    _notificationsEnabled = true;
    notifyListeners();
    savePreferences();
  }
} 