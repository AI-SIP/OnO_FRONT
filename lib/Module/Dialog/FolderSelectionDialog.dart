import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ono/Model/Folder/FolderModel.dart';
import 'package:ono/Module/Theme/NoteIconHandler.dart';
import 'package:provider/provider.dart';

import '../../Provider/FoldersProvider.dart';
import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';

class FolderSelectionDialog extends StatefulWidget {
  final int? initialFolderId; // 추가: 처음 선택된 폴더 ID

  const FolderSelectionDialog({super.key, this.initialFolderId});

  @override
  _FolderSelectionDialogState createState() => _FolderSelectionDialogState();

  // folderId로 folderName을 찾아 반환하는 함수
  static String? getFolderNameByFolderId(int? folderId) {
    if (folderId == null || _cachedFolders.isEmpty) return '책장';

    // 해당 folderId가 있는지 확인하고, 없으면 기본값 반환
    final folder = _cachedFolders.firstWhere(
      (folder) => folder.folderId == folderId,
    );

    return folder.folderId != -1 ? folder.folderName : '책장';
  }

  static List<FolderModel> _cachedFolders = [];
}

class _FolderSelectionDialogState extends State<FolderSelectionDialog> {
  int? _selectedFolderId;
  Set<int> _expandedFolders = {}; // 확장된 폴더 ID를 저장하는 Set
  List<FolderModel> _cachedFolders = []; // 폴더 데이터를 캐싱하기 위한 리스트
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
      _cachedFolders = foldersProvider.folders;
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
      contentPadding: const EdgeInsets.all(0),
      titlePadding: const EdgeInsets.only(left: 30, top: 20, right: 20),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const StandardText(
            text: '공책 선택',
            fontSize: 20,
            color: Colors.black,
          ),
          IconButton(
            icon: SvgPicture.asset(
              "assets/Icon/addNote.svg", // SVG 경로
              width: 30,
              height: 30,
            ),
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
                padding: const EdgeInsets.only(top: 10, right: 10),
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
            fontSize: 16,
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
            fontSize: 16,
            color: themeProvider.primaryColor,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFolderList(
      List<FolderModel> folders, ThemeHandler themeProvider,
      {int? parentId, int level = 0}) {
    List<Widget> folderWidgets = [];

    var parentFolders = folders
        .where((folder) => folder.parentFolder?.folderId == parentId)
        .toList();

    for (var i = 0; i < parentFolders.length; i++) {
      var folder = parentFolders[i];
      bool isExpanded = _expandedFolders.contains(folder.folderId);
      bool isSelected = _selectedFolderId == folder.folderId;

      folderWidgets.add(
        Padding(
            padding: EdgeInsets.only(left: level * 20.0),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min, // Row가 너무 넓어지지 않도록 설정
                children: [
                  IconButton(
                    icon: Icon(
                        isExpanded ? Icons.expand_more : Icons.chevron_right),
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
                  SvgPicture.asset(
                    NoteIconHandler.getNoteIcon(i), // 헬퍼 클래스로 아이콘 설정
                    width: 30,
                    height: 30,
                  ),
                ],
              ),
              title: StandardText(
                text: folder.folderName,
                fontSize: 16,
                color: themeProvider.primaryColor,
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.red)
                  : null, // 선택된 폴더에만 체크 표시
              selected: isSelected,
              onTap: () {
                setState(() {
                  _selectedFolderId = folder.folderId;
                });
              },
            )),
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
            color: Colors.black,
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: TextField(
              controller: folderNameController,
              style: standardTextStyle.copyWith(
                color: Colors.black,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: '공책 이름을 입력하세요',
                hintStyle: standardTextStyle.copyWith(
                  color: ThemeHandler.desaturatenColor(Colors.black),
                  fontSize: 14,
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.5),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.5),
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
    await foldersProvider.createFolder(folderName,
        parentFolderId: parentFolderId);
    await _loadFolders();
  }
}
