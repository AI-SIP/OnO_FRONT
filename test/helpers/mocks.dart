import 'package:mocktail/mocktail.dart';
import 'package:ono/Provider/TokenProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Service/Api/FileUpload/FileUploadService.dart';
import 'package:ono/Service/Api/Folder/FolderService.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:ono/Service/Api/LearningReport/LearningReportService.dart';
import 'package:ono/Service/Api/PracticeNote/PracticeNoteService.dart';
import 'package:ono/Service/Api/Problem/ProblemService.dart';
import 'package:ono/Service/Api/Problem/ProblemSolveService.dart';
import 'package:ono/Service/Api/StudyCalendar/StudyCalendarService.dart';
import 'package:ono/Service/Api/StudyRoom/StudyRoomService.dart';
import 'package:ono/Service/Api/Tag/TagService.dart';
import 'package:ono/Service/Api/User/UserService.dart';

// ─────────────────────────────────────────────────────────────
// Provider 테스트에서 Service 를 대신할 mock 들.
// Service 테스트에서는 mock 대신 TestHttpClient 로 진짜 HttpService 를 태운다.
// 그래야 URL·헤더·바디까지 같이 검증된다.
// ─────────────────────────────────────────────────────────────

class MockHttpService extends Mock implements HttpService {}

class MockTokenProvider extends Mock implements TokenProvider {}

class MockProblemService extends Mock implements ProblemService {}

class MockProblemSolveService extends Mock implements ProblemSolveService {}

class MockFolderService extends Mock implements FolderService {}

class MockFileUploadService extends Mock implements FileUploadService {}

class MockPracticeNoteService extends Mock implements PracticeNoteService {}

class MockStudyRoomService extends Mock implements StudyRoomService {}

class MockStudyCalendarService extends Mock implements StudyCalendarService {}

class MockLearningReportService extends Mock implements LearningReportService {}

class MockTagService extends Mock implements TagService {}

class MockUserService extends Mock implements UserService {}

class MockProblemsProvider extends Mock implements ProblemsProvider {}

/// 토큰이 항상 있는 TokenProvider.
/// [accessToken] 을 null 로 주면 "토큰 없음" 상황이 되어
/// HttpService 가 UnauthorizedException 을 던지는 경로를 볼 수 있다.
MockTokenProvider buildMockTokenProvider({
  String? accessToken = 'test-access-token',
}) {
  final tokenProvider = MockTokenProvider();
  when(() => tokenProvider.getAccessToken())
      .thenAnswer((_) async => accessToken);
  when(() => tokenProvider.refreshAccessToken()).thenAnswer((_) async {});
  when(() => tokenProvider.notifyAuthFailure()).thenAnswer((_) async {});
  return tokenProvider;
}

/// ChangeNotifier 가 몇 번 알렸는지 세는 리스너.
///
/// ```dart
/// final notified = NotifyRecorder();
/// provider.addListener(notified.call);
/// await provider.fetchSomething();
/// expect(notified.count, 2); // 로딩 시작 / 완료
/// ```
class NotifyRecorder {
  int count = 0;

  void call() => count++;

  void reset() => count = 0;
}
