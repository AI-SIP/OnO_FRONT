import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Util/AiAnalysisPreference.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('처음에는 꺼져 있다', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await AiAnalysisPreference.load(), isFalse);
  });

  test('마지막으로 고른 값을 다음에도 쓴다', () async {
    SharedPreferences.setMockInitialValues({});

    await AiAnalysisPreference.save(false);
    expect(await AiAnalysisPreference.load(), isFalse);

    await AiAnalysisPreference.save(true);
    expect(await AiAnalysisPreference.load(), isTrue);
  });
}
