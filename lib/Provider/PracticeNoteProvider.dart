import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteRegisterModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';
import 'package:ono/Provider/ProblemsProvider.dart';

import '../Model/PracticeNote/PracticeNoteDetailModel.dart';
import '../Model/Problem/ProblemModel.dart';
import '../Service/Api/HttpService.dart';
import '../Service/Api/PracticeNote/PracticeNoteService.dart';
import 'TokenProvider.dart';

class ProblemPracticeProvider with ChangeNotifier {
  PracticeNoteDetailModel? currentPracticeNote;
  List<PracticeNoteDetailModel> _practices = [];
  List<ProblemModel> currentProblems = [];
  final TokenProvider tokenProvider = TokenProvider();
  final HttpService httpService = HttpService();
  final PracticeNoteService practiceNoteService = PracticeNoteService();
  final ProblemsProvider problemsProvider;

  List<PracticeNoteDetailModel> get practices => _practices;

  ProblemPracticeProvider({required this.problemsProvider});

  PracticeNoteDetailModel getPracticeNote(int practiceNoteId) {
    int low = 0, high = _practices.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final midId = _practices[mid].practiceId;
      if (midId == practiceNoteId) {
        return _practices[mid];
      } else if (midId < practiceNoteId) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    log('can\'t find problemId: $practiceNoteId');
    throw Exception('Problem with id $practiceNoteId not found.');
  }

  Future<void> fetchPracticeNote(int? practiceNoteId) async {
    final practiceNote =
        await practiceNoteService.getPracticeNoteById(practiceNoteId!);

    final index = _practices
        .indexWhere((practice) => practice.practiceId == practiceNoteId);
    if (index != -1) {
      _practices[index] = practiceNote;
      if (currentPracticeNote != null) {
        if (practiceNoteId == currentPracticeNote!.practiceId) {
          await moveToPractice(practiceNoteId);
        }
      }
    } else {
      _practices.add(practiceNote);
    }
    log('practiceId: ${practiceNoteId} fetch complete');

    notifyListeners();
  }

  Future<void> fetchAllPracticeContents() async {
    _practices = await practiceNoteService.getAllPracticeNoteDetails();

    log('fetch practice complete');
    notifyListeners();
  }

  Future<void> moveToPractice(int practiceId) async {
    final targetPractice = getPracticeNote(practiceId);

    currentProblems.clear();
    for (var problemId in targetPractice.problemIdList) {
      ProblemModel problemModel = problemsProvider.getProblem(problemId);
      currentProblems.add(problemModel);
    }

    currentPracticeNote = targetPractice;
    notifyListeners();
  }

  Future<void> registerPractice(
      PracticeNoteRegisterModel practiceNoteRegisterModel) async {
    int createdPracticeId = await practiceNoteService
        .registerPracticeNote(practiceNoteRegisterModel);

    await fetchPracticeNote(createdPracticeId);
  }

  Future<void> updatePractice(
      PracticeNoteUpdateModel practiceNoteUpdateModel) async {
    await practiceNoteService.updatePracticeNote(practiceNoteUpdateModel);

    await fetchPracticeNote(practiceNoteUpdateModel.practiceNoteId);
  }

  Future<void> deletePractices(List<int> deletePracticeIds) async {
    await practiceNoteService.deletePracticeNotes(deletePracticeIds);
    await fetchAllPracticeContents();
  }

  Future<void> resetProblems() async {
    currentProblems = [];
    notifyListeners();
  }

  Future<ProblemModel?> getProblemDetails(int? problemId) async {
    return currentProblems
        .firstWhere((problem) => problem.problemId == problemId);
  }

  Future<void> addPracticeCount(int practiceId) async {
    await practiceNoteService.addPracticeNoteCount(practiceId);
    await fetchPracticeCount(practiceId);
  }

  Future<void> fetchPracticeCount(int practiceNoteId) async {
    // 서버에서 최신 복습 노트 정보 조회
    await fetchPracticeNote(practiceNoteId);
    log('복습 카운트 갱신 완료 - Practice ID: $practiceNoteId');
  }
}
