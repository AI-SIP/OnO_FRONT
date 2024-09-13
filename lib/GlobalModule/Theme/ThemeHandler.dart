import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeHandler with ChangeNotifier {
  // 기본 색상
  Color _primaryColor = Colors.lightGreen;
  Color _darkPrimaryColor = Colors.lightGreen;
  Color _lightPrimaryColor = Colors.lightGreen;
  //Color _secondColor = Colors.lightGreen;
  //Color _thirdColor = Colors.teal;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 각 색상에 대한 getter
  Color get primaryColor => _primaryColor;

  // 색상을 변경하고 저장하는 메서드
  void changePrimaryColor(Color primaryColor) {
    _primaryColor = primaryColor;
    _lightPrimaryColor = _lightenColor(primaryColor, 0.2);
    _darkPrimaryColor = _darkenColor(primaryColor, 0.2);
    _saveColor('primaryColor', primaryColor);
    _saveColor('lightPrimaryColor', _lightPrimaryColor);
    _saveColor('darkPrimaryColor', _darkPrimaryColor);
    notifyListeners();
  }

  // 저장된 색상을 로드하는 메서드
  Future<void> loadColors() async {
    _primaryColor = await _loadColor('primaryColor', Colors.lightGreen);
    _lightPrimaryColor = await _loadColor('lightPrimaryColor', _lightenColor(Colors.lightGreen, 0.2));
    _darkPrimaryColor = await _loadColor('darkPrimaryColor', _darkenColor(Colors.lightGreen, 0.2));
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
  Color _lightenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hslColor = HSLColor.fromColor(color);
    final lightenedHslColor = hslColor.withLightness(
      (hslColor.lightness + amount).clamp(0.0, 1.0),
    );
    return lightenedHslColor.toColor();
  }

  // 더 밝은 색상을 생성하는 메서드
  Color _darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hslColor = HSLColor.fromColor(color);
    final lightenedHslColor = hslColor.withLightness(
      (hslColor.lightness - amount).clamp(0.0, 1.0),
    );
    return lightenedHslColor.toColor();
  }
}
