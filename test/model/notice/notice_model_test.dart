import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Notice/NoticeModel.dart';

void main() {
  group('NoticeType.from', () {
    test('서버가 주는 세 가지를 그대로 옮긴다', () {
      expect(NoticeType.from('INFO'), NoticeType.info);
      expect(NoticeType.from('WARNING'), NoticeType.warning);
      expect(NoticeType.from('EVENT'), NoticeType.event);
    });

    test('나중에 값이 늘어나 모르는 종류가 와도 info 로 떨어진다', () {
      // 백엔드가 type 값을 늘릴 수 있다고 해서, 앱이 죽는 대신 기본 모양으로
      // 그리기로 했다.
      expect(NoticeType.from('MAINTENANCE'), NoticeType.info);
      expect(NoticeType.from(null), NoticeType.info);
      expect(NoticeType.from(''), NoticeType.info);
    });
  });

  group('NoticeModel.fromJson', () {
    test('공지 한 건을 그대로 읽는다', () {
      final notice = NoticeModel.fromJson({
        'noticeId': 12,
        'title': '점검 안내',
        'content': '오늘 밤 2시부터\n30분간 점검이 있습니다.',
        'type': 'WARNING',
        'expiresAt': '2026-09-08T23:10:00',
      });

      expect(notice.noticeId, 12);
      expect(notice.title, '점검 안내');
      expect(notice.content, contains('\n'));
      expect(notice.type, NoticeType.warning);
      expect(notice.expiresAt, DateTime(2026, 9, 8, 23, 10));
    });

    test('expiresAt 이 없거나 이상해도 공지는 만들어진다', () {
      // 만료 판정은 서버가 한다. 이 값은 화면에 보여주는 용도라서 없다고
      // 공지를 못 띄우면 안 된다.
      expect(
        NoticeModel.fromJson({
          'noticeId': 1,
          'title': '제목',
          'content': '본문',
          'type': 'INFO',
        }).expiresAt,
        isNull,
      );
      expect(
        NoticeModel.fromJson({
          'noticeId': 1,
          'title': '제목',
          'content': '본문',
          'type': 'INFO',
          'expiresAt': '알 수 없는 형식',
        }).expiresAt,
        isNull,
      );
    });

    test('title 과 content 가 비어 있어도 빈 문자열로 채운다', () {
      final notice = NoticeModel.fromJson({'noticeId': 3, 'type': 'EVENT'});

      expect(notice.title, '');
      expect(notice.content, '');
      expect(notice.type, NoticeType.event);
    });
  });
}
