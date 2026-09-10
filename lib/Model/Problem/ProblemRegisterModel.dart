import 'ProblemImageDataRegisterModel.dart';

class ProblemRegisterModel {
  /// 서버 problem.memo 컬럼 길이. 넘겨 보내면 DB 에서 잘리며 500 이 떨어진다.
  static const int memoMaxLength = 1000;

  /// 서버 problem.reference 컬럼 길이. 오답노트의 '제목' 이 이 칸으로 들어간다.
  static const int referenceMaxLength = 255;

  /// 서버 한도에 맞춰 잘라 낸다.
  ///
  /// 입력 필드의 `maxLength` 만으로는 부족해서 보내기 직전에 한 번 더 자른다.
  /// 두 가지 구멍이 있다.
  ///
  /// 1. `maxLength` 는 자소(grapheme) 단위로 세는데 서버와 DB 는 UTF-16 단위로
  ///    센다. 이모지처럼 한 글자가 두 칸을 차지하는 문자가 섞이면 화면에서는
  ///    막히지 않은 채로 서버 한도를 넘길 수 있다.
  /// 2. 자동 생성 제목처럼 코드가 컨트롤러에 직접 넣는 값은 `maxLength` 를
  ///    아예 거치지 않는다. 폴더 이름이 길면 그대로 한도를 넘는다.
  static String clamp(String value, int maxLength) {
    if (value.length <= maxLength) return value;

    var end = maxLength;
    // 서로게이트 쌍 한가운데를 자르면 깨진 문자가 남는다.
    final lastKept = value.codeUnitAt(end - 1);
    if (lastKept >= 0xD800 && lastKept <= 0xDBFF) {
      end -= 1;
    }
    return value.substring(0, end);
  }

  static String clampMemo(String value) => clamp(value, memoMaxLength);

  static String clampReference(String value) =>
      clamp(value, referenceMaxLength);

  int? problemId;
  String? memo;
  String? reference;
  int? folderId;
  DateTime? solvedAt;
  List<ProblemImageDataRegisterModel>? imageDataDtoList;
  List<int>? tagIds;

  ProblemRegisterModel({
    this.problemId,
    this.memo,
    this.reference,
    this.folderId,
    this.solvedAt,
    this.imageDataDtoList,
    this.tagIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'problemId': problemId,
      'memo': memo,
      'reference': reference,
      'folderId': folderId,
      'solvedAt': solvedAt?.toIso8601String(),
      'imageDataDtoList': imageDataDtoList?.map((e) => e.toJson()).toList(),
      'tagIds': tagIds,
    };
  }
}
