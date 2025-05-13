import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ono/Model/Folder/FolderRegisterModel.dart';
import 'package:ono/Model/Problem/ProblemRepeatRegisterModel.dart';
import 'package:ono/Module/Util/ProblemSorting.dart';
import 'package:ono/Module/Util/ReviewHandler.dart';
import 'package:ono/Service/Api/FileUpload/FileUploadService.dart';
import 'package:ono/Service/Api/Folder/FolderService.dart';
import 'package:ono/Service/Api/HttpService.dart';

import '../Model/Folder/FolderModel.dart';
import '../Model/Problem/ProblemModel.dart';
import '../Model/Problem/ProblemRegisterModel.dart';
import '../Service/Api/Problem/ProblemService.dart';
import 'TokenProvider.dart';

class FoldersProvider with ChangeNotifier {
  FolderModel? _currentFolder;
  List<FolderModel> _folders = [];
  List<ProblemModel> _currentProblems = [];
  final TokenProvider tokenProvider = TokenProvider();
  final ReviewHandler reviewHandler = ReviewHandler();
  final HttpService httpService = HttpService();
  final folderService = FolderService();
  final problemService = ProblemService();
  final fileUploadService = FileUploadService();

  String sortOption = 'newest';

  FolderModel? get currentFolder => _currentFolder;
  List<ProblemModel> get currentProblems => List.unmodifiable(_currentProblems);
  List<FolderModel> get folders => _folders;

  // 상위 폴더로 이동
  Future<void> moveToFolder(int? folderId) async {
    FolderModel targetFolder =
        _folders.firstWhere((f) => f.folderId == folderId);

    _currentFolder = targetFolder;
    _currentProblems = targetFolder.problems;
    sortProblemsByOption(sortOption);

    log('Moved to folder: ${targetFolder.folderId}, Problems: ${_currentProblems.length}');

    // 4) UI 갱신
    notifyListeners();
  }

  Future<void> moveToRootFolder() async {
    // 전달받은 folderId에 해당하는 폴더를 _folders에서 검색
    final rootFolder = _folders[0];
    moveToFolder(rootFolder.folderId);
  }

  FolderModel getFolderContents(int? folderId) {
    return _folders.firstWhere(
      (folder) => folder.folderId == folderId,
      orElse: () => throw Exception('Folder with ID $folderId not found'),
    );
  }

  // 폴더 내용 로드 (특정 폴더 ID로)
  Future<void> fetchFolderContent(int? folderId) async {
    folderId ??= currentFolder!.folderId;

    final updatedFolder = await folderService.getFolderById(folderId);

    // 기존 데이터를 업데이트
    final index = _folders.indexWhere((folder) => folder.folderId == folderId);
    if (index != -1) {
      _folders[index] = updatedFolder;
    } else {
      _folders.add(updatedFolder);
    }

    print("folder fetch complete");
    notifyListeners();
  }

  Future<void> fetchAllFolderContents() async {
    _folders = await folderService.getAllFolderDetails();
    log('fetch all folder contents');

    for (var folder in _folders) {
      log('-----------------------------------------');
      log('Folder ID: ${folder.folderId}');
      log('Folder Name: ${folder.folderName}');
      log('Parent Folder Id: ${folder.parentFolder?.folderId ?? "No Parent"}');
      log('problem length: ${folder.problems.length}');
      log('Number of Problems: ${folder.problems.length}');
      log('Length of Subfolders: ${folder.subFolderList.length}');
      log('Created At: ${folder.createdAt}');
      log('Updated At: ${folder.updateAt}');
      log('-----------------------------------------');
    }

    await moveToRootFolder();
  }

  Future<void> clearFolderContents() async {
    _currentFolder = null;
    _folders = [];
    _currentProblems = [];

    notifyListeners();
  }

  // 폴더 생성
  Future<void> createFolder(String folderName, {int? parentFolderId}) async {
    parentFolderId = parentFolderId ?? currentFolder!.folderId;
    FolderRegisterModel folderRegisterModel = FolderRegisterModel(
        folderName: folderName, parentFolderId: parentFolderId);

    final createdFolderId =
        await folderService.registerFolder(folderRegisterModel);

    print(createdFolderId);

    await fetchFolderContent(createdFolderId);
    await fetchFolderContent(_currentFolder!.folderId);
    await moveToFolder(_currentFolder!.folderId);
  }

  Future<void> updateFolder(
      String? newName, int? folderId, int? parentId) async {
    FolderRegisterModel folderRegisterModel = FolderRegisterModel(
        folderName: newName!, parentFolderId: parentId!, folderId: folderId);

    await folderService.updateFolderInfo(folderRegisterModel);

    await fetchFolderContent(parentId);
    await fetchFolderContent(folderId);
    await fetchFolderContent(currentFolder!.folderId);

    await moveToFolder(currentFolder!.folderId);
  }

  // 폴더 삭제
  Future<void> deleteFolders(List<int> deleteFolderIdList) async {
    await folderService.deleteFolders(deleteFolderIdList);

    await fetchFolderContent(currentFolder!.folderId);
    await moveToFolder(currentFolder!.folderId);
  }

  Future<String> uploadImage(XFile image) async {
    return await fileUploadService.uploadImageFile(image);
  }

  Future<void> submitProblem(
      ProblemRegisterModel problemData, BuildContext context) async {
    await problemService.registerProblem(problemData);

    await fetchFolderContent(problemData.folderId ?? currentFolder!.folderId);
    await moveToFolder(currentFolder!.folderId);

    int userProblemCount = await getUserProblemCount();
    if (userProblemCount > 0 && userProblemCount % 10 == 0) {
      reviewHandler.requestReview(context);
    }
  }

  Future<int> getUserProblemCount() async {
    return await problemService.getProblemCount();
  }

  Future<void> updateProblem(ProblemRegisterModel problemData) async {
    if (problemData.imageDataDtoList != null &&
        problemData.imageDataDtoList!.isNotEmpty) {
      await problemService.updateProblemImageData(problemData);
    }

    if (problemData.memo != null || problemData.reference != null) {
      await problemService.updateProblemInfo(problemData);
    }

    if (problemData.folderId != null) {
      await problemService.updateProblemPath(problemData);
      await fetchFolderContent(problemData.folderId!);
    }

    await fetchFolderContent(_currentFolder!.folderId);
    await moveToFolder(_currentFolder!.folderId);
  }

  Future<void> deleteProblems(List<int> deleteProblemIdList) async {
    await problemService.deleteProblems(deleteProblemIdList);

    await fetchFolderContent(_currentFolder!.folderId);
    await moveToFolder(_currentFolder!.folderId);
  }

  Future<void> addRepeatCount(
      ProblemRepeatRegisterModel problemRepeatRegisterModel) async {
    await problemService.repeatProblem(problemRepeatRegisterModel);
    await fetchFolderContent(_currentFolder!.folderId);
  }

  void sortProblemsByOption(String option) {
    if (option == 'name') {
      sortProblemsByName();
    } else if (option == 'newest') {
      sortProblemsByNewest();
    } else if (option == 'oldest') {
      sortProblemsByOldest();
    }
  }

  void sortProblemsByName() {
    _currentProblems.sortByName();
    sortOption = 'name';
  }

  void sortProblemsByNewest() {
    _currentProblems.sortByNewest();
    sortOption = 'newest';
  }

  void sortProblemsByOldest() {
    _currentProblems.sortByOldest();
    sortOption = 'oldest';
  }

  List<int> getProblemIds() {
    return _currentProblems.map((problem) => problem.problemId).toList();
  }

  Future<ProblemModel?> getProblemDetails(int? problemId) async {
    var problemDetails = _currentProblems
        .firstWhere((problem) => problem.problemId == problemId);

    if (problemDetails != null) {
      return problemDetails;
    } else {
      return problemService.getProblem(problemId);
      throw Exception('Problem with ID $problemId not found');
    }
  }
}
