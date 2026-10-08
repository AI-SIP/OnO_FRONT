import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/Tag/TagModel.dart';
import 'package:ono/Screen/PracticeNote/PracticeSetAnalysis.dart';
import 'package:ono/Service/Pdf/PracticePdfExporter.dart';
import 'package:ono/Service/Pdf/PracticeWorksheetPdf.dart';

import '../../helpers/helpers.dart';

/// 문제 사진 대신 쓰는 그림. 줄 몇 개를 그어 글줄처럼 보이게 한다.
Uint8List _photo(int width, int height) {
  final image = img.Image(width: width, height: height)
    ..clear(img.ColorRgb8(250, 249, 245));
  for (var y = 60; y < height - 40; y += 48) {
    img.fillRect(image,
        x1: 40,
        y1: y,
        x2: width - 80,
        y2: y + 14,
        color: img.ColorRgb8(70, 70, 70));
  }
  return img.encodeJpg(image, quality: 80);
}

void main() {
  setUpOnoTest();

  final regular =
      File('assets/fonts/pdf/Pretendard-Regular.ttf').readAsBytesSync();
  final bold = File('assets/fonts/pdf/Pretendard-Bold.ttf').readAsBytesSync();

  List<WorksheetItem> items(int count) => [
        for (var i = 0; i < count; i++)
          WorksheetItem(
            meta: '2024 6월 모평 ${i + 1}번 · #미분 #극값 · 3번 풀었어요 · 지난번엔 틀렸어요',
            problemImage: i % 3 == 2
                ? null
                : (i.isEven ? _photo(1400, 900) : _photo(800, 1400)),
            answerImage: i % 4 == 3 ? null : _photo(1000, 700),
            memo: i.isEven ? '극댓값이랑 극솟값 위치를 또 바꿔 썼다. 다음엔 증감표부터 그리기' : null,
          ),
      ];

  Future<Uint8List> build(int count, WorksheetOptions options) {
    return buildPracticeWorksheetPdf(
      title: '중간고사 대비 수학Ⅱ',
      items: items(count),
      options: options,
      regularFont: regular,
      boldFont: bold,
      accentColor: 0xFFF48FB1,
    );
  }

  group('worksheetPageCount', () {
    test('학습지 쪽과 정답지 쪽을 더한다', () {
      const two = WorksheetOptions(
          layout: WorksheetLayout.two, withAnswers: true, withMemo: true);
      const four = WorksheetOptions(
          layout: WorksheetLayout.four, withAnswers: true, withMemo: true);
      expect(worksheetPageCount(12, two), 6 + 2);
      expect(worksheetPageCount(12, four), 3 + 2);
      expect(worksheetPageCount(7, two), 4 + 2);
      expect(worksheetPageCount(1, four), 1 + 1);
    });

    test('정답지를 빼면 학습지 쪽만 센다', () {
      const options = WorksheetOptions(
          layout: WorksheetLayout.two, withAnswers: false, withMemo: true);
      expect(worksheetPageCount(5, options), 3);
    });

    test('문제가 없으면 0쪽이다', () {
      const options = WorksheetOptions(
          layout: WorksheetLayout.four, withAnswers: true, withMemo: true);
      expect(worksheetPageCount(0, options), 0);
    });
  });

  group('buildPracticeWorksheetPdf', () {
    // 시트에서 고를 수 있는 경우의 수 전부. 메모는 정답지가 있을 때만 켤 수 있다.
    const answerChoices = [
      (withAnswers: true, withMemo: true, name: '정답지_메모'),
      (withAnswers: true, withMemo: false, name: '정답지만'),
      (withAnswers: false, withMemo: false, name: '정답지_없음'),
    ];
    for (final layout in WorksheetLayout.values) {
      for (final choice in answerChoices) {
        final label =
            '${layout == WorksheetLayout.two ? '두문제' : '네문제'}_${choice.name}';
        test('$label 로 끝까지 그린다', () async {
          final options = WorksheetOptions(
            layout: layout,
            withAnswers: choice.withAnswers,
            withMemo: choice.withMemo,
          );
          // 마지막 쪽이 덜 차는 경우까지 보려고 쪽 수로 나눠떨어지지 않게 둔다.
          final bytes = await build(7, options);
          expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

          // 눈으로 볼 때: PDF_OUT=/tmp/out flutter test <이 파일>
          final out = Platform.environment['PDF_OUT'];
          if (out != null) {
            File('$out/$label.pdf')
              ..createSync(recursive: true)
              ..writeAsBytesSync(bytes);
          }
        });
      }
    }
  });

  group('shrinkWorksheetImage', () {
    test('긴 변을 1400 으로 줄인다', () {
      final shrunk = shrinkWorksheetImage(_photo(3000, 2000))!;
      final decoded = img.decodeJpg(shrunk)!;
      expect(decoded.width, 1400);
      expect(decoded.height, closeTo(933, 1));
    });

    test('작은 사진은 그대로 둔다', () {
      final decoded = img.decodeJpg(shrinkWorksheetImage(_photo(600, 400))!)!;
      expect(decoded.width, 600);
    });

    test('투명한 곳은 검게 아니라 희게 채운다', () {
      final png = img.encodePng(img.Image(width: 20, height: 20, numChannels: 4)
        ..clear(img.ColorRgba8(0, 0, 0, 0)));
      final pixel = img.decodeJpg(shrinkWorksheetImage(png)!)!.getPixel(5, 5);
      expect(pixel.r, greaterThan(240));
    });

    test('그림이 아니면 null 이다', () {
      expect(shrinkWorksheetImage(Uint8List.fromList([1, 2, 3])), isNull);
    });
  });

  group('worksheetMetaLine', () {
    test('제목과 태그, 복습 기록을 잇는다', () {
      final problem = ProblemModel(
        problemId: 1,
        reference: ' 6월 모평 21번 ',
        solveCount: 3,
        tags: const [
          TagModel(tagId: 1, name: '미분'),
          TagModel(tagId: 2, name: '극값'),
        ],
      );
      expect(
        worksheetMetaLine(problem, PracticeProblemResult.wrong),
        '6월 모평 21번 · #미분 #극값 · 3번 풀었어요 · 지난번엔 틀렸어요',
      );
    });

    test('다시 푼 적이 없으면 그렇게 적는다', () {
      expect(
        worksheetMetaLine(ProblemModel(problemId: 1), null),
        '아직 다시 안 풀었어요',
      );
    });

    test('태그는 세 개까지만 넣는다', () {
      final problem = ProblemModel(
        problemId: 1,
        solveCount: 1,
        tags: [for (var i = 0; i < 5; i++) TagModel(tagId: i, name: '태그$i')],
      );
      expect(worksheetMetaLine(problem, PracticeProblemResult.unsolved),
          '#태그0 #태그1 #태그2 · 1번 풀었어요');
    });
  });

  group('worksheetFileName', () {
    test('파일 이름에 못 쓰는 글자를 뺀다', () {
      expect(worksheetFileName('수학/과학: 1학기?'), '수학 과학 1학기 학습지.pdf');
    });

    test('이름이 비면 복습 세트로 둔다', () {
      expect(worksheetFileName('  '), '복습 세트 학습지.pdf');
    });
  });
}
