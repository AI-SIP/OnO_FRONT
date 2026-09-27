import 'AnswerStatus.dart';
import 'ImprovementType.dart';

class ProblemSolveUpdateDto {
  final int problemSolveId;
  final AnswerStatus answerStatus;
  final String? reflection;
  final List<ImprovementType> improvements;
  final int? timeSpentSeconds;

  /// 기분 이모지 키. null 이면 서버에서 지워진다.
  ///
  /// PATCH 는 부분 수정이 아니라 전체 교체다. 이 필드를 빼고 보내면 서버가
  /// null 로 덮어써서 이모지가 사라진다. 수정 요청을 만들 때는 바꿀 생각이
  /// 없더라도 기존 값을 그대로 실어야 한다. reflection 과 improvements 도
  /// 원래 같은 규칙이다.
  final String? moodEmojiKey;

  ProblemSolveUpdateDto({
    required this.problemSolveId,
    required this.answerStatus,
    this.reflection,
    required this.improvements,
    this.timeSpentSeconds,
    this.moodEmojiKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'problemSolveId': problemSolveId,
      'answerStatus': answerStatus.toJson(),
      'reflection': reflection,
      'improvements': improvements.map((e) => e.toJson()).toList(),
      'timeSpentSeconds': timeSpentSeconds,
      'moodEmojiKey': moodEmojiKey,
    };
  }
}
