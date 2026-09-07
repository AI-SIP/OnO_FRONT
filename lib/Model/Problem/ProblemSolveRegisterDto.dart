import 'AnswerStatus.dart';
import 'ImprovementType.dart';

class ProblemSolveRegisterDto {
  final int problemId;
  final DateTime practicedAt;
  final AnswerStatus answerStatus;
  final String? reflection;
  final List<ImprovementType> improvements;
  final int? timeSpentSeconds;

  /// 기분 이모지 키. 안 고르면 null 이고 서버도 null 로 저장한다.
  final String? moodEmojiKey;

  ProblemSolveRegisterDto({
    required this.problemId,
    required this.practicedAt,
    required this.answerStatus,
    this.reflection,
    required this.improvements,
    this.timeSpentSeconds,
    this.moodEmojiKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'problemId': problemId,
      'practicedAt': practicedAt.toIso8601String(),
      'answerStatus': answerStatus.toJson(),
      'reflection': reflection,
      'improvements': improvements.map((e) => e.toJson()).toList(),
      'timeSpentSeconds': timeSpentSeconds,
      'moodEmojiKey': moodEmojiKey,
    };
  }
}
