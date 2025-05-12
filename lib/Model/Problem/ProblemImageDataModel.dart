import 'package:ono/Model/Common/ProblemImageDataType.dart';

class ProblemImageDataModel {
  final String imageUrl;
  final ProblemImageType problemImageType;
  final DateTime createdAt;

  ProblemImageDataModel({
    required this.imageUrl,
    required this.problemImageType,
    required this.createdAt,
  });

  factory ProblemImageDataModel.fromJson(Map<String, dynamic> json) {
    // 서버에서 받은 문자열을 enum으로 변환
    final typeStr = json['problemImageType'] as String;
    final type = ProblemImageType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ProblemImageType.PROBLEM_IMAGE,
    );

    return ProblemImageDataModel(
      imageUrl: json['imageUrl'] as String,
      problemImageType: type,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'problemImageType': problemImageType,
        'createdAt': createdAt.toIso8601String(),
      };
}
