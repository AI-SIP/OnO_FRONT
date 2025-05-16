import '../Common/ProblemImageDataType.dart';

class ProblemImageDataRegisterModel {
  final int problemId;
  final String imageUrl;
  final ProblemImageType problemImageType;

  ProblemImageDataRegisterModel({
    required this.problemId,
    required this.imageUrl,
    required this.problemImageType,
  });

  Map<String, dynamic> toJson() => {
        'problemId': problemId,
        'imageUrl': imageUrl,
        'problemImageType': problemImageType.name,
      };
}
