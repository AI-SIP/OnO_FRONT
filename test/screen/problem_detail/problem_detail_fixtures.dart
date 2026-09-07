// ProblemDetail 테스트 전용 fixture 빌더 모음.
//
// test/helpers/ 는 다른 작업자와 공유하는 영역이라 손대지 않는다. 이 디렉토리
// 안에서만 쓰는 ProblemModel 조립은 여기 모아 둔다. `_test.dart` 로 끝나지
// 않으므로 flutter test 가 테스트 파일로 인식하지 않는다.

import 'package:ono/Model/Common/ProblemImageDataType.dart';
import 'package:ono/Model/Problem/ProblemAnalysisModel.dart';
import 'package:ono/Model/Problem/ProblemAnalysisStatus.dart';
import 'package:ono/Model/Problem/ProblemImageDataModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Model/Tag/TagModel.dart';

/// 이미지 한 장을 만든다.
ProblemImageDataModel buildImageData(
  String url, {
  ProblemImageType type = ProblemImageType.PROBLEM_IMAGE,
}) =>
    ProblemImageDataModel(
      imageUrl: url,
      problemImageType: type,
      createdAt: DateTime(2026, 1, 1),
    );

/// 테스트용 ProblemModel. 기본값만으로도 화면이 그려질 수 있게
/// solvedAt 은 항상 채워 둔다 (화면 여러 곳에서 `solvedAt!` 으로 접근한다).
ProblemModel buildProblem({
  int problemId = 1,
  DateTime? solvedAt,
  String? memo,
  String? reference,
  List<ProblemImageDataModel> problemImages = const [],
  List<ProblemImageDataModel> answerImages = const [],
  List<ProblemImageDataModel> solveImages = const [],
  ProblemAnalysisModel? analysis,
  List<TagModel> tags = const [],
}) {
  return ProblemModel(
    problemId: problemId,
    solvedAt: solvedAt ?? DateTime(2026, 3, 2),
    memo: memo,
    reference: reference,
    problemImageDataList: problemImages,
    answerImageDataList: answerImages,
    solveImageDataList: solveImages,
    analysis: analysis,
    tags: tags,
  );
}

ProblemAnalysisModel buildAnalysis({
  ProblemAnalysisStatus? status = ProblemAnalysisStatus.COMPLETED,
  String? subject = '수학',
  String? problemType = '이차방정식',
  List<String>? keyPoints = const ['판별식', '근의 공식'],
  String? solution = '판별식을 이용해 근의 개수를 구한다.',
  String? commonMistakes = '부호를 놓치기 쉽다.',
  String? studyTips = '기본 공식을 암기해두자.',
  String? errorMessage,
}) {
  return ProblemAnalysisModel(
    status: status,
    subject: subject,
    problemType: problemType,
    keyPoints: keyPoints,
    solution: solution,
    commonMistakes: commonMistakes,
    studyTips: studyTips,
    errorMessage: errorMessage,
  );
}
