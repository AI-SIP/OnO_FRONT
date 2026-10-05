/// 목록을 어느 순서로 받을지. 서버 커서 목록의 `sort` 파라미터와 짝이다.
///
/// 서버는 값을 보내지 않으면 예전처럼 오래된 순으로 준다. 앱은 최근에 쓴
/// 오답노트가 먼저 보이도록 기본으로 최근 순을 보낸다.
enum ListSort {
  /// 최근에 만든 것이 위.
  newest,

  /// 먼저 만든 것이 위.
  oldest;

  /// 서버에 보내는 값.
  String get apiValue => switch (this) {
        ListSort.newest => 'NEWEST',
        ListSort.oldest => 'OLDEST',
      };

  /// 화면에 보이는 이름.
  String get label => switch (this) {
        ListSort.newest => '최근 등록순',
        ListSort.oldest => '오래된순',
      };

  static ListSort fromName(String? name) => ListSort.values.firstWhere(
        (sort) => sort.name == name,
        orElse: () => ListSort.newest,
      );
}
