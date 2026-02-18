import 'AnswerStatus.dart';
import 'ImprovementType.dart';

class ProblemSolveUpdateDto {
  final int problemSolveId;
  final AnswerStatus answerStatus;
  final String? reflection;
  final List<ImprovementType> improvements;
  final int? timeSpentSeconds;

  ProblemSolveUpdateDto({
    required this.problemSolveId,
    required this.answerStatus,
    this.reflection,
    required this.improvements,
    this.timeSpentSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'problemSolveId': problemSolveId,
      'answerStatus': answerStatus.toJson(),
      'reflection': reflection,
      'improvements': improvements.map((e) => e.toJson()).toList(),
      'timeSpentSeconds': timeSpentSeconds,
    };
  }
}
