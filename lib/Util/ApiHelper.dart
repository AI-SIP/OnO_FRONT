import 'package:flutter/material.dart';
import '../Exception/ApiException.dart';
import 'AppErrorReporter.dart';

/// API 호출을 위한 공통 헬퍼 클래스
/// 모든 API 호출에서 일관된 에러 처리와 사용자 피드백을 제공합니다.
class ApiHelper {
  /// API 호출을 래핑하여 자동으로 에러 처리를 수행합니다.
  ///
  /// [context]: SnackBar를 표시하기 위한 BuildContext
  /// [apiCall]: 실행할 API 호출 함수
  /// [successMessage]: 성공 시 표시할 메시지 (null이면 표시 안함)
  /// [showErrorSnackBar]: 에러 발생 시 SnackBar 표시 여부 (기본: true)
  /// [onError]: 에러 발생 시 추가로 실행할 콜백 (선택)
  ///
  /// 사용 예시:
  /// ```dart
  /// await ApiHelper.call(
  ///   context,
  ///   () => userService.fetchUserInfo(),
  ///   successMessage: '프로필을 불러왔습니다',
  /// );
  /// ```
  static Future<T?> call<T>(
    BuildContext context,
    Future<T> Function() apiCall, {
    String? successMessage,
    bool showErrorSnackBar = true,
    void Function(dynamic error)? onError,
    String source = 'api_helper',
    AppErrorSeverity severity = AppErrorSeverity.error,
    bool sendToDiscord = true,
  }) async {
    try {
      final result = await apiCall();

      // 성공 메시지 표시
      if (successMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return result;
    } catch (e, stackTrace) {
      final messenger = context.mounted ? ScaffoldMessenger.of(context) : null;
      await _handleError(
        messenger,
        e,
        stackTrace,
        showErrorSnackBar: showErrorSnackBar,
        source: source,
        severity: severity,
        sendToDiscord: sendToDiscord,
      );
      onError?.call(e);
    }

    return null;
  }

  /// API 호출을 래핑하되, 에러를 다시 던집니다.
  /// 에러 메시지는 자동으로 표시하지만, 호출한 곳에서 추가 처리가 필요한 경우 사용합니다.
  ///
  /// [context]: SnackBar를 표시하기 위한 BuildContext
  /// [apiCall]: 실행할 API 호출 함수
  /// [successMessage]: 성공 시 표시할 메시지 (null이면 표시 안함)
  /// [showErrorSnackBar]: 에러 발생 시 SnackBar 표시 여부 (기본: true)
  ///
  /// 사용 예시:
  /// ```dart
  /// try {
  ///   await ApiHelper.callAndThrow(
  ///     context,
  ///     () => userService.deleteAccount(),
  ///   );
  ///   // 성공 시 추가 처리
  ///   Navigator.pop(context);
  /// } on BadRequestException catch (e) {
  ///   // 특정 에러에 대한 추가 처리
  ///   if (e.errorCode == 4003) {
  ///     // 특별한 처리
  ///   }
  /// }
  /// ```
  static Future<T> callAndThrow<T>(
    BuildContext context,
    Future<T> Function() apiCall, {
    String? successMessage,
    bool showErrorSnackBar = true,
    String source = 'api_helper',
    AppErrorSeverity severity = AppErrorSeverity.error,
    bool sendToDiscord = true,
  }) async {
    try {
      final result = await apiCall();

      // 성공 메시지 표시
      if (successMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return result;
    } catch (e, stackTrace) {
      final messenger = context.mounted ? ScaffoldMessenger.of(context) : null;
      await _handleError(
        messenger,
        e,
        stackTrace,
        showErrorSnackBar: showErrorSnackBar,
        source: source,
        severity: severity,
        sendToDiscord: sendToDiscord,
      );
      rethrow;
    }
  }

  /// 로딩 인디케이터와 함께 API를 호출합니다.
  ///
  /// [context]: BuildContext
  /// [apiCall]: 실행할 API 호출 함수
  /// [successMessage]: 성공 시 표시할 메시지
  /// [loadingMessage]: 로딩 중 표시할 메시지 (기본: "처리 중...")
  ///
  /// 사용 예시:
  /// ```dart
  /// await ApiHelper.callWithLoading(
  ///   context,
  ///   () => problemService.deleteProblems(ids),
  ///   successMessage: '삭제되었습니다',
  ///   loadingMessage: '삭제 중...',
  /// );
  /// ```
  static Future<T?> callWithLoading<T>(
    BuildContext context,
    Future<T> Function() apiCall, {
    String? successMessage,
    String loadingMessage = '처리 중...',
    String source = 'api_helper',
    AppErrorSeverity severity = AppErrorSeverity.error,
    bool sendToDiscord = true,
  }) async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(loadingMessage),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final result = await call(
        context,
        apiCall,
        successMessage: successMessage,
        source: source,
        severity: severity,
        sendToDiscord: sendToDiscord,
      );

      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      return result;
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      rethrow;
    }
  }

  static Future<void> _handleError(
    ScaffoldMessengerState? messenger,
    Object error,
    StackTrace stackTrace, {
    required bool showErrorSnackBar,
    required String source,
    required AppErrorSeverity severity,
    required bool sendToDiscord,
  }) async {
    await AppErrorReporter.report(
      error,
      stackTrace,
      source: source,
      severity: severity,
      sendToDiscord: sendToDiscord,
    );

    if (showErrorSnackBar && messenger != null) {
      final presentation = _errorPresentation(error);
      messenger.showSnackBar(
        SnackBar(
          content: Text(presentation.message),
          backgroundColor: presentation.backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static _ErrorPresentation _errorPresentation(Object error) {
    if (error is NetworkException) {
      return _ErrorPresentation(error.getUserMessage(), Colors.orange);
    }
    if (error is TimeoutException) {
      return _ErrorPresentation(error.getUserMessage(), Colors.orange);
    }
    if (error is BadRequestException) {
      return _ErrorPresentation(error.getUserMessage(), Colors.orange);
    }
    if (error is UnauthorizedException) {
      return _ErrorPresentation(error.getUserMessage(), Colors.red);
    }
    if (error is ServerException) {
      return _ErrorPresentation(error.getUserMessage(), Colors.red);
    }
    if (error is ApiException) {
      return _ErrorPresentation(error.getUserMessage(), Colors.red);
    }

    return const _ErrorPresentation('알 수 없는 오류가 발생했습니다.', Colors.red);
  }
}

class _ErrorPresentation {
  final String message;
  final Color backgroundColor;

  const _ErrorPresentation(this.message, this.backgroundColor);
}
