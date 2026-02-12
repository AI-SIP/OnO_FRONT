import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ono/Model/Folder/FolderModel.dart';
import 'package:ono/Model/Folder/FolderThumbnailModel.dart';
import 'package:ono/Module/Theme/NoteIconHandler.dart';
import 'package:provider/provider.dart';

import '../../Provider/FoldersProvider.dart';
import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';

// 트리 노드 상태를 관리하는 클래스
class FolderTreeNode {
  final int folderId;
  final String folderName;
  final int? parentFolderId;

  bool isExpanded = false;
  bool isLoading = false;
  bool hasLoadedChildren = false;
  List<FolderTreeNode> children = [];
  bool hasMoreChildren = false;
  int? nextCursor;

  FolderTreeNode({
    required this.folderId,
    required this.folderName,
    this.parentFolderId,
  });
}

class FolderPickerDialog extends StatefulWidget {
  final int? initialFolderId;

  const FolderPickerDialog({super.key, this.initialFolderId});

  @override
  _FolderPickerDialogState createState() => _FolderPickerDialogState();

  // folderId로 folderName을 찾아 반환하는 함수
  static String? getFolderNameByFolderId(int? folderId) {
    if (folderId == null) return '책장';
    if (_cachedFolderNames.containsKey(folderId)) {
      return _cachedFolderNames[folderId];
    }
    return '책장';
  }

  static Map<int, String> _cachedFolderNames = {};
}

class _FolderPickerDialogState extends State<FolderPickerDialog> {
  int? _selectedFolderId;
  FolderTreeNode? _rootNode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.initialFolderId;
    _loadRootFolder();
  }

  Future<void> _loadRootFolder() async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    try {
      // 루트 폴더 가져오기
      final rootFolder = foldersProvider.rootFolder;
      if (rootFolder == null) {
        await foldersProvider.fetchRootFolder();
      }

      final root = foldersProvider.rootFolder!;
      _rootNode = FolderTreeNode(
        folderId: root.folderId,
        folderName: root.folderName,
        parentFolderId: null,
      );

      // 루트 폴더는 기본적으로 펼쳐진 상태로 설정
      _rootNode!.isExpanded = true;

      // 캐시에 저장
      FolderPickerDialog._cachedFolderNames[root.folderId] = root.folderName;

      _selectedFolderId ??= root.folderId;

      // 루트 폴더의 하위 폴더들을 바로 로드
      await _loadSubfolders(_rootNode!);
    } catch (e) {
      log('Failed to load root folder: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 하위 폴더 로드 (lazy loading with pagination)
  Future<void> _loadSubfolders(FolderTreeNode node) async {
    if (node.isLoading) return;

    setState(() {
      node.isLoading = true;
    });

    try {
      final foldersProvider =
          Provider.of<FoldersProvider>(context, listen: false);

      final response = await foldersProvider.folderService.getSubfoldersV2(
        folderId: node.folderId,
        cursor: node.nextCursor,
        size: 20,
      );

      // 하위 폴더들을 트리 노드로 변환
      final newChildren = response.content.map((folderThumbnail) {
        // 캐시에 저장
        FolderPickerDialog._cachedFolderNames[folderThumbnail.folderId] =
            folderThumbnail.folderName;

        return FolderTreeNode(
          folderId: folderThumbnail.folderId,
          folderName: folderThumbnail.folderName,
          parentFolderId: node.folderId,
        );
      }).toList();

      setState(() {
        node.children.addAll(newChildren);
        node.hasLoadedChildren = true;
        node.hasMoreChildren = response.hasNext;
        node.nextCursor = response.nextCursor;
        node.isLoading = false;
      });
    } catch (e, stackTrace) {
      log('Failed to load subfolders: $e');
      log('Stack trace: $stackTrace');
      setState(() {
        node.isLoading = false;
      });
    }
  }

  // 폴더 확장/축소 토글
  Future<void> _toggleFolder(FolderTreeNode node) async {
    if (node.isExpanded) {
      // 축소
      setState(() {
        node.isExpanded = false;
      });
    } else {
      // 확장
      setState(() {
        node.isExpanded = true;
      });

      // 아직 로드하지 않았으면 로드
      if (!node.hasLoadedChildren) {
        await _loadSubfolders(node);
      }
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
              "assets/Icon/addNote.svg",
              width: 30,
              height: 30,
            ),
            onPressed: () async {
              await _showFolderNameDialog(
                dialogTitle: '공책 생성',
                defaultFolderName: '',
                onFolderNameSubmitted: (folderName) async {
                  if (_rootNode != null) {
                    await _createFolder(folderName, _rootNode!.folderId);
                  }
                },
              );
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading || _rootNode == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(top: 10, right: 10),
                children: _buildFolderTreeList(_rootNode!, themeProvider),
              ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context, widget.initialFolderId);
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
              Navigator.pop(context, _selectedFolderId);
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

  // 트리 구조로 폴더 목록 빌드
  List<Widget> _buildFolderTreeList(
      FolderTreeNode node, ThemeHandler themeProvider,
      {int level = 0}) {
    List<Widget> widgets = [];

    bool isSelected = _selectedFolderId == node.folderId;

    // 현재 노드 위젯
    widgets.add(
      Padding(
        padding: EdgeInsets.only(left: level * 20.0),
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 확장/축소 버튼 (항상 같은 크기 유지)
              SizedBox(
                width: 48, // IconButton의 기본 크기
                height: 48,
                child: node.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          node.isExpanded
                              ? Icons.expand_more
                              : Icons.chevron_right,
                        ),
                        color: themeProvider.primaryColor,
                        onPressed: () => _toggleFolder(node),
                      ),
              ),
              // 폴더 아이콘
              SvgPicture.asset(
                NoteIconHandler.getNoteIcon(level),
                width: 30,
                height: 30,
              ),
            ],
          ),
          title: StandardText(
            text: node.folderName,
            fontSize: 16,
            color: themeProvider.primaryColor,
          ),
          trailing: isSelected
              ? Icon(Icons.check, color: themeProvider.primaryColor)
              : null,
          selected: isSelected,
          onTap: () {
            setState(() {
              _selectedFolderId = node.folderId;
            });
          },
        ),
      ),
    );

    // 확장되어 있으면 자식 노드들 표시
    if (node.isExpanded) {
      for (var child in node.children) {
        widgets.addAll(
          _buildFolderTreeList(child, themeProvider, level: level + 1),
        );
      }

      // 더 로드할 항목이 있으면 "더 보기" 버튼 표시
      if (node.hasMoreChildren && !node.isLoading) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: (level + 1) * 20.0),
            child: ListTile(
              leading: const Icon(Icons.more_horiz),
              title: StandardText(
                text: '더 보기',
                fontSize: 14,
                color: themeProvider.primaryColor,
              ),
              onTap: () => _loadSubfolders(node),
            ),
          ),
        );
      }
    }

    return widgets;
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

  Future<void> _createFolder(String folderName, int parentFolderId) async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    await foldersProvider.createFolder(folderName,
        parentFolderId: parentFolderId);

    // 생성된 폴더의 부모 노드를 찾아서 갱신
    _refreshNodeChildren(_rootNode!, parentFolderId);
  }

  // 특정 폴더 ID의 노드를 찾아서 자식 목록을 새로고침
  void _refreshNodeChildren(FolderTreeNode node, int targetFolderId) {
    if (node.folderId == targetFolderId) {
      // 찾았으면 자식 목록 초기화 후 다시 로드
      setState(() {
        node.children.clear();
        node.hasLoadedChildren = false;
        node.nextCursor = null;
        node.hasMoreChildren = false;
      });

      // 확장되어 있으면 다시 로드
      if (node.isExpanded) {
        _loadSubfolders(node);
      }
      return;
    }

    // 재귀적으로 자식 노드들 탐색
    for (var child in node.children) {
      _refreshNodeChildren(child, targetFolderId);
    }
  }
}
