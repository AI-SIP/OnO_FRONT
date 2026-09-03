import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

import '../Model/User/UserInfoModel.dart';
import '../Screen/Tutorial/TutorialStep.dart';
import '../Screen/Tutorial/TutorialStorage.dart';

class TutorialProvider extends ChangeNotifier {
  final TutorialStorage _storage;

  TutorialProvider({TutorialStorage? storage})
      : _storage = storage ?? TutorialStorage();

  TutorialStatus _status = TutorialStatus.idle;
  TutorialLaunchSource? _source;
  int _currentStepIndex = 0;
  int? _userId;

  TutorialStatus get status => _status;
  TutorialLaunchSource? get source => _source;
  int get currentStepIndex => _currentStepIndex;
  TutorialStep get currentStep => tutorialSteps[_currentStepIndex];
  bool get isVisible => _status != TutorialStatus.idle;
  bool get isIntro => _status == TutorialStatus.intro;
  bool get isRunning => _status == TutorialStatus.running;
  bool get isOutro => _status == TutorialStatus.outro;

  Future<void> showAutoIntroIfNeeded({
    required UserInfoModel? userInfo,
    required bool isFirstLogin,
  }) async {
    if (_status != TutorialStatus.idle || !isFirstLogin || userInfo == null) {
      return;
    }

    final createdAt = userInfo.createdAt;
    final now = DateTime.now();
    final isRecentlyCreated = createdAt != null &&
        createdAt.isAfter(now.subtract(const Duration(minutes: 30))) &&
        createdAt.isBefore(now.add(const Duration(minutes: 5)));
    if (!isRecentlyCreated) return;

    final completed = await _storage.isCompleted(userInfo.userId);
    if (completed) return;

    _userId = userInfo.userId;
    _source = TutorialLaunchSource.firstSignup;
    _status = TutorialStatus.intro;
    _currentStepIndex = 0;
    _logEvent('tutorial_intro_show');
    notifyListeners();
  }

  void showReplayIntro(int userId) {
    _userId = userId;
    _source = TutorialLaunchSource.settingsReplay;
    _status = TutorialStatus.intro;
    _currentStepIndex = 0;
    _logEvent('tutorial_replay_from_settings');
    _logEvent('tutorial_intro_show');
    notifyListeners();
  }

  void start() {
    if (_status != TutorialStatus.intro) return;
    _status = TutorialStatus.running;
    _currentStepIndex = 0;
    _logEvent('tutorial_start');
    _logStepEvent('tutorial_step_show');
    notifyListeners();
  }

  void previous() {
    if (_status == TutorialStatus.outro) {
      _status = TutorialStatus.running;
      _logStepEvent('tutorial_previous');
      _logStepEvent('tutorial_step_show');
      notifyListeners();
      return;
    }
    if (_status != TutorialStatus.running || _currentStepIndex == 0) return;
    _logStepEvent('tutorial_previous');
    _currentStepIndex -= 1;
    _logStepEvent('tutorial_step_show');
    notifyListeners();
  }

  Future<void> next() async {
    if (_status != TutorialStatus.running) return;
    _logStepEvent('tutorial_next');
    if (_currentStepIndex >= tutorialSteps.length - 1) {
      _status = TutorialStatus.outro;
      _logEvent('tutorial_outro_show');
      notifyListeners();
      return;
    }
    _currentStepIndex += 1;
    _logStepEvent('tutorial_step_show');
    notifyListeners();
  }

  Future<void> skip() async {
    if (_status == TutorialStatus.running) {
      _logStepEvent('tutorial_skip');
    } else {
      _logEvent('tutorial_skip');
    }
    await _markCompletedIfAuto();
    _reset();
  }

  Future<void> complete() async {
    _logEvent('tutorial_complete');
    await _markCompletedIfAuto();
    _reset();
  }

  Future<void> _markCompletedIfAuto() async {
    if (_source != TutorialLaunchSource.firstSignup || _userId == null) return;
    await _storage.markCompleted(_userId!);
  }

  void _reset() {
    _status = TutorialStatus.idle;
    _source = null;
    _currentStepIndex = 0;
    notifyListeners();
  }

  void _logStepEvent(String name) {
    FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: {
        'step_index': _currentStepIndex,
        'step_id': currentStep.id,
        'source': _source?.name ?? 'unknown',
        'version': currentTutorialVersion,
      },
    );
  }

  void _logEvent(String name) {
    FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: {
        'source': _source?.name ?? 'unknown',
        'version': currentTutorialVersion,
      },
    );
  }
}
