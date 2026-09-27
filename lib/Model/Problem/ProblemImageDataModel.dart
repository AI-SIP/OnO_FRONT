import 'package:flutter/foundation.dart';
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

  /// 이미지 한 줄을 읽는다. 쓸 수 없는 줄이면 null 이다.
  ///
  /// 서버 컬럼에 not null 제약이 없어서 값이 빠진 줄이 섞일 수 있다. 예전에는
  /// non-null 캐스팅이라 그런 줄 하나가 문제 상세·폴더 목록·태그 목록·검색을
  /// 전부 파싱 단계에서 죽였다.
  ///
  /// - `imageUrl` 이 없으면 **그 줄을 버린다.** 주소가 없는 이미지는 그릴 것이
  ///   없어서, 빈 문자열로 남겨 두면 썸네일과 갤러리에 빈 칸만 하나 더 생긴다.
  /// - `problemImageType` 을 모르면 PROBLEM_IMAGE 로 본다. 예전부터 모르는
  ///   문자열에 쓰던 폴백과 같다.
  /// - `createdAt` 은 화면에 쓰이지 않아서, 없으면 읽은 시각으로 채우고 줄은
  ///   살린다. 날짜 하나 때문에 그림을 못 보여 줄 이유가 없다.
  static ProblemImageDataModel? fromJsonOrNull(Object? json) {
    if (json is! Map) return null;

    final imageUrl = json['imageUrl'];
    if (imageUrl is! String || imageUrl.isEmpty) {
      debugPrint('[ProblemImageDataModel] imageUrl 이 없어 건너뛴다: $json');
      return null;
    }

    final typeStr = json['problemImageType'];
    final type = ProblemImageType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ProblemImageType.PROBLEM_IMAGE,
    );

    final rawCreatedAt = json['createdAt'];
    final createdAt =
        rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null;

    return ProblemImageDataModel(
      imageUrl: imageUrl,
      problemImageType: type,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// 여러 줄을 읽는다. 읽지 못한 줄은 버린다.
  static List<ProblemImageDataModel> listFrom(Object? json) {
    if (json is! List) return const [];
    return [
      for (final entry in json)
        if (fromJsonOrNull(entry) case final image?) image,
    ];
  }

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'problemImageType': problemImageType,
        'createdAt': createdAt.toIso8601String(),
      };
}
