import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/ProblemAnalysisModel.dart';
import 'package:ono/Model/Problem/ProblemAnalysisStatus.dart';

void main() {
  group('ProblemAnalysisModel.fromJson', () {
    test('모든 필드가 채워진 정상 응답을 파싱한다', () {
      final json = {
        'id': 1,
        'problemId': 7,
        'subject': '수학',
        'problemType': '이차방정식',
        'keyPoints': ['판별식', '근의 공식'],
        'solution': '근의 공식을 이용해 푼다',
        'commonMistakes': '부호 실수',
        'studyTips': '판별식부터 확인하자',
        'status': 'COMPLETED',
        'errorMessage': null,
      };

      final model = ProblemAnalysisModel.fromJson(json);

      expect(model.id, 1);
      expect(model.problemId, 7);
      expect(model.subject, '수학');
      expect(model.problemType, '이차방정식');
      expect(model.keyPoints, ['판별식', '근의 공식']);
      expect(model.solution, '근의 공식을 이용해 푼다');
      expect(model.commonMistakes, '부호 실수');
      expect(model.studyTips, '판별식부터 확인하자');
      expect(model.status, ProblemAnalysisStatus.COMPLETED);
      expect(model.errorMessage, isNull);
    });

    test('nullable 필드가 전부 null 이어도 파싱된다', () {
      final json = {
        'id': null,
        'problemId': null,
        'subject': null,
        'problemType': null,
        'keyPoints': null,
        'solution': null,
        'commonMistakes': null,
        'studyTips': null,
        'status': null,
        'errorMessage': null,
      };

      final model = ProblemAnalysisModel.fromJson(json);

      expect(model.id, isNull);
      expect(model.problemId, isNull);
      expect(model.keyPoints, isNull);
      expect(model.status, isNull);
    });

    test('키가 아예 빠져 있어도 전부 null 로 떨어진다', () {
      final model = ProblemAnalysisModel.fromJson({});

      expect(model.id, isNull);
      expect(model.problemId, isNull);
      expect(model.subject, isNull);
      expect(model.keyPoints, isNull);
      expect(model.status, isNull);
      expect(model.errorMessage, isNull);
    });

    test('keyPoints 가 빈 배열이면 빈 리스트로 파싱된다', () {
      final model = ProblemAnalysisModel.fromJson({'keyPoints': <String>[]});

      expect(model.keyPoints, isEmpty);
    });

    test('status 에 서버가 모르는 값이 오면 null 로 떨어진다 (예외 없음)', () {
      final model = ProblemAnalysisModel.fromJson({'status': 'ALIEN_STATUS'});

      expect(model.status, isNull);
    });

    test('failed 상태와 errorMessage 를 함께 파싱한다', () {
      final model = ProblemAnalysisModel.fromJson({
        'status': 'FAILED',
        'errorMessage': 'AI 분석 서버 응답 시간 초과',
      });

      expect(model.status, ProblemAnalysisStatus.FAILED);
      expect(model.errorMessage, 'AI 분석 서버 응답 시간 초과');
    });
  });

  group('ProblemAnalysisModel.toJson', () {
    test('서버가 받는 키 이름으로 정확히 직렬화된다', () {
      final model = ProblemAnalysisModel(
        id: 1,
        problemId: 7,
        subject: '수학',
        problemType: '이차방정식',
        keyPoints: const ['판별식'],
        solution: '근의 공식',
        commonMistakes: '부호 실수',
        studyTips: '판별식부터',
        status: ProblemAnalysisStatus.COMPLETED,
        errorMessage: null,
      );

      expect(model.toJson(), {
        'id': 1,
        'problemId': 7,
        'subject': '수학',
        'problemType': '이차방정식',
        'keyPoints': ['판별식'],
        'solution': '근의 공식',
        'commonMistakes': '부호 실수',
        'studyTips': '판별식부터',
        'status': 'COMPLETED',
        'errorMessage': null,
      });
    });

    test('status 가 null 이면 toJson 에서도 null 이다', () {
      final model = ProblemAnalysisModel();

      expect(model.toJson()['status'], isNull);
    });

    test('round-trip: fromJson 한 것을 다시 toJson 하면 원래 값으로 돌아온다', () {
      final original = {
        'id': 3,
        'problemId': 9,
        'subject': '영어',
        'problemType': '독해',
        'keyPoints': ['주제문 찾기'],
        'solution': '지문 구조를 먼저 파악한다',
        'commonMistakes': '보기만 보고 판단',
        'studyTips': '지문을 두 번 읽자',
        'status': 'PROCESSING',
        'errorMessage': null,
      };

      final roundTripped = ProblemAnalysisModel.fromJson(original).toJson();

      expect(roundTripped, original);
    });
  });
}
