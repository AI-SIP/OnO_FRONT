import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/FolderThumbnailModel.dart';
import '../../Provider/FoldersProvider.dart';
import '../Theme/HandWriteText.dart';
import '../Theme/ThemeHandler.dart';

class FolderSelectionDialog extends StatefulWidget {
  final int? initialFolderId; // 추가: 처음 선택된 폴더 ID

  FolderSelectionDialog({this.initialFolderId});

  @override
  _FolderSelectionDialogState createState() => _FolderSelectionDialogState();

  // folderId로 folderName을 찾아 반환하는 함수
  static String? getFolderNameByFolderId(int? folderId) {
    if (folderId == null) return '폴더 선택';

    return _cachedFolders.firstWhere(
          (folder) => folder.folderId == folderId,
      orElse: () => FolderThumbnailModel(folderId: -1, folderName: '폴더 선택'),
    ).folderName;
  }

  static List<FolderThumbnailModel> _cachedFolders = [];
}

class _FolderSelectionDialogState extends State<FolderSelectionDialog> {
  int? _selectedFolderId;
  Set<int> _expandedFolders = {}; // 확장된 폴더 ID를 저장하는 Set
  List<FolderThumbnailModel> _cachedFolders = []; // 폴더 데이터를 캐싱하기 위한 리스트
  bool _isLoading = true; // 데이터를 로딩 중인지 여부를 나타내는 상태

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.initialFolderId;
    _loadFolders(); // 초기 폴더 데이터를 로드
  }

  Future<void> _loadFolders() async {
    final foldersProvider = Provider.of<FoldersProvider>(context, listen: false);
    try {
      _cachedFolders = await foldersProvider.fetchAllFolderThumbnails();
      FolderSelectionDialog._cachedFolders = _cachedFolders;
      _expandedFolders = _cachedFolders.map((folder) => folder.folderId).toSet(); // 모든 폴더를 기본적으로 확장
    } catch (e) {
      log('Failed to load folders: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      contentPadding: const EdgeInsets.all(0),
      titlePadding: const EdgeInsets.only(left: 20, top: 20),
      title: HandWriteText(
        text: '폴더 선택',
        fontSize: 24,
        color: themeProvider.primaryColor,
      ),
      content: Container(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.only(left: 10, top: 10),
          children: _buildFolderList(_cachedFolders, themeProvider),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context, null); // 취소 시 아무 값도 넘기지 않음
          },
          child: const HandWriteText(
            text: '취소',
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () {
            if (_selectedFolderId != null) {
              Navigator.pop(context, _selectedFolderId); // 선택된 폴더 ID만 반환
            } else {
              Navigator.pop(context, null);
            }
          },
          child: HandWriteText(
            text: '확인',
            fontSize: 24,
            color: themeProvider.primaryColor,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFolderList(List<FolderThumbnailModel> folders, ThemeHandler themeProvider, {int? parentId, int level = 0}) {
    List<Widget> folderWidgets = [];

    var parentFolders = folders.where((folder) => folder.parentFolderId == parentId).toList();

    for (var folder in parentFolders) {
      bool isExpanded = _expandedFolders.contains(folder.folderId);
      bool isSelected = _selectedFolderId == folder.folderId;

      folderWidgets.add(
        Padding(
          padding: EdgeInsets.only(left: level * 12.0),
          child: ListTile(
            title: HandWriteText(
              text: folder.folderName,
              fontSize: 20,
              color: themeProvider.primaryColor,
            ),
            leading: Icon(Icons.folder, color: themeProvider.primaryColor),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Icon(Icons.check, color: Colors.red),
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  color: themeProvider.primaryColor,
                  onPressed: () {
                    setState(() {
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
            selected: isSelected,
            onTap: () {
              setState(() {
                _selectedFolderId = folder.folderId;
              });
            },
          ),
        ),
      );

      if (isExpanded) {
        folderWidgets.addAll(
          _buildFolderList(folders, themeProvider, parentId: folder.folderId, level: level + 1),
        );
      }
    }

    return folderWidgets;
  }
}
