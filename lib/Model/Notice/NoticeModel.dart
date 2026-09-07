/// 서비스 공지의 종류다.
///
/// 서버는 `INFO` / `WARNING` / `EVENT` 를 내려주는데, 나중에 값이 늘어날 수
/// 있다고 했다. 모르는 값이 와도 앱이 죽지 않도록 [NoticeType.from] 에서
/// [NoticeType.info] 로 떨어뜨린다.
enum NoticeType {
  info,
  warning,
  event;

  static NoticeType from(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'WARNING':
        return NoticeType.warning;
      case 'EVENT':
        return NoticeType.event;
      default:
        return NoticeType.info;
    }
  }
}

/// 메인 진입 때 팝업으로 띄우는 서비스 공지다.
///
/// 한 번에 한 건만 내려오고, 노출 기간은 서버가 관리한다. 앱에서 만료를
/// 계산하지 않는다. [expiresAt] 은 화면에 언제까지인지 보여주는 용도다.
class NoticeModel {
  final int noticeId;
  final String title;
  final String content;
  final NoticeType type;
  final DateTime? expiresAt;

  const NoticeModel({
    required this.noticeId,
    required this.title,
    required this.content,
    required this.type,
    this.expiresAt,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    return NoticeModel(
      noticeId: json['noticeId'] as int,
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      type: NoticeType.from(json['type'] as String?),
      // 서버가 KST 기준 시각을 ISO-8601 로 내려준다. 표시용이라 파싱에
      // 실패해도 공지 자체는 띄워야 한다.
      expiresAt: DateTime.tryParse((json['expiresAt'] as String?) ?? ''),
    );
  }
}
