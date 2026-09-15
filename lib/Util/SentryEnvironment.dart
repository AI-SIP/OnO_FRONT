/// Sentry 에 실어 보내는 environment 이름을 정한다.
///
/// Sentry 기본값은 빌드 모드만 본다. 릴리즈 빌드면 전부 `production` 이라
/// `--dart-define=ENV=dev` 로 뽑은 개발 서버 빌드도 운영 에러에 섞였다.
/// 여기서는 빌드 모드와 `ENV` 를 같이 본다.
///
/// | 빌드 | ENV | environment |
/// |---|---|---|
/// | release | prod | `production` |
/// | release | dev | `dev` |
/// | release | local | `local` |
/// | profile | 무관 | `profile` |
/// | debug | 무관 | `debug` |
///
/// 운영을 `prod` 가 아니라 `production` 으로 두는 것은, 이미 쌓인 이벤트와
/// Sentry 화면에 저장해 둔 필터가 `production` 으로 되어 있어서다.
///
/// 디버그 실행은 `ENV=prod` 로 띄워도 `debug` 다. 운영 서버를 붙여 로컬에서
/// 확인하다 난 에러가 운영 사용자 에러로 세어지면 안 된다.
class SentryEnvironment {
  const SentryEnvironment._();

  static String resolve({
    required String appEnv,
    required bool isReleaseMode,
    required bool isProfileMode,
  }) {
    if (isProfileMode) return 'profile';
    if (!isReleaseMode) return 'debug';

    switch (appEnv) {
      case 'prod':
        return 'production';
      case '':
        return 'local';
      default:
        // dev, local, 그리고 오타까지 그대로 보낸다. 오타가 나면 Sentry 에서
        // 낯선 environment 로 바로 보여서 알아챌 수 있다.
        return appEnv;
    }
  }
}
