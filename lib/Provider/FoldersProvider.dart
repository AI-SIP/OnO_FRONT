import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ono/Model/Folder/FolderRegisterModel.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Service/Api/FileUpload/FileUploadService.dart';
import 'package:ono/Service/Api/Folder/FolderService.dart';

import '../Model/Folder/FolderModel.dart';
import '../Model/Problem/ProblemModel.dart';

class FoldersProvider with ChangeNotifier {
  final ProblemsProvider problemsProvider;
  FolderModel? _currentFolder;
  List<FolderModel> _folders = [];
  List<ProblemModel> _currentProblems = [];

  final folderService = FolderService();
  final fileUploadService = FileUploadService();

  FolderModel? get currentFolder => _currentFolder;

  List<ProblemModel> get currentProblems => _currentProblems;

  List<FolderModel> get folders => _folders;

  FoldersProvider({required this.problemsProvider});

  FolderModel getFolder(int folderId) {
    int low = 0, high = _folders.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final midId = _folders[mid].folderId;
      if (midId == folderId) {
        log('find problemId: $folderId');
        return _folders[mid];
      } else if (midId < folderId) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    log('can\'t find problemId: $folderId');
    throw Exception('Problem with id $folderId not found.');
  }

  // 상위 폴더로 이동
  Future<void> moveToFolder(int? folderId) async {
    FolderModel targetFolder = await getFolder(folderId!);

    _currentFolder = targetFolder;
    _currentProblems.clear();

    for (var problemId in targetFolder.problemIdList) {
      final problemModel = await problemsProvider.getProblem(problemId);
      _currentProblems.add(problemModel);
    }

    log('Moved to folder: ${targetFolder.folderId}, Problems: ${_currentProblems.length}');
    notifyListeners();
  }

  Future<void> moveToRootFolder() async {
    final rootFolder = _folders[0];
    moveToFolder(rootFolder.folderId);
  }

  Future<void> fetchFolderContent(int? folderId) async {
    folderId ??= currentFolder!.folderId;

    final updatedFolder = await folderService.fetchFolder(folderId);

    final index = _folders.indexWhere((folder) => folder.folderId == folderId);
    if (index != -1) {
      _folders[index] = updatedFolder;
    } else {
      _folders.add(updatedFolder);
    }
    log('folderId: ${folderId} fetch complete');

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
      log('Number of Problems: ${folder.problemIdList.length}');
      log('Length of Subfolders: ${folder.subFolderList.length}');
      log('Created At: ${folder.createdAt}');
      log('Updated At: ${folder.updateAt}');
      log('-----------------------------------------');
    }

    await moveToRootFolder();
  }

  // 폴더 생성
  Future<void> createFolder(String folderName, {int? parentFolderId}) async {
    parentFolderId = parentFolderId ?? currentFolder!.folderId;
    FolderRegisterModel folderRegisterModel = FolderRegisterModel(
        folderName: folderName, parentFolderId: parentFolderId);

    final createdFolderId =
        await folderService.registerFolder(folderRegisterModel);

    await fetchFolderContent(createdFolderId);
    await fetchFolderContent(_currentFolder!.folderId);
    _currentFolder = await getFolder(_currentFolder!.folderId);

    notifyListeners();
  }

  Future<void> updateFolder(
      String? newName, int? folderId, int? parentId) async {
    FolderRegisterModel folderRegisterModel = FolderRegisterModel(
        folderName: newName!, parentFolderId: parentId!, folderId: folderId);

    await folderService.updateFolderInfo(folderRegisterModel);

    await fetchFolderContent(parentId);
    await fetchFolderContent(folderId);
    await fetchFolderContent(currentFolder!.folderId);
  }

  // 폴더 삭제
  Future<void> deleteFolders(List<int> deleteFolderIdList) async {
    await folderService.deleteFolders(deleteFolderIdList);

    await fetchFolderContent(currentFolder!.folderId);
  }
}
