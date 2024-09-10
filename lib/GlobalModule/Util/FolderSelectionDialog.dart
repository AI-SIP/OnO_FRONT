import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/FolderThumbnailModel.dart';
import '../../Provider/FoldersProvider.dart';
import '../Theme/DecorateText.dart';
import '../Theme/ThemeHandler.dart';

class FolderSelectionDialog extends StatefulWidget {
  @override
  _FolderSelectionDialogState createState() => _FolderSelectionDialogState();
}

class _FolderSelectionDialogState extends State<FolderSelectionDialog> {
  int? _selectedFolderId;
  String? _selectedFolderName;
  Set<int> _expandedFolders = {}; // 확장된 폴더 ID를 저장하는 Set
  List<FolderThumbnailModel> _cachedFolders = []; // 폴더 데이터를 캐싱하기 위한 리스트
  bool _isLoading = true; // 데이터를 로딩 중인지 여부를 나타내는 상태

  @override
  void initState() {
    super.initState();
    _loadFolders(); // 초기 폴더 데이터를 로드
  }

  Future<void> _loadFolders() async {
    final foldersProvider = Provider.of<FoldersProvider>(context, listen: false);
    try {
      // 서버에서 폴더 데이터를 한 번만 가져옴
      _cachedFolders = await foldersProvider.fetchAllFolderThumbnails();
      _selectedFolderId = await foldersProvider.currentFolder!.folderId;
      _selectedFolderName = await foldersProvider.currentFolder!.folderName;
    } catch (e) {
      log('Failed to load folders: $e');
    } finally {
      setState(() {
        _isLoading = false; // 데이터 로딩이 완료되면 상태 업데이트
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 30), // 좌우 패딩 줄임
      contentPadding: const EdgeInsets.all(0), // AlertDialog의 기본 패딩 제거
      titlePadding: const EdgeInsets.only(left: 20, top: 20), // 타이틀 패딩만 유지
      title: DecorateText(
        text: '위치 선택',
        fontSize: 24,
        color: themeProvider.primaryColor,
      ),
      content: Container(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator()) // 로딩 중일 때 로딩 인디케이터 표시
            : ListView(
          padding: const EdgeInsets.only(left: 10, top: 10), // ListView의 기본 padding 제거
          children: _buildFolderList(_cachedFolders, themeProvider),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context, null); // 취소 시 아무 값도 넘기지 않음
          },
          child: const DecorateText(
            text: '취소',
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () {
            if (_selectedFolderId != null && _selectedFolderName != null) {
              // 선택된 폴더 ID와 이름을 Map으로 전달
              Navigator.pop(context, {
                'folderId': _selectedFolderId,
                'folderName': _selectedFolderName,
              });
            } else {
              // 선택되지 않으면 그대로 취소
              Navigator.pop(context, null);
            }
          },
          child: DecorateText(
            text: '확인',
            fontSize: 24,
            color: themeProvider.primaryColor,
          ),
        ),
      ],
    );
  }

  // 계층 구조로 폴더 목록을 구축하는 함수
  List<Widget> _buildFolderList(List<FolderThumbnailModel> folders, ThemeHandler themeProvider, {int? parentId, int level = 0}) {
    List<Widget> folderWidgets = [];

    // 부모 폴더가 없는 (최상위) 폴더를 먼저 필터링
    var parentFolders = folders.where((folder) => folder.parentFolderId == parentId).toList();

    for (var folder in parentFolders) {
      bool isExpanded = _expandedFolders.contains(folder.folderId); // 현재 폴더가 확장된 상태인지 확인
      bool isSelected = _selectedFolderId == folder.folderId; // 현재 폴더가 선택된 상태인지 확인

      folderWidgets.add(
        Padding(
          padding: EdgeInsets.only(left: level * 12.0), // 계층에 따른 왼쪽 여백
          child: ListTile(
            title: DecorateText(
              text: folder.folderName,
              fontSize: 20,
              color: themeProvider.primaryColor,
            ),
            leading: Icon(Icons.folder, color: themeProvider.primaryColor),
            trailing: Row(
              mainAxisSize: MainAxisSize.min, // 아이콘들이 꽉 차지 않도록 설정
              children: [
                if (isSelected) // 폴더가 선택된 경우 체크 아이콘을 추가
                  const Icon(Icons.check, color: Colors.red),
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  color: themeProvider.primaryColor,
                  onPressed: () {
                    setState(() {
                      // 폴더를 확장하거나 축소
                      if (isExpanded) {
                        _expandedFolders.remove(folder.folderId);
                      } else {
                        _expandedFolders.add(folder.folderId);
                      }
                    });
                  },
                ),
              ],
            ),
            selected: isSelected, // 선택된 상태 반영
            onTap: () {
              // 폴더 선택 시 전체 화면 리빌드 없이 상태만 변경
              setState(() {
                _selectedFolderId = folder.folderId;
                _selectedFolderName = folder.folderName;
              });
            },
          ),
        ),
      );

      // 자식 폴더가 있을 경우 추가
      if (isExpanded) {
        folderWidgets.addAll(
          _buildFolderList(folders, themeProvider, parentId: folder.folderId, level: level + 1), // level 증가
        );
      }
    }

    return folderWidgets;
  }
}
