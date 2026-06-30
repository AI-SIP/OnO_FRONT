import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ono/Module/Theme/NoteIconHandler.dart';
import 'package:ono/Module/Dialog/SnackBarDialog.dart';
import 'package:provider/provider.dart';

import '../../Provider/FoldersProvider.dart';
import '../Text/mobile_font_size.dart';
import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';

// 트리 노드 상태를 관리하는 클래스
class FolderTreeNode {
  final int folderId;
  final String folderName;
  int? parentFolderId;

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
  final bool isManagementMode;

  const FolderPickerDialog({
    super.key,
    this.initialFolderId,
    this.isManagementMode = false,
  });

  @override
  _FolderPickerDialogState createState() => _FolderPickerDialogState();

  // folderId로 folderName을 찾아 반환하는 함수
  static String? getFolderNameByFolderId(int? folderId) {
    if (folderId == null) return null;
    if (_cachedFolderNames.containsKey(folderId)) {
      return _cachedFolderNames[folderId];
    }
    return null;
  }

  static Map<int, String> _cachedFolderNames = {};
}

class _FolderPickerDialogState extends State<FolderPickerDialog> {
  int? _selectedFolderId;
  FolderTreeNode? _rootNode;
  bool _isLoading = true;
  bool _isMovingFolder = false;

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
        folderName: '책장',
        parentFolderId: null,
      );

      // 루트 폴더는 기본적으로 펼쳐진 상태로 설정
      _rootNode!.isExpanded = true;

      // 캐시에 저장
      FolderPickerDialog._cachedFolderNames[root.folderId] = '책장';

      _selectedFolderId ??= root.folderId;

      // 루트 폴더의 하위 폴더들을 바로 로드
      await _loadSubfolders(_rootNode!);
    } catch (e) {
      debugPrint('Failed to load root folder: $e');
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
      debugPrint('Failed to load subfolders: $e');
      debugPrint('Stack trace: $stackTrace');
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
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final selectedFolderName =
        FolderPickerDialog.getFolderNameByFolderId(_selectedFolderId) ??
            '선택 안 됨';
    final selectedNode = _findNodeById(_rootNode, _selectedFolderId);
    final createTargetName = selectedNode?.folderName ?? selectedFolderName;
    final dialogTitle = widget.isManagementMode ? '공책 정리' : '공책 선택';
    final confirmText = widget.isManagementMode ? '완료하기' : '선택하기';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 12,
        vertical: isTablet ? 32 : 14,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: size.height * 0.86,
          maxWidth: isTablet ? 720 : size.width - 24,
          minHeight: isTablet ? 560 : size.height * 0.72,
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(isTablet ? 26 : 18, 20, 14, 16),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.folder_open,
                          color: themeProvider.primaryColor,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StandardText(
                              text: dialogTitle,
                              fontSize: MobileFontSize.reduced(context, 21),
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            const SizedBox(height: 4),
                            StandardText(
                              text: widget.isManagementMode
                                  ? '공책을 길게 눌러 위치를 바꿀 수 있어요'
                                  : '오답노트를 넣을 공책을 골라주세요',
                              fontSize: MobileFontSize.reduced(context, 12),
                              color: Colors.black54,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '공책 추가',
                        icon: SvgPicture.asset(
                          "assets/Icon/addNote.svg",
                          width: 26,
                          height: 26,
                        ),
                        onPressed: (_selectedFolderId == null ||
                                _isMovingFolder)
                            ? null
                            : () async {
                                await _showFolderNameDialog(
                                  dialogTitle: '공책 생성',
                                  defaultFolderName: '',
                                  parentFolderName: createTargetName,
                                  onFolderNameSubmitted: (folderName) async {
                                    final parentId = _selectedFolderId;
                                    if (parentId != null) {
                                      await _createFolder(folderName, parentId);
                                    }
                                  },
                                );
                              },
                      ),
                      IconButton(
                        tooltip: '닫기',
                        icon: const Icon(Icons.close, size: 22),
                        color: Colors.black54,
                        onPressed: () {
                          Navigator.pop(context, widget.initialFolderId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: _isLoading || _rootNode == null
                  ? Center(
                      child: CircularProgressIndicator(
                        color: themeProvider.primaryColor,
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 18 : 10,
                        12,
                        isTablet ? 18 : 10,
                        12,
                      ),
                      children: _buildFolderTreeList(_rootNode!, themeProvider),
                    ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context, widget.initialFolderId);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: StandardText(
                        text: '취소',
                        fontSize: MobileFontSize.reduced(context, 15),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (_isMovingFolder) return;
                        if (_selectedFolderId != null) {
                          Navigator.pop(context, _selectedFolderId);
                        } else {
                          Navigator.pop(context, null);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: themeProvider.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: StandardText(
                        text: confirmText,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 트리 구조로 폴더 목록 빌드
  List<Widget> _buildFolderTreeList(
      FolderTreeNode node, ThemeHandler themeProvider,
      {int level = 0}) {
    List<Widget> widgets = [];

    bool isSelected = _selectedFolderId == node.folderId;

    final horizontalIndent = (level * 14.0).clamp(0.0, 92.0);

    widgets.add(
      Padding(
        padding: EdgeInsets.fromLTRB(horizontalIndent, 4, 0, 4),
        child: _buildFolderDropTarget(
          node: node,
          level: level,
          themeProvider: themeProvider,
          child: _buildDraggableFolderRow(
            node: node,
            level: level,
            isSelected: isSelected,
            themeProvider: themeProvider,
          ),
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
            padding: EdgeInsets.only(left: (level + 1) * 18.0),
            child: TextButton.icon(
              onPressed: () => _loadSubfolders(node),
              icon: Icon(Icons.more_horiz, color: themeProvider.primaryColor),
              label: StandardText(
                text: '더 보기',
                fontSize: MobileFontSize.reduced(context, 13),
                color: themeProvider.primaryColor,
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildDraggableFolderRow({
    required FolderTreeNode node,
    required int level,
    required bool isSelected,
    required ThemeHandler themeProvider,
  }) {
    final row = _buildFolderRow(
      node: node,
      level: level,
      isSelected: isSelected,
      themeProvider: themeProvider,
    );

    if (node.parentFolderId == null) return row;

    return LongPressDraggable<FolderTreeNode>(
      data: node,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Opacity(
            opacity: 0.92,
            child: _buildFolderRow(
              node: node,
              level: 0,
              isSelected: true,
              themeProvider: themeProvider,
              isFeedback: true,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.45, child: row),
      onDragStarted: () => HapticFeedback.lightImpact(),
      child: row,
    );
  }

  Widget _buildFolderDropTarget({
    required FolderTreeNode node,
    required int level,
    required ThemeHandler themeProvider,
    required Widget child,
  }) {
    return DragTarget<FolderTreeNode>(
      onWillAcceptWithDetails: (details) => _canMoveFolder(details.data, node),
      onAcceptWithDetails: (details) async {
        await _moveFolderToParent(details.data, node);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: isHovered
                ? themeProvider.primaryColor.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHovered
                  ? themeProvider.primaryColor.withOpacity(0.35)
                  : Colors.transparent,
            ),
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildFolderRow({
    required FolderTreeNode node,
    required int level,
    required bool isSelected,
    required ThemeHandler themeProvider,
    bool isFeedback = false,
  }) {
    final iconSize = level == 0 ? 24.0 : 20.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected
            ? themeProvider.primaryColor.withOpacity(0.12)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? themeProvider.primaryColor.withOpacity(0.26)
              : Colors.grey[200]!,
        ),
        boxShadow: isFeedback
            ? const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _selectedFolderId = node.folderId;
          });
        },
        child: Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: node.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        node.isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 22,
                      ),
                      color: themeProvider.primaryColor,
                      splashRadius: 17,
                      onPressed: () => _toggleFolder(node),
                    ),
            ),
            const SizedBox(width: 4),
            SvgPicture.asset(
              NoteIconHandler.getNoteIcon(level),
              width: iconSize,
              height: iconSize,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StandardText(
                text: node.folderName,
                fontSize: MobileFontSize.reduced(context, 14),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: Colors.black87,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isMovingFolder)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isSelected)
              Icon(Icons.check_circle,
                  color: themeProvider.primaryColor, size: 18)
            else if (node.parentFolderId != null)
              Icon(Icons.drag_indicator, color: Colors.grey[350], size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _showFolderNameDialog({
    required String dialogTitle,
    required String defaultFolderName,
    required Function(String) onFolderNameSubmitted,
    String? parentFolderName,
  }) async {
    TextEditingController folderNameController =
        TextEditingController(text: defaultFolderName);
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final standardTextStyle = const StandardText(text: '').getTextStyle();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.create_new_folder,
                        color: themeProvider.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StandardText(
                      text: dialogTitle,
                      fontSize: MobileFontSize.reduced(context, 20),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (parentFolderName != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: StandardText(
                      text: '$parentFolderName 아래에 만들어요',
                      fontSize: MobileFontSize.reduced(context, 13),
                      color: Colors.black87,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                // 입력 필드
                TextField(
                  controller: folderNameController,
                  autofocus: true,
                  style: standardTextStyle.copyWith(
                    color: Colors.black87,
                    fontSize: MobileFontSize.reduced(context, 15),
                  ),
                  decoration: InputDecoration(
                    hintText: '공책 이름을 입력하세요',
                    hintStyle: standardTextStyle.copyWith(
                      color: Colors.grey[400],
                      fontSize: MobileFontSize.reduced(context, 14),
                    ),
                    fillColor: Colors.grey[50],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.primaryColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 액션 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: StandardText(
                        text: '취소',
                        fontSize: MobileFontSize.reduced(context, 15),
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () async {
                        final folderName = folderNameController.text.trim();
                        if (folderName.isNotEmpty) {
                          await onFolderNameSubmitted(folderName);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        backgroundColor: themeProvider.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const StandardText(
                        text: '확인',
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  bool _canMoveFolder(FolderTreeNode dragged, FolderTreeNode target) {
    if (_isMovingFolder) return false;
    if (dragged.folderId == target.folderId) return false;
    if (dragged.parentFolderId == target.folderId) return false;
    if (_isDescendantOf(target, dragged.folderId)) return false;
    return true;
  }

  bool _isDescendantOf(FolderTreeNode node, int ancestorId) {
    FolderTreeNode? current = node;
    while (current != null) {
      if (current.parentFolderId == ancestorId) return true;
      current = _findNodeById(_rootNode, current.parentFolderId);
    }
    return false;
  }

  Future<void> _moveFolderToParent(
    FolderTreeNode dragged,
    FolderTreeNode target,
  ) async {
    if (!_canMoveFolder(dragged, target)) return;

    final previousParentId = dragged.parentFolderId;
    final successColor =
        Provider.of<ThemeHandler>(context, listen: false).primaryColor;
    setState(() {
      _isMovingFolder = true;
    });

    try {
      final foldersProvider =
          Provider.of<FoldersProvider>(context, listen: false);
      await foldersProvider.updateFolder(
        dragged.folderName,
        dragged.folderId,
        target.folderId,
      );

      if (previousParentId != null) {
        await foldersProvider.refreshFolder(previousParentId);
      }
      await foldersProvider.refreshFolder(target.folderId);

      dragged.parentFolderId = target.folderId;
      await _refreshAfterMove(previousParentId, target.folderId);

      if (mounted) {
        SnackBarDialog.showSnackBar(
          context: context,
          message: '${dragged.folderName} 공책을 옮겼어요.',
          backgroundColor: successColor,
        );
      }
    } catch (e) {
      debugPrint('Failed to move folder: $e');
      if (mounted) {
        SnackBarDialog.showSnackBar(
          context: context,
          message: '공책을 옮기지 못했어요. 잠시 후 다시 시도해주세요.',
          backgroundColor: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMovingFolder = false;
        });
      }
    }
  }

  Future<void> _refreshAfterMove(
      int? previousParentId, int targetParentId) async {
    if (_rootNode == null) return;
    if (previousParentId != null) {
      await _resetAndReloadNode(previousParentId);
    }
    await _resetAndReloadNode(targetParentId);
  }

  Future<void> _resetAndReloadNode(int folderId) async {
    final node = _findNodeById(_rootNode, folderId);
    if (node == null) return;

    setState(() {
      node.children.clear();
      node.hasLoadedChildren = false;
      node.nextCursor = null;
      node.hasMoreChildren = false;
      node.isExpanded = true;
    });
    await _loadSubfolders(node);
  }

  FolderTreeNode? _findNodeById(FolderTreeNode? node, int? folderId) {
    if (node == null || folderId == null) return null;
    if (node.folderId == folderId) return node;
    for (final child in node.children) {
      final found = _findNodeById(child, folderId);
      if (found != null) return found;
    }
    return null;
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
