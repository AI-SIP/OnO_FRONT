class PaginatedResponse<T> {
  final List<T> content;
  final int? nextCursor;
  final bool hasNext;
  final int size;

  PaginatedResponse({
    required this.content,
    required this.nextCursor,
    required this.hasNext,
    required this.size,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    // API 응답이 { errorCode, message, data } 형식으로 래핑되어 있는 경우 처리
    final dataMap = json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;

    return PaginatedResponse<T>(
      content: (dataMap['content'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      nextCursor: dataMap['nextCursor'] as int?,
      hasNext: dataMap['hasNext'] as bool,
      size: dataMap['size'] as int,
    );
  }

  bool get isLastPage => !hasNext || nextCursor == null;
}