// 훈장표와 계약 픽스처가 어긋나지 않는지 잠근다.
//
// **표를 여기에 다시 옮겨 적지 않는다.** `docs/훈장/훈장표.md` 를 직접 읽어서
// 비교한다. 옮겨 적으면 문서와 테스트와 픽스처가 셋이 되고, 셋이 되면 언젠가
// 둘씩 짝지어 어긋난다. 문서가 계약이라면 계약서를 읽어야 한다. 치장의
// `test/screen/cosmetic/cosmetic_unlock_table_test.dart` 와 같은 방식이다.
//
// 앱에는 훈장 목록이 박혀 있지 않다. 열두 개의 key·이름·설명은 전부 서버가
// 주므로, 앱 쪽에서 문서와 맞대 볼 수 있는 것은 **계약 픽스처**
// (`test/fixtures/achievement/get_achievements_response.json`)와 **에셋 열두
// 장**이다. 문서를 고치고 픽스처를 안 고치면 여기서 걸리고, 픽스처를 고치고
// 문서를 안 고쳐도 여기서 걸린다. 어느 쪽을 먼저 고쳐야 하는지는 문서가
// 계약이므로 문서다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

/// 훈장표 한 줄.
class _TableRow {
  final String key;
  final String nameKo;
  final String descriptionKo;

  const _TableRow({
    required this.key,
    required this.nameKo,
    required this.descriptionKo,
  });

  @override
  String toString() => '$key($nameKo)';
}

/// 문서 경로. `flutter test` 는 패키지 루트에서 돈다.
const String _docPath = 'docs/훈장/훈장표.md';

/// `| `first_step` | 첫 걸음 | 오답노트를 처음 작성했어요 | 오답노트 1개 | `problem` |`
///
/// 표의 머리줄(`| key | 이름 | ... |`)과 구분선은 첫 칸이 백틱으로 감싸인
/// 식별자가 아니라서 저절로 걸러진다.
final RegExp _row = RegExp(
  r'^\|\s*`([a-z0-9_]+)`\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|',
);

/// `## 진행도` 절에서 굵게 적힌 훈장 이름. `**불사조**` 를 잡는다.
final RegExp _boldName = RegExp(r'\*\*([^*]+)\*\*');

/// 문서를 읽어 목록 표 전체를 편다.
///
/// `main()` 몸통에서 바로 읽지 않는 이유는, 파일이 없거나 표가 깨졌을 때
/// 테스트 하나가 실패하는 것과 파일 전체가 로드에 실패하는 것이 다르기
/// 때문이다. 뒤쪽은 무엇이 왜 틀렸는지 안 보인다.
final List<_TableRow> _table = _readTable();

/// `## 진행도` 절이 "진행도를 안 내려준다"고 말한 훈장들의 key.
final Set<String> _noProgressKeys = _readNoProgressKeys();

List<String> _docLines() {
  final file = File(_docPath);
  if (!file.existsSync()) {
    throw StateError('$_docPath 가 없다. 훈장표가 곧 계약이라 문서 없이는 이 테스트가 의미가 없다.');
  }
  return file.readAsLinesSync();
}

List<_TableRow> _readTable() {
  final rows = <_TableRow>[];
  for (final line in _docLines()) {
    final match = _row.firstMatch(line);
    if (match == null) continue;
    rows.add(
      _TableRow(
        key: match.group(1)!,
        nameKo: match.group(2)!,
        descriptionKo: match.group(3)!,
      ),
    );
  }
  return rows;
}

/// `## 진행도` 절만 훑어 굵게 적힌 **훈장 이름**을 key 로 바꿔 모은다.
///
/// 절을 가르지 않으면 `## 조건을 어떻게 세는가` 의 `**집념**`, `**개근**` 까지
/// 딸려 온다. 그쪽은 세는 법을 설명하는 굵은 글씨지 진행도 이야기가 아니다.
/// 절 안에도 `**지금 몇까지 왔는지**` 처럼 훈장이 아닌 강조가 섞여 있어서,
/// **목록 표에 이름이 있는 것만** 남긴다.
///
/// 산문에서 이름을 줍는 것이라 문단을 다시 쓰면 여기서 걸린다. 그래도 이 편이
/// 낫다고 본 이유는, 진행도를 안 내려주는 훈장이 어느 것인지가 표에 칸으로
/// 적혀 있지 않고 **그 문단에만** 적혀 있기 때문이다. 문단을 고쳐 쓸 일이
/// 생기면 이 테스트도 같이 봐야 한다는 뜻이고, 그게 맞다.
Set<String> _readNoProgressKeys() {
  final keyOfName = {for (final row in _table) row.nameKo: row.key};
  final keys = <String>{};
  var inSection = false;

  for (final line in _docLines()) {
    if (line.startsWith('## ')) {
      inSection = line.contains('진행도');
      continue;
    }
    if (!inSection) continue;
    for (final match in _boldName.allMatches(line)) {
      final key = keyOfName[match.group(1)!.trim()];
      if (key != null) keys.add(key);
    }
  }

  return keys;
}

void main() {
  setUpOnoTest();

  group('훈장표 읽기', () {
    test('표에서 열두 줄을 읽었다', () {
      // 이 숫자가 틀리면 아래 비교가 통째로 무의미해진다. 파서가 표를 제대로
      // 훑었는지부터 확인한다.
      expect(_table, hasLength(12));
    });

    test('같은 key 가 두 번 적혀 있지 않다', () {
      final keys = <String>{};
      for (final row in _table) {
        expect(keys.add(row.key), isTrue, reason: '${row.key} 가 두 번 있다');
      }
    });

    test('이름과 설명이 빈 줄이 없다', () {
      for (final row in _table) {
        expect(row.nameKo, isNotEmpty, reason: '${row.key} 의 이름이 비었다');
        expect(row.descriptionKo, isNotEmpty, reason: '${row.key} 의 설명이 비었다');
      }
    });

    test('진행도 절이 훈장 둘을 가리킨다', () {
      // 하나도 못 찾았으면 문단을 다시 써서 파서가 훈장 이름을 놓친 것이다.
      // 그때 아래 비교는 "픽스처에도 진행도 없는 것이 없다"를 통과시켜 버린다.
      expect(_noProgressKeys, hasLength(2));
    });
  });

  group('계약 픽스처가 훈장표를 따른다', () {
    final achievements = AchievementMockData.achievements;

    test('개수가 같다', () {
      expect(achievements, hasLength(_table.length));
    });

    test('순서까지 같다', () {
      // 화면은 서버가 준 순서를 그대로 그린다. 정렬하지 않는다. 그 순서가
      // 문서의 순서라는 것을 여기서 잠근다.
      expect(
        AchievementMockData.keys,
        [for (final row in _table) row.key],
      );
    });

    test('이름과 설명이 표와 같다', () {
      final byKey = {for (final item in achievements) item.key: item};

      for (final row in _table) {
        final item = byKey[row.key];
        expect(item, isNotNull, reason: '픽스처에 ${row.key} 가 없다');
        if (item == null) continue;

        expect(item.nameKo, row.nameKo, reason: '$row 의 이름이 다르다');
        expect(
          item.descriptionKo,
          row.descriptionKo,
          reason: '$row 의 설명이 다르다',
        );
      }
    });

    test('표에 없는 훈장이 픽스처에 끼어 있지 않다', () {
      final tableKeys = {for (final row in _table) row.key};

      for (final item in achievements) {
        expect(tableKeys, contains(item.key), reason: '${item.key} 는 훈장표에 없다');
      }
    });

    test('진행도를 안 내려주는 둘이 문서가 말한 그 둘이다', () {
      // 문서는 이름으로 말하고 픽스처는 key 로 말한다. 표를 거쳐 맞춘다.
      expect(AchievementMockData.keysWithoutProgress, _noProgressKeys);
      expect(AchievementMockData.keysWithoutProgress, hasLength(2));
    });
  });

  group('그림', () {
    test('훈장 열두 장이 문서가 말한 자리에 있다', () {
      // 그림 경로는 문자열이라 오타가 나도 컴파일이 통과한다. 드러나는 것은
      // 그 화면을 켠 사람 앞에서고, 훈장 카드는 그림을 못 읽으면 빨간 상자
      // 대신 빈자리를 두므로 더더욱 조용히 사라진다.
      for (final row in _table) {
        final path = 'assets/Medal/${row.key}.png';
        expect(File(path).existsSync(), isTrue, reason: '$path 가 없다');
      }
    });

    test('픽스처의 imageUrl 이 그 경로를 가리킨다', () {
      for (final item in AchievementMockData.achievements) {
        expect(item.imageUrl, 'assets/Medal/${item.key}.png');
      }
    });

    test('lib 안에서 부르는 assets/Medal 경로가 전부 실제 파일이다', () {
      // 옷장 탭의 훈장 줄이 훈장 그림 한 장을 버튼 아이콘으로 쓴다. 그 key 가
      // 표에서 사라지면 에셋도 같이 사라지는데, 그때 버튼 그림만 조용히
      // 비어 버린다.
      final pattern = RegExp(r'assets/Medal/[A-Za-z0-9_]+\.png');
      final paths = <String>{};
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        paths.addAll(
          pattern.allMatches(entity.readAsStringSync()).map((m) => m.group(0)!),
        );
      }

      // 하나도 못 찾았으면 정규식이 썩었거나 진입점이 사라진 것이다.
      expect(paths, isNotEmpty);
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: '$path 가 없다');
      }
    });
  });
}
