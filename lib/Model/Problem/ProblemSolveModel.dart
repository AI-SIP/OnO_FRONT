import 'AnswerStatus.dart';
import 'ImprovementType.dart';

class ProblemSolveModel {
  final int problemSolveId;
  final int problemId;
  final int userId;
  final DateTime practicedAt;
  final AnswerStatus answerStatus;
  final String? reflection;
  final List<ImprovementType> improvements;
  final int? timeSpentSeconds;

  /// 이 복습 회차의 기분 이모지 키다. 안 고르고 넘어갈 수 있어서 null 이 온다.
  /// 유니코드 이모지 문자가 아니라 `excited_happy` 같은 키 문자열이다.
  final String? moodEmojiKey;
  final bool migratedFromLegacy;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProblemSolveModel({
    required this.problemSolveId,
    required this.problemId,
    required this.userId,
    required this.practicedAt,
    required this.answerStatus,
    this.reflection,
    required this.improvements,
    this.timeSpentSeconds,
    this.moodEmojiKey,
    required this.migratedFromLegacy,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProblemSolveModel.fromJson(Map<String, dynamic> json) {
    return ProblemSolveModel(
      problemSolveId: json['problemSolveId'],
      problemId: json['problemId'],
      userId: json['userId'],
      practicedAt: DateTime.parse(json['practicedAt']),
      answerStatus: AnswerStatusExtension.fromJson(json['answerStatus']),
      reflection: json['reflection'],
      improvements: (json['improvements'] as List<dynamic>?)
              ?.map((e) => ImprovementTypeExtension.fromJson(e as String))
              .toList() ??
          [],
      timeSpentSeconds: json['timeSpentSeconds'],
      moodEmojiKey: json['moodEmojiKey'] as String?,
      migratedFromLegacy: json['migratedFromLegacy'] ?? false,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'problemSolveId': problemSolveId,
      'problemId': problemId,
      'userId': userId,
      'practicedAt': practicedAt.toIso8601String(),
      'answerStatus': answerStatus.toJson(),
      'reflection': reflection,
      'improvements': improvements.map((e) => e.toJson()).toList(),
      'timeSpentSeconds': timeSpentSeconds,
      'moodEmojiKey': moodEmojiKey,
      'migratedFromLegacy': migratedFromLegacy,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
