import '../Common/ProblemImageDataType.dart';

class ProblemImageDataRegisterModel {
  final String imageUrl;
  final ProblemImageType problemImageType;
  final DateTime createdAt;

  ProblemImageDataRegisterModel({
    required this.imageUrl,
    required this.problemImageType,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'problemImageType': problemImageType.value,
        'createdAt': createdAt.toIso8601String(),
      };
}
