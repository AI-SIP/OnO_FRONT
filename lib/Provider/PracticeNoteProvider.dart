import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteRegisterModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteThumbnailModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';

import '../Model/Problem/ProblemModel.dart';
import '../Service/Api/HttpService.dart';
import '../Service/Api/PracticeNote/PracticeNoteService.dart';
import 'TokenProvider.dart';

class ProblemPracticeProvider with ChangeNotifier {
  PracticeNoteModel? currentPracticeNote;
  List<PracticeNoteThumbnailModel> practiceThumbnails = [];
  List<ProblemModel> currentProblems = [];
  final TokenProvider tokenProvider = TokenProvider();
  final HttpService httpService = HttpService();
  final PracticeNoteService practiceNoteService = PracticeNoteService();

  Future<PracticeNoteThumbnailModel> findPracticeNote(
      int practiceNoteId) async {
    return practiceThumbnails.firstWhere((p) => p.practiceId == practiceNoteId);
  }

  Future<void> fetchAllPracticeContents() async {
    practiceThumbnails =
        await practiceNoteService.fetchPracticeNoteThumbnails();

    for (var practice in practiceThumbnails) {
      log('-----------------------------------------');
      log('practice ID: ${practice.practiceId}');
      log('practice Name: ${practice.practiceTitle}');
      log('lastSolved at: ${practice.lastSolvedAt}');
      log('practiceCount: ${practice.practiceCount}');
      log('-----------------------------------------');
    }
    notifyListeners();
  }

  Future<void> moveToPractice(int practiceId) async {
    final targetPractice =
        await practiceNoteService.getPracticeNoteById(practiceId);

    currentProblems = targetPractice.problems;
    currentPracticeNote = targetPractice;

    notifyListeners();
  }

  Future<void> registerPractice(
      PracticeNoteRegisterModel practiceNoteRegisterModel) async {
    await practiceNoteService.registerPracticeNote(practiceNoteRegisterModel);

    await fetchAllPracticeContents();
  }

  Future<void> updatePractice(
      PracticeNoteUpdateModel practiceNoteUpdateModel) async {
    await practiceNoteService.updatePracticeNote(practiceNoteUpdateModel);

    moveToPractice(practiceNoteUpdateModel.practiceNoteId);
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
    PracticeNoteThumbnailModel practiceNote =
        await findPracticeNote(practiceNoteId);
    practiceNote.addPracticeCount();
  }
}
