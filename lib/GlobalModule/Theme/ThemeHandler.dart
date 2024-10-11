import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeHandler with ChangeNotifier {
  // 기본 색상
  Color _primaryColor;
  Color _lightPrimaryColor;
  Color _darkPrimaryColor;
  Color _desaturateColor;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ThemeHandler()
      : _primaryColor = Colors.lightGreen,
        _lightPrimaryColor = _lightenColor(Colors.lightGreen, 0.2),
        _darkPrimaryColor = _darkenColor(Colors.lightGreen, 0.2),
        _desaturateColor = _desaturatenColor(Colors.lightGreen, 0.5) {
    loadColors(); // 생성자에서 색상을 불러오는 메서드 호출
  }

  // 각 색상에 대한 getter
  Color get primaryColor => _primaryColor;
  Color get lightPrimaryColor => _lightPrimaryColor;
  Color get darkPrimaryColor => _darkPrimaryColor;
  Color get desaturateColor => _desaturateColor;

  // 색상을 변경하고 저장하는 메서드
  void changePrimaryColor(Color primaryColor, String colorName) {
    _primaryColor = primaryColor;
    _lightPrimaryColor = _lightenColor(primaryColor, 0.2);
    _darkPrimaryColor = _darkenColor(primaryColor, 0.2);
    _desaturateColor = _desaturatenColor(primaryColor, 0.5);
    _saveColor('primaryColor', primaryColor);
    _saveColor('lightPrimaryColor', _lightPrimaryColor);
    _saveColor('darkPrimaryColor', _darkPrimaryColor);
    _saveColor('desaturateColor', _desaturateColor);

    FirebaseAnalytics.instance.logEvent(name: 'theme_color_change_to_$colorName');
    notifyListeners();
  }

  // 저장된 색상을 로드하는 메서드
  Future<void> loadColors() async {
    _primaryColor = await _loadColor('primaryColor', Colors.lightGreen);
    _lightPrimaryColor = await _loadColor(
        'lightPrimaryColor', _lightenColor(Colors.lightGreen, 0.2));
    _darkPrimaryColor = await _loadColor(
        'darkPrimaryColor', _darkenColor(Colors.lightGreen, 0.2));
    _desaturateColor = await _loadColor(
        'desaturateColor', _desaturatenColor(Colors.lightGreen, 0.5));
    notifyListeners();
  }

  // 색상을 저장하는 메서드
  Future<void> _saveColor(String key, Color color) async {
    await _storage.write(key: key, value: color.value.toRadixString(16));
  }

  // 색상을 불러오는 메서드
  Future<Color> _loadColor(String key, Color defaultColor) async {
    final colorString = await _storage.read(key: key);
    if (colorString != null) {
      return Color(int.parse(colorString, radix: 16));
    }
    return defaultColor;
  }

  // 더 밝은 색상을 생성하는 메서드
  static Color _lightenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hslColor = HSLColor.fromColor(color);
    final lightenedHslColor = hslColor.withLightness(
      (hslColor.lightness + amount).clamp(0.0, 1.0),
    );
    return lightenedHslColor.toColor();
  }

  // 더 밝은 색상을 생성하는 메서드
  static Color _darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hslColor = HSLColor.fromColor(color);
    final lightenedHslColor = hslColor.withLightness(
      (hslColor.lightness - amount).clamp(0.0, 1.0),
    );
    return lightenedHslColor.toColor();
  }

  static Color _desaturatenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    return color.withOpacity(
      (color.opacity - amount).clamp(0.0, 1.0), // 투명도를 감소시킴
    );
  }
}
