import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../Model/Problem/ProblemImageDataModel.dart';
import '../../Model/Problem/ProblemModel.dart';
import '../../Screen/PracticeNote/PracticeSetAnalysis.dart';
import 'PracticeWorksheetPdf.dart';

/// 만든 PDF 파일과 애널리틱스에 남길 값.
class PracticePdfResult {
  final File file;
  final int pageCount;

  /// 받지 못해 빈칸으로 둔 사진 수.
  final int failedImageCount;

  const PracticePdfResult({
    required this.file,
    required this.pageCount,
    required this.failedImageCount,
  });
}

/// 복습 세트의 문제를 받아 학습지 PDF 파일을 만든다.
///
/// 사진은 원본 그대로 넣으면 문제 수십 개짜리 세트에서 PDF 가 수십 MB 가 되고
/// 메모리도 많이 먹어서, 받는 대로 긴 변을 [_maxImageSide] 로 줄여 JPEG 로
/// 다시 담는다. A4 반쪽 칸에 인쇄해도 글자가 뭉개지지 않는 크기다.
class PracticePdfExporter {
  static const int _maxImageSide = 1400;
  static const int _jpegQuality = 82;
  static const int _downloadConcurrency = 4;
  static const Duration _downloadTimeout = Duration(seconds: 20);

  final http.Client _client;

  PracticePdfExporter({http.Client? client})
      : _client = client ?? http.Client();

  Future<PracticePdfResult> export({
    required String title,
    required List<ProblemModel> problems,
    required WorksheetOptions options,
    required Color accentColor,
    PracticeSetAnalysis? analysis,
  }) async {
    final fonts = await Future.wait([
      rootBundle.load('assets/fonts/pdf/Pretendard-Regular.ttf'),
      rootBundle.load('assets/fonts/pdf/Pretendard-Bold.ttf'),
    ]);

    var failed = 0;
    final problemImages = <int, Uint8List?>{};
    final answerImages = <int, Uint8List?>{};

    // 정답지를 안 붙이면 정답 사진은 받을 필요가 없다.
    final jobs = <({int problemId, String url, bool answer})>[
      for (final problem in problems) ...[
        if (_firstUrl(problem.problemImageDataList) case final url?)
          (problemId: problem.problemId, url: url, answer: false),
        if (options.withAnswers)
          if (_firstUrl(problem.answerImageDataList) case final url?)
            (problemId: problem.problemId, url: url, answer: true),
      ],
    ];

    for (var start = 0; start < jobs.length; start += _downloadConcurrency) {
      final batch = jobs.skip(start).take(_downloadConcurrency);
      await Future.wait(batch.map((job) async {
        final bytes = await _loadImage(job.url);
        if (bytes == null) failed++;
        (job.answer ? answerImages : problemImages)[job.problemId] = bytes;
      }));
    }

    final items = [
      for (final problem in problems)
        WorksheetItem(
          meta: worksheetMetaLine(
            problem,
            analysis?.resultOf(problem.problemId),
          ),
          problemImage: problemImages[problem.problemId],
          answerImage: answerImages[problem.problemId],
          keyPoints: problem.analysis?.keyPoints,
          memo: options.withMemo ? problem.memo : null,
        ),
    ];

    final bytes = await _renderInIsolate(
      title: title,
      items: items,
      options: options,
      regularFont: fonts[0].buffer.asUint8List(),
      boldFont: fonts[1].buffer.asUint8List(),
      accentColor: accentColor.toARGB32(),
    );

    final dir = Directory('${(await getTemporaryDirectory()).path}/ono_pdf');
    if (await dir.exists()) {
      // 지난번에 공유한 파일은 공유 창이 닫힌 뒤라 지워도 된다.
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
    final file = File('${dir.path}/${worksheetFileName(title)}');
    await file.writeAsBytes(bytes, flush: true);

    return PracticePdfResult(
      file: file,
      pageCount: worksheetPageCount(problems.length, options),
      failedImageCount: failed,
    );
  }

  String? _firstUrl(List<ProblemImageDataModel>? images) {
    if (images == null || images.isEmpty) return null;
    final url = images.first.imageUrl;
    return url.isEmpty ? null : url;
  }

  Future<Uint8List?> _loadImage(String url) async {
    try {
      final response =
          await _client.get(Uri.parse(url)).timeout(_downloadTimeout);
      if (response.statusCode != 200) {
        debugPrint('[PracticePdfExporter] 사진을 못 받음 ${response.statusCode}');
        return null;
      }
      return await compute(shrinkWorksheetImage, response.bodyBytes);
    } catch (e) {
      // 한 장 못 받았다고 PDF 를 포기하지 않는다. 그 칸만 비워 둔다.
      debugPrint('[PracticePdfExporter] 사진을 못 받음: $e');
      return null;
    }
  }
}

/// 사진 수십 장을 담는 동안 로딩 애니메이션이 멈추지 않게 따로 그린다.
///
/// 클로저가 넘기는 값만 들고 가도록 최상위 함수로 둔다. [PracticePdfExporter]
/// 안에서 만들면 `http.Client` 를 든 `this` 까지 따라가서 보낼 수 없다.
Future<Uint8List> _renderInIsolate({
  required String title,
  required List<WorksheetItem> items,
  required WorksheetOptions options,
  required Uint8List regularFont,
  required Uint8List boldFont,
  required int accentColor,
}) {
  return Isolate.run(() => buildPracticeWorksheetPdf(
        title: title,
        items: items,
        options: options,
        regularFont: regularFont,
        boldFont: boldFont,
        accentColor: accentColor,
      ));
}

/// 사진을 PDF 에 넣을 크기로 줄인다. 읽을 수 없는 그림이면 null 이다.
///
/// 휴대폰 사진은 회전 정보만 달고 픽셀은 누운 채로 오는 일이 많아서, 회전을
/// 먼저 픽셀에 반영한다. 안 그러면 PDF 에서 문제가 옆으로 눕는다.
Uint8List? shrinkWorksheetImage(Uint8List bytes) {
  // 깨진 바이트를 받으면 null 대신 예외를 던지는 디코더가 있다.
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;
  var image = img.bakeOrientation(decoded);
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > PracticePdfExporter._maxImageSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: PracticePdfExporter._maxImageSide)
        : img.copyResize(image, height: PracticePdfExporter._maxImageSide);
  }
  // 투명한 PNG 를 JPEG 로 바꾸면 투명한 곳이 검게 된다. 흰 종이 위에 올린다.
  if (image.hasAlpha) {
    final flat = img.Image(width: image.width, height: image.height)
      ..clear(img.ColorRgb8(255, 255, 255));
    image = img.compositeImage(flat, image);
  }
  return img.encodeJpg(image, quality: PracticePdfExporter._jpegQuality);
}

/// 번호 옆에 붙는 한 줄. 제목, 태그, 복습 기록을 이어 붙인다.
String worksheetMetaLine(ProblemModel problem, PracticeProblemResult? result) {
  final parts = <String>[];

  final reference = problem.reference?.trim() ?? '';
  if (reference.isNotEmpty) parts.add(reference);

  final tags = problem.tags
      .map((tag) => tag.name.trim())
      .where((name) => name.isNotEmpty)
      .take(3)
      .map((name) => '#$name')
      .join(' ');
  if (tags.isNotEmpty) parts.add(tags);

  if (problem.solveCount <= 0) {
    parts.add('아직 다시 안 풀었어요');
  } else {
    final last = switch (result) {
      PracticeProblemResult.correct => ' · 지난번엔 맞혔어요',
      PracticeProblemResult.partial => ' · 지난번엔 헷갈렸어요',
      PracticeProblemResult.wrong => ' · 지난번엔 틀렸어요',
      _ => '',
    };
    parts.add('${problem.solveCount}번 풀었어요$last');
  }

  return parts.join(' · ');
}

/// 공유 창에 보이는 파일 이름. 파일 시스템이 못 쓰는 글자는 뺀다.
String worksheetFileName(String title) {
  final safe = title
      .replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final name = safe.isEmpty ? '복습 세트' : safe;
  final short = name.length > 40 ? name.substring(0, 40).trim() : name;
  return '$short 학습지.pdf';
}
