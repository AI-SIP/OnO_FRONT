import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemRegister/ProblemRegisterTemplate.dart';

/// 업로드가 끝나는 순서와 상관없이 고른 순서대로 사진 주소가 놓이는지 본다.
void main() {
  test('늦게 고른 사진이 먼저 올라가도 고른 순서대로 놓인다', () {
    final urls = <String>[];
    final orders = <String, int>{};

    insertInPickOrder(urls, orders, 'c', 2);
    insertInPickOrder(urls, orders, 'a', 0);
    insertInPickOrder(urls, orders, 'b', 1);

    expect(urls, ['a', 'b', 'c']);
  });

  test('수정 화면에서 이미 있던 사진은 앞에 둔다', () {
    final urls = <String>['old'];
    final orders = <String, int>{};

    insertInPickOrder(urls, orders, 'new2', 1);
    insertInPickOrder(urls, orders, 'new1', 0);

    expect(urls, ['old', 'new1', 'new2']);
  });
}
