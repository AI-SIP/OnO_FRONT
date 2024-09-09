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

  @override
  Widget build(BuildContext context) {
    final foldersProvider =
    Provider.of<FoldersProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeHandler>(context);

    return AlertDialog(
      title: DecorateText(
        text: '위치 선택',
        fontSize: 24,
        color: themeProvider.primaryColor,
      ),
      content: Container(
        width: double.maxFinite,
        child: FutureBuilder<List<FolderThumbnailModel>>(
          future: foldersProvider.fetchAllFolderThumbnails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                  child: DecorateText(
                    text: '폴더를 불러오는 중 오류 발생',
                    fontSize: 24,
                    color: themeProvider.primaryColor,
                  ));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                  child: DecorateText(
                    text: '폴더가 없습니다!',
                    fontSize: 24,
                    color: themeProvider.primaryColor,
                  ));
            } else {
              // 폴더를 계층 구조로 표현
              return ListView(
                children: _buildFolderList(snapshot.data!, themeProvider),
              );
            }
          },
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
          padding: EdgeInsets.only(left: level * 16.0), // 계층에 따른 왼쪽 여백
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
                  Icon(Icons.check, color: themeProvider.primaryColor),
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
              // 폴더 선택 로직
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