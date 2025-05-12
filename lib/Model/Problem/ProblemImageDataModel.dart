class ProblemImageDataModel {
  final String imageUrl;
  final String problemImageType;
  final DateTime createdAt;

  ProblemImageDataModel({
    required this.imageUrl,
    required this.problemImageType,
    required this.createdAt,
  });

  factory ProblemImageDataModel.fromJson(Map<String, dynamic> json) {
    return ProblemImageDataModel(
      imageUrl: json['imageUrl'] as String,
      problemImageType: json['problemImageType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'problemImageType': problemImageType,
        'createdAt': createdAt.toIso8601String(),
      };
}
