import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 학습지 한 쪽에 문제를 몇 개 놓는지.
enum WorksheetLayout {
  /// 한 쪽에 두 문제. 풀이 칸이 넓다.
  two,

  /// 한 쪽에 네 문제. 두 단으로 나눠 종이를 아낀다.
  four,
}

extension WorksheetLayoutValue on WorksheetLayout {
  int get problemsPerPage => switch (this) {
        WorksheetLayout.two => 2,
        WorksheetLayout.four => 4,
      };

  /// 애널리틱스에 남기는 값.
  String get analyticsName => switch (this) {
        WorksheetLayout.two => 'two',
        WorksheetLayout.four => 'four',
      };
}

/// 내보내기 시트에서 고른 것.
class WorksheetOptions {
  final WorksheetLayout layout;

  /// 맨 뒤에 정답지를 붙인다.
  final bool withAnswers;

  /// 정답지에 내 메모를 넣는다. 정답지가 없으면 뜻이 없다.
  final bool withMemo;

  const WorksheetOptions({
    required this.layout,
    required this.withAnswers,
    required this.withMemo,
  });
}

/// 학습지에 들어갈 문제 하나. 이미지는 미리 받아 줄여 둔 바이트다.
///
/// AI 분석은 넣지 않는다. 출력해서 다시 푸는 종이에는 정답과 내 메모면 된다.
class WorksheetItem {
  /// 번호 옆 한 줄. 제목, 태그, 복습 기록을 이어 붙인 것이다.
  final String meta;
  final Uint8List? problemImage;
  final Uint8List? answerImage;

  final String? memo;

  const WorksheetItem({
    required this.meta,
    this.problemImage,
    this.answerImage,
    this.memo,
  });
}

/// 정답지 한 쪽에 들어가는 줄 수. 줄 높이를 고정해서 쪽수를 미리 셀 수 있다.
const int answerRowsPerPage = 6;

/// 학습지와 정답지를 합친 쪽수. 시트에 미리 보여 주는 값과 실제 PDF 가 같다.
int worksheetPageCount(int problemCount, WorksheetOptions options) {
  if (problemCount <= 0) return 0;
  final sheetPages = (problemCount / options.layout.problemsPerPage).ceil();
  final answerPages =
      options.withAnswers ? (problemCount / answerRowsPerPage).ceil() : 0;
  return sheetPages + answerPages;
}

/// 복습 세트를 다시 풀 학습지 PDF 로 그린다.
///
/// 앱 화면을 찍는 게 아니라 출력용으로 따로 짠다. 카드나 아이콘 상자 없이
/// 시험지처럼 선과 여백만 쓰고, 테마 색은 맨 위 줄과 번호 테두리에만 쓴다.
/// 연핑크 같은 밝은 테마는 흰 종이 위 글자로 쓰면 안 읽혀서 글자에는 안 쓴다.
///
/// 플랫폼 채널을 쓰지 않아서 `Isolate.run` 안에서 불러도 된다.
Future<Uint8List> buildPracticeWorksheetPdf({
  required String title,
  required List<WorksheetItem> items,
  required WorksheetOptions options,
  required Uint8List regularFont,
  required Uint8List boldFont,
  required int accentColor,
}) async {
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(ByteData.sublistView(regularFont)),
    bold: pw.Font.ttf(ByteData.sublistView(boldFont)),
  ).copyWith(
    defaultTextStyle: const pw.TextStyle(fontSize: 9.5, color: _ink),
  );
  final style = _Style(PdfColor.fromInt(accentColor));
  final doc = pw.Document(title: title, author: 'OnO', creator: 'OnO');

  final totalPages = worksheetPageCount(items.length, options);
  final perPage = options.layout.problemsPerPage;
  var pageNumber = 0;

  for (var start = 0; start < items.length; start += perPage) {
    pageNumber++;
    final pageItems = items.skip(start).take(perPage).toList();
    final first = start == 0;
    final number = pageNumber;
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: options.layout == WorksheetLayout.two
          ? const pw.EdgeInsets.fromLTRB(48, 39, 48, 30)
          : const pw.EdgeInsets.fromLTRB(42, 39, 42, 30),
      build: (context) => pw.Column(
        children: [
          _sheetHeader(style, title, items.length, first: first),
          pw.SizedBox(height: 16),
          pw.Expanded(
            child: options.layout == WorksheetLayout.two
                ? _twoUp(style, pageItems, start)
                : _fourUp(style, pageItems, start),
          ),
          pw.SizedBox(height: 10),
          _footer(number, totalPages),
        ],
      ),
    ));
  }

  if (options.withAnswers) {
    for (var start = 0; start < items.length; start += answerRowsPerPage) {
      pageNumber++;
      final rows = items.skip(start).take(answerRowsPerPage).toList();
      final number = pageNumber;
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(48, 39, 48, 30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _answerHeader(style, title),
            pw.SizedBox(height: 14),
            _answerColumnLabels(options.withMemo),
            pw.Expanded(
              child: pw.Column(
                children: [
                  for (var i = 0; i < answerRowsPerPage; i++)
                    pw.Expanded(
                      child: i < rows.length
                          ? _answerRow(style, rows[i], start + i + 1,
                              withMemo: options.withMemo)
                          : pw.SizedBox(),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            _footer(number, totalPages),
          ],
        ),
      ));
    }
  }

  return doc.save();
}

// ==================== 색과 공통 조각 ====================

const _ink = PdfColor.fromInt(0xFF1D1D1F);
const _inkSoft = PdfColor.fromInt(0xFF4A4A4A);
const _muted = PdfColor.fromInt(0xFF6B6B6B);
const _faint = PdfColor.fromInt(0xFF8A8A8A);
const _line = PdfColor.fromInt(0xFFE4E4E4);
const _box = PdfColor.fromInt(0xFFD6D6D6);
const _dot = PdfColor.fromInt(0xFFC4C4C4);
const _writeLine = PdfColor.fromInt(0xFF8A8A8A);

class _Style {
  final PdfColor accent;
  const _Style(this.accent);
}

pw.Widget _blank(String label, double width, {String? suffix}) {
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
      pw.SizedBox(width: 4),
      pw.Container(
        width: width,
        height: 11,
        decoration: const pw.BoxDecoration(
          border:
              pw.Border(bottom: pw.BorderSide(color: _writeLine, width: 0.75)),
        ),
      ),
      if (suffix != null) ...[
        pw.SizedBox(width: 3),
        pw.Text(suffix,
            style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
      ],
    ],
  );
}

pw.Widget _numberBox(_Style style, int number, {double size = 22}) {
  return pw.Container(
    width: size,
    height: size,
    alignment: pw.Alignment.center,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: style.accent, width: 1.5),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Text(
      '$number',
      style: pw.TextStyle(
        fontSize: size >= 22 ? 12 : 10.5,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

pw.Widget _accentRule(_Style style) {
  return pw.Container(height: 2.25, color: style.accent);
}

pw.Widget _footer(int page, int total) {
  const small = pw.TextStyle(fontSize: 8.25, color: _muted);
  return pw.Container(
    padding: const pw.EdgeInsets.only(top: 7),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _line, width: 0.75)),
    ),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            'OnO',
            style: pw.TextStyle(
              fontSize: 8.25,
              color: _inkSoft,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text('$page / $total',
              style: small, textAlign: pw.TextAlign.center),
        ),
        // 쪽 번호가 가운데 오도록 오른쪽 칸을 비워 둔다.
        pw.Expanded(child: pw.SizedBox()),
      ],
    ),
  );
}

/// 사진을 테두리 안에 비율대로 넣는다. 사진이 없으면 그렇다고 적는다.
pw.Widget _photo(Uint8List? bytes, String emptyText, {double padding = 6}) {
  return pw.Container(
    padding: pw.EdgeInsets.all(padding),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _box, width: 0.75),
      borderRadius: pw.BorderRadius.circular(3),
    ),
    child: bytes == null
        ? pw.Center(
            child: pw.Text(emptyText,
                style: const pw.TextStyle(fontSize: 8.5, color: _faint)),
          )
        // Image 의 alignment 는 칸을 꽉 채운 뒤 그 안에서 맞추는데, 가로 사진이
        // 칸 아래쪽에 붙어 나왔다. Align 이 먼저 크기를 정하게 해서 가운데 둔다.
        : pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
          ),
  );
}

pw.Widget _checkBox(String label, {double size = 8}) {
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Container(
        width: size,
        height: size,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _muted, width: 0.75),
        ),
      ),
      pw.SizedBox(width: 3.5),
      pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
    ],
  );
}

pw.Widget _metaRow(_Style style, int number, String meta,
    {double boxSize = 22}) {
  return pw.Row(
    children: [
      _numberBox(style, number, size: boxSize),
      pw.SizedBox(width: 9),
      pw.Expanded(
        // 네 문제 배치는 칸이 좁아 한 줄이면 '지난번엔' 에서 잘린다.
        child: pw.Text(
          meta,
          maxLines: 2,
          overflow: pw.TextOverflow.clip,
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        ),
      ),
    ],
  );
}

// ==================== 학습지 ====================

pw.Widget _sheetHeader(_Style style, String title, int count,
    {required bool first}) {
  if (!first) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Text(
                title,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Text('오답 학습지',
                style: const pw.TextStyle(fontSize: 9, color: _muted)),
          ],
        ),
        pw.SizedBox(height: 7),
        _accentRule(style),
      ],
    );
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('오답 학습지 · $count문제',
                    style: const pw.TextStyle(fontSize: 9, color: _muted)),
                pw.SizedBox(height: 4),
                pw.Text(
                  title,
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                      fontSize: 19, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          _blank('이름', 62),
          pw.SizedBox(width: 12),
          _blank('날짜', 46),
          pw.SizedBox(width: 12),
          _blank('맞힌 수', 22, suffix: '/ $count'),
        ],
      ),
      pw.SizedBox(height: 10),
      _accentRule(style),
    ],
  );
}

/// 점 격자 풀이 칸. 줄 공책보다 식과 그림을 같이 쓰기 좋다.
pw.Widget _dotGrid({String? label}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _line, width: 0.75),
      borderRadius: pw.BorderRadius.circular(3),
    ),
    child: pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.CustomPaint(
            painter: (canvas, size) {
              const step = 12.0;
              canvas.setFillColor(_dot);
              for (var x = step / 2; x < size.x; x += step) {
                for (var y = step / 2; y < size.y; y += step) {
                  canvas.drawEllipse(x, y, 0.55, 0.55);
                }
              }
              canvas.fillPath();
            },
            child: pw.SizedBox.expand(),
          ),
        ),
        if (label != null)
          pw.Positioned(
            left: 6,
            top: 5,
            child: pw.Container(
              color: PdfColors.white,
              padding: const pw.EdgeInsets.symmetric(horizontal: 3),
              child: pw.Text(label,
                  style: const pw.TextStyle(fontSize: 8.25, color: _faint)),
            ),
          ),
      ],
    ),
  );
}

pw.Widget _answerLine(String answerLabel, double width, List<String> checks) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      _blank(answerLabel, width),
      pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          for (var i = 0; i < checks.length; i++) ...[
            if (i > 0) pw.SizedBox(width: 10),
            _checkBox(checks[i]),
          ],
        ],
      ),
    ],
  );
}

pw.Widget _twoUp(_Style style, List<WorksheetItem> items, int offset) {
  pw.Widget cell(int index) {
    final item = items[index];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _metaRow(style, offset + index + 1, item.meta),
        pw.SizedBox(height: 8),
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.SizedBox(
                width: 255,
                child: _photo(item.problemImage, '문제 사진이 없어요', padding: 8),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(child: _dotGrid(label: '풀이')),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        _answerLine('답', 90, const ['맞았어요', '헷갈려요', '또 틀렸어요']),
      ],
    );
  }

  return pw.Column(
    children: [
      pw.Expanded(child: cell(0)),
      pw.SizedBox(height: 14),
      // 마지막 쪽에 문제가 하나뿐이어도 칸 크기는 다른 쪽과 같게 둔다.
      if (items.length > 1) ...[
        pw.Container(height: 0.75, color: _line),
        pw.SizedBox(height: 14),
        pw.Expanded(child: cell(1)),
      ] else
        pw.Expanded(child: pw.SizedBox()),
    ],
  );
}

pw.Widget _fourUp(_Style style, List<WorksheetItem> items, int offset) {
  pw.Widget cell(int index) {
    final left = index.isEven;
    final top = index < 2;
    final border = pw.Border(
      right: left
          ? const pw.BorderSide(color: _line, width: 0.75)
          : pw.BorderSide.none,
      bottom: top
          ? const pw.BorderSide(color: _line, width: 0.75)
          : pw.BorderSide.none,
    );
    final padding = pw.EdgeInsets.fromLTRB(
      left ? 0 : 15,
      top ? 0 : 15,
      left ? 15 : 0,
      top ? 15 : 0,
    );
    if (index >= items.length) {
      return pw.Container(decoration: pw.BoxDecoration(border: border));
    }

    final item = items[index];
    return pw.Container(
      padding: padding,
      decoration: pw.BoxDecoration(border: border),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _metaRow(style, offset + index + 1, item.meta, boxSize: 19),
          pw.SizedBox(height: 7),
          pw.Expanded(
            flex: 5,
            child: _photo(item.problemImage, '문제 사진이 없어요'),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < 4; i++)
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: _box,
                          width: 0.75,
                          style: pw.BorderStyle.dashed,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _answerLine('답', 52, const ['맞음', '헷갈림', '틀림']),
        ],
      ),
    );
  }

  return pw.Column(
    children: [
      for (var row = 0; row < 2; row++)
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Expanded(child: cell(row * 2)),
              pw.Expanded(child: cell(row * 2 + 1)),
            ],
          ),
        ),
    ],
  );
}

// ==================== 정답지 ====================

const double _answerNumberWidth = 30;
const double _answerMemoWidth = 190;
const double _answerGap = 13;

pw.Widget _answerHeader(_Style style, String title) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: const pw.TextStyle(fontSize: 9, color: _muted),
                ),
                pw.SizedBox(height: 4),
                pw.Text('정답지',
                    style: pw.TextStyle(
                        fontSize: 19, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.Text('다 풀고 나서 맞춰 보세요',
              style: const pw.TextStyle(fontSize: 9, color: _muted)),
        ],
      ),
      pw.SizedBox(height: 10),
      _accentRule(style),
    ],
  );
}

pw.Widget _answerColumnLabels(bool withMemo) {
  const label = pw.TextStyle(fontSize: 8.25, color: _muted);
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _box, width: 0.75)),
    ),
    child: pw.Row(
      children: [
        pw.SizedBox(
            width: _answerNumberWidth, child: pw.Text('번호', style: label)),
        pw.SizedBox(width: _answerGap),
        pw.Expanded(child: pw.Text('정답', style: label)),
        if (withMemo) ...[
          pw.SizedBox(width: _answerGap),
          pw.SizedBox(
              width: _answerMemoWidth, child: pw.Text('내 메모', style: label)),
        ],
      ],
    ),
  );
}

pw.Widget _answerRow(_Style style, WorksheetItem item, int number,
    {required bool withMemo}) {
  final memo = item.memo?.trim() ?? '';

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 9),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.75)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: _answerNumberWidth,
          child: pw.Align(
            alignment: pw.Alignment.topLeft,
            child: _numberBox(style, number, size: 19),
          ),
        ),
        pw.SizedBox(width: _answerGap),
        pw.Expanded(
          child: _photo(item.answerImage, '정답 사진이 없어요', padding: 4),
        ),
        if (withMemo) ...[
          pw.SizedBox(width: _answerGap),
          pw.SizedBox(
            width: _answerMemoWidth,
            child: pw.Text(
              memo.isEmpty ? '-' : memo,
              maxLines: 6,
              overflow: pw.TextOverflow.clip,
              style: const pw.TextStyle(
                  fontSize: 9, color: _inkSoft, lineSpacing: 2),
            ),
          ),
        ],
      ],
    ),
  );
}
