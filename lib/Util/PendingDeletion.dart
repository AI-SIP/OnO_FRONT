import 'package:flutter/foundation.dart';

import '../Module/Design/AppToast.dart';

/// 지우기를 잠깐 미뤄 되돌릴 수 있게 한다.
///
/// 지우면 목록에서 바로 빼고 몇 초 동안 `되돌리기` 를 보인 뒤에 실제로 지운다.
/// 서버에는 지운 것을 되살리는 길이 없어서, 요청을 늦게 보내는 쪽으로 했다.
/// 목록 화면은 [isProblemHidden], [isFolderHidden] 으로 걸러 그리고, 바뀔 때
/// 다시 그리도록 이것을 듣는다.
class PendingDeletion extends ChangeNotifier {
  PendingDeletion._();

  static final PendingDeletion instance = PendingDeletion._();

  final Set<int> _problemIds = {};
  final Set<int> _folderIds = {};

  /// 지운 것. 문제 번호는 다시 쓰이지 않아서, 목록이 아직 옛 데이터를 들고
  /// 있어도 다시 보이지 않게 앱을 쓰는 동안 기억해 둔다.
  final Set<int> _deletedProblemIds = {};
  final Set<int> _deletedFolderIds = {};

  bool isProblemHidden(int problemId) =>
      _problemIds.contains(problemId) || _deletedProblemIds.contains(problemId);

  bool isFolderHidden(int folderId) =>
      _folderIds.contains(folderId) || _deletedFolderIds.contains(folderId);

  /// [message] 와 되돌리기를 보이고, 누르지 않으면 [commit] 으로 실제로 지운다.
  ///
  /// 지웠으면 true, 되돌렸으면 false 다. [commit] 이 실패하면 다시 보이게
  /// 하고 예외를 그대로 던진다.
  Future<bool> schedule({
    List<int> problemIds = const [],
    List<int> folderIds = const [],
    required String message,
    required Future<void> Function() commit,
  }) async {
    _problemIds.addAll(problemIds);
    _folderIds.addAll(folderIds);
    notifyListeners();

    final undone = await AppToast.undo(message);
    if (undone) {
      _release(problemIds, folderIds);
      return false;
    }

    try {
      await commit();
      _deletedProblemIds.addAll(problemIds);
      _deletedFolderIds.addAll(folderIds);
    } finally {
      _release(problemIds, folderIds);
    }
    return true;
  }

  void _release(List<int> problemIds, List<int> folderIds) {
    _problemIds.removeAll(problemIds);
    _folderIds.removeAll(folderIds);
    notifyListeners();
  }
}
