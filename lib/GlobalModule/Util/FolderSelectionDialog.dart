import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/FolderThumbnailModel.dart';
import '../../Provider/FoldersProvider.dart';
import '../Theme/StandardText.dart';
import '../Theme/ThemeHandler.dart';

class FolderSelectionDialog extends StatefulWidget {
  final int? initialFolderId; // 추가: 처음 선택된 폴더 ID

  const FolderSelectionDialog({super.key, this.initialFolderId});

  @override
  _FolderSelectionDialogState createState() => _FolderSelectionDialogState();

  // folderId로 folderName을 찾아 반환하는 함수
  static String? getFolderNameByFolderId(int? folderId) {
    if (folderId == null || _cachedFolders.isEmpty) return '공책 선택';

    // 해당 folderId가 있는지 확인하고, 없으면 기본값 반환
    final folder = _cachedFolders.firstWhere(
      (folder) => folder.folderId == folderId,
      orElse: () => FolderThumbnailModel(folderId: -1, folderName: '공책 선택'),
    );

    return folder.folderId != -1 ? folder.folderName : '공책 선택';
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
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    try {
      _cachedFolders = await foldersProvider.fetchAllFolderThumbnails();
      FolderSelectionDialog._cachedFolders = _cachedFolders;
      _expandedFolders = _cachedFolders
          .map((folder) => folder.folderId)
          .toSet(); // 모든 폴더를 기본적으로 확장

      if (_selectedFolderId != null) {
        // 폴더 ID가 선택되어 있다면 폴더 이름을 불러와 업데이트
        setState(() {
          _selectedFolderId = _selectedFolderId; // 업데이트 시 폴더 이름 반영
        });
      }
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
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
      contentPadding: const EdgeInsets.all(5),
      titlePadding: const EdgeInsets.only(left: 20, top: 20, right: 20),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StandardText(
            text: '공책 선택',
            fontSize: 20,
            color: themeProvider.primaryColor,
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: themeProvider.primaryColor),
            onPressed: () async {
              await _showFolderNameDialog(
                dialogTitle: '공책 생성',
                defaultFolderName: '',
                onFolderNameSubmitted: (folderName) async {
                  await _createFolder(folderName, _cachedFolders[0].folderId);
                },
              );
            },
          ),
        ],
      ),
      content: SizedBox(
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
          child: const StandardText(
            text: '취소',
            fontSize: 14,
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
          child: StandardText(
            text: '확인',
            fontSize: 14,
            color: themeProvider.primaryColor,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFolderList(
      List<FolderThumbnailModel> folders, ThemeHandler themeProvider,
      {int? parentId, int level = 0}) {
    List<Widget> folderWidgets = [];

    var parentFolders =
        folders.where((folder) => folder.parentFolderId == parentId).toList();

    for (var folder in parentFolders) {
      bool isExpanded = _expandedFolders.contains(folder.folderId);
      bool isSelected = _selectedFolderId == folder.folderId;

      folderWidgets.add(
        Padding(
          padding: EdgeInsets.only(left: level * 12.0),
          child: ListTile(
            title: StandardText(
              text: folder.folderName,
              fontSize: 15,
              color: themeProvider.primaryColor,
            ),
            leading: Icon(Icons.menu_book_outlined,
                color: themeProvider.primaryColor),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) const Icon(Icons.check, color: Colors.red),
                IconButton(
                  icon:
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
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
          _buildFolderList(folders, themeProvider,
              parentId: folder.folderId, level: level + 1),
        );
      }
    }

    return folderWidgets;
  }

  Future<void> _showFolderNameDialog({
    required String dialogTitle,
    required String defaultFolderName,
    required Function(String) onFolderNameSubmitted,
  }) async {
    TextEditingController folderNameController =
    TextEditingController(text: defaultFolderName);
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final standardTextStyle = const StandardText(text: '').getTextStyle();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: StandardText(
            text: dialogTitle,
            fontSize: 18,
            color: themeProvider.primaryColor,
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: TextField(
              controller: folderNameController,
              style: standardTextStyle.copyWith(
                color: themeProvider.primaryColor,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: '공책 이름을 입력하세요',
                hintStyle: standardTextStyle.copyWith(
                  color: themeProvider.desaturateColor,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: themeProvider.primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: themeProvider.primaryColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: themeProvider.primaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 12.0),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const StandardText(
                text: '취소',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () async {
                if (folderNameController.text.isNotEmpty) {
                  onFolderNameSubmitted(folderNameController.text);
                  Navigator.pop(context);
                }
              },
              child: StandardText(
                text: '확인',
                fontSize: 14,
                color: themeProvider.primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createFolder(String folderName, int? parentFolderId) async {
    final foldersProvider =
    Provider.of<FoldersProvider>(context, listen: false);
    await foldersProvider.createFolder(folderName, parentFolderId: parentFolderId);
    await _loadFolders();
  }
}
