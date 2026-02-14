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
      'migratedFromLegacy': migratedFromLegacy,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
