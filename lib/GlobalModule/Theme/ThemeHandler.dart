import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeHandler with ChangeNotifier {
  // 기본 색상
  Color _primaryColor = Colors.green;
  Color _secondColor = Colors.lightGreen;
  Color _thirdColor = Colors.teal;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 각 색상에 대한 getter
  Color get primaryColor => _primaryColor;
  Color get secondColor => _secondColor;
  Color get thirdColor => _thirdColor;

  // 색상을 변경하고 저장하는 메서드
  void changePrimaryColor(Color primaryColor) {
    _primaryColor = primaryColor;
    _saveColor('primaryColor', primaryColor);
    notifyListeners();
  }

  // SecondColor와 ThirdColor도 저장할 수 있도록 수정
  void changeSecondColor(Color secondColor) {
    _secondColor = secondColor;
    _saveColor('secondColor', secondColor);
    notifyListeners();
  }

  void changeThirdColor(Color thirdColor) {
    _thirdColor = thirdColor;
    _saveColor('thirdColor', thirdColor);
    notifyListeners();
  }

  // 저장된 색상을 로드하는 메서드
  Future<void> loadColors() async {
    _primaryColor = await _loadColor('primaryColor', Colors.green);
    _secondColor = await _loadColor('secondColor', Colors.lightGreen);
    _thirdColor = await _loadColor('thirdColor', Colors.teal);
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
}
