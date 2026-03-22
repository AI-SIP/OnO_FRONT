class TagModel {
  final int tagId;
  final String name;

  const TagModel({
    required this.tagId,
    required this.name,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      tagId: json['tagId'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}
