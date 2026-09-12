import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/User/UserInfoModel.dart';
import '../../Provider/UserProvider.dart';
import '../../Screen/Mission/MissionPalette.dart';
import '../Design/AppColors.dart';
import '../Design/AppRadius.dart';
import '../Design/AppSpacing.dart';
import '../Motion/AppearTransition.dart';
import '../Motion/AppHaptic.dart';
import '../Motion/AppMotion.dart';
import '../Motion/PressableScale.dart';
import '../Motion/SelectionPop.dart';
import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';
import '../Theme/ThemeLockManager.dart';

/// 격자의 열 하나가 능력치 하나다.
///
/// 색과 아이콘을 새로 만들지 않고 미션·캐릭터 화면이 쓰는 것을 그대로 가져온다.
/// 같은 능력치가 화면마다 다른 색이면 색이 정보를 잃는다. 아이콘도 옷장 탭
/// 스탯창의 눈금판과 같은 것([MissionPalette.iconOfKind])을 쓴다.
class _ThemeLane {
  /// [ThemeLockManager.getCategoryIndex] 가 돌려주는 열 번호.
  final int categoryIndex;

  final MissionKind kind;

  const _ThemeLane({
    required this.categoryIndex,
    required this.kind,
  });

  MissionKindColors get colors => MissionPalette.of(kind);

  /// 열 머리에 붙는 짧은 이름. 칸이 좁아서 긴 이름은 들어가지 않는다.
  String get shortLabel => MissionPalette.labelOfKind(kind);

  /// 조건을 문장으로 말할 때 쓰는 제 이름.
  String get fullLabel => ThemeLockManager.getCategoryName(categoryIndex);
}

/// 왼쪽부터 오른쪽으로 [ThemeLockManager] 의 열 순서와 같아야 한다.
const List<_ThemeLane> _themeLanes = <_ThemeLane>[
  _ThemeLane(
    categoryIndex: 0,
    kind: MissionKind.attendance,
  ),
  _ThemeLane(
    categoryIndex: 1,
    kind: MissionKind.noteWrite,
  ),
  _ThemeLane(
    categoryIndex: 2,
    kind: MissionKind.problemPractice,
  ),
  _ThemeLane(
    categoryIndex: 3,
    kind: MissionKind.notePractice,
  ),
];

/// 테마를 고르는 창이다.
///
/// 예전에는 색 동그라미 24개를 4열로 깔아 두고 잠긴 것에 자물쇠만 얹었다.
/// 그래서 **무엇을 하면 열리는지 알 수가 없었다.** 누르면 그제서야 창이 하나
/// 더 떠서 조건을 알려 줬다.
///
/// 해금 규칙은 이미 좋은 재료다. 열이 능력치고 행이 단계다. 이 창은 그 구조를
/// 그대로 그린다. 열 넷을 능력치 네 갈래의 **트랙**으로 세우고, 지금 레벨까지
/// 올라온 칸은 그 능력치 색으로 칠하고 그 위는 회색으로 둔다. 색이 끝나는
/// 자리가 지금 내가 서 있는 곳이고, 바로 그다음 칸이 다음 목표다.
///
/// 색이 주인공인 화면이라 나머지는 전부 물러나 있다. 바탕은 흰색이고,
/// 능력치 색은 아주 옅은 파스텔이며, 강조는 고른 테마색 하나만 맡는다.
class ThemeDialog extends StatefulWidget {
  // const 로 만들지 않는다. 이미 `ThemeDialog()` 로 부르는 자리가 둘 있어서
  // 생성자만 const 로 바꾸면 그쪽에 prefer_const_constructors 가 새로 뜬다.
  // ignore: prefer_const_constructors_in_immutables
  ThemeDialog({super.key});

  /// 격자 한 칸의 키. 칸이 다시 그려져도 같은 칸으로 이어진다.
  ///
  /// 테스트에서 "출석 열 Lv.9 칸" 처럼 특정 칸을 집을 때도 이걸 쓴다.
  static Key cellKey(int themeIndex) =>
      ValueKey<String>('themeCell$themeIndex');

  @override
  State<ThemeDialog> createState() => _ThemeDialogState();
}

class _ThemeDialogState extends State<ThemeDialog> {
  /// 격자 좌우 여백. 칸이 가장자리까지 차야 24개가 한 화면에 들어간다.
  static const double _gridPadding = AppSpacing.md;

  /// 단계 이름(기본, Lv.3 …)이 서는 왼쪽 칸의 폭.
  static const double _tierGutter = 36;

  /// 트랙과 트랙 사이.
  static const double _laneGap = AppSpacing.sm;

  /// 동그라미 지름의 위 한계.
  ///
  /// 트랙이 넓어도 여기서 멈춘다. 원을 키우는 대신 남는 자리를 여백으로 돌리는
  /// 쪽이 스물넷을 한눈에 볼 때 덜 답답하다. 색은 크기보다 서로 떨어져 있을 때
  /// 더 잘 구분된다.
  static const double _maxSwatch = 40;

  /// 트랙 안쪽 여백. 동그라미가 트랙 벽에 닿지 않게 한다.
  static const double _laneInset = 5;

  /// 트랙 위아래 끝의 여백.
  ///
  /// 칸마다 똑같은 높이를 주면 첫 동그라미와 마지막 동그라미가 트랙 모서리에
  /// 6px 밖에 안 떨어진다. 끼워 넣은 것처럼 답답해 보여서 위아래 끝 칸만 이만큼
  /// 키우고, 늘어난 자리를 **바깥쪽에만** 준다(안쪽에 반씩 나눠 주면 첫째와
  /// 둘째 사이만 벌어져 간격이 들쭉날쭉해진다). 칸의 색칠은 늘어난 높이까지
  /// 그대로 차므로 "색이 끝나는 자리가 지금 서 있는 곳"은 흐트러지지 않는다.
  ///
  /// 늘어난 만큼의 자리는 동그라미를 [_maxSwatch] 로 줄여서 마련했다. 24칸이
  /// 390pt 폰과 태블릿에서 스크롤 없이 들어가야 하는 조건이 있어 트랙 전체
  /// 높이는 늘릴 수 없다. 처음에는 칸 사이를 좁혀 이 자리를 만들었는데,
  /// 그러면 끝만 벌어지고 가운데는 더 빽빽해졌다. 원을 줄이는 쪽이 끝도 사이도
  /// 같이 벌릴 수 있다.
  static const double _laneEndPad = AppSpacing.md;

  /// 칸과 칸 사이.
  ///
  /// 동그라미를 46 에서 [_maxSwatch] 로 줄이면서 생긴 자리를 여기에 돌려줬다.
  /// 원이 작아지고 사이가 벌어지니 트랙이 빽빽해 보이지 않는다.
  static const double _cellGap = AppSpacing.md;

  /// 적용을 누르고 창이 닫히기까지의 사이.
  ///
  /// 누르는 순간 앱 색이 바뀌는데 창이 같이 사라지면 무엇이 바뀌었는지 볼
  /// 틈이 없다. 이만큼 남겨 두면 창과 뒤 화면이 새 색으로 물드는 것을 보고
  /// 닫힌다.
  static const Duration _settleBeforeClose = Duration(milliseconds: 220);

  Color? _selectedColor;
  String? _selectedColorName;
  int? _selectedIndex;
  bool _isSelectionInitialized = false;

  /// 잠긴 칸을 눌러 조건을 들여다보는 중인 칸. 고른 것과는 다른 상태다.
  int? _inspectedIndex;

  /// 적용을 눌러 닫히는 중. 두 번 눌러 두 번 pop 되는 것을 막는다.
  bool _isApplying = false;

  void _initializeSelection(ThemeHandler themeProvider) {
    if (_isSelectionInitialized) return;
    _isSelectionInitialized = true;

    for (int i = 0; i < ThemeLockManager.themeCount; i++) {
      final color = ThemeLockManager.getThemeColor(i);
      if (color == themeProvider.primaryColor) {
        _selectedColor = color;
        _selectedColorName = ThemeLockManager.getThemeName(i);
        _selectedIndex = i;
        return;
      }
    }

    _selectedColor = themeProvider.primaryColor;
    _selectedColorName = '현재 테마';
    _selectedIndex = null;
  }

  void _select(int index) {
    setState(() {
      _selectedColor = ThemeLockManager.getThemeColor(index);
      _selectedColorName = ThemeLockManager.getThemeName(index);
      _selectedIndex = index;
      _inspectedIndex = null;
    });
  }

  /// 잠긴 칸은 고르는 대신 조건을 위쪽 판에 펼친다.
  ///
  /// 예전에는 창 위에 창을 하나 더 띄웠다. 조건 하나 보자고 화면을 덮는 것은
  /// 과했고, 확인을 누르고 돌아와야 다음 칸을 볼 수 있었다.
  void _inspect(int index) {
    setState(() => _inspectedIndex = index);
  }

  void _apply(ThemeHandler themeProvider) {
    if (_isApplying) return;

    final navigator = Navigator.of(context);
    final color = _selectedColor;
    final name = _selectedColorName;

    if (color == null || name == null) {
      navigator.pop();
      return;
    }

    AppHaptic.primary();
    themeProvider.changePrimaryColor(color, name);

    if (AppMotion.isReduced(context)) {
      navigator.pop();
      return;
    }

    setState(() => _isApplying = true);
    Future<void>.delayed(_settleBeforeClose, () {
      if (!mounted) return;
      navigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final userInfo = Provider.of<UserProvider>(context).userInfoModel;
    _initializeSelection(themeProvider);

    final screenHeight = MediaQuery.of(context).size.height;
    final duration =
        AppMotion.isReduced(context) ? Duration.zero : AppMotion.normal;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 430,
          maxHeight: screenHeight * 0.86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPreview(userInfo, duration),
            _buildLaneHeader(userInfo),
            Flexible(child: _buildTracks(userInfo, duration)),
            _buildFooter(themeProvider, duration),
          ],
        ),
      ),
    );
  }

  // ── 위쪽 미리보기 판 ─────────────────────────────────────────

  /// 고른 색을 크게 보여 주는 자리.
  ///
  /// 잠긴 칸을 누르면 같은 자리가 그 칸의 조건으로 바뀐다. 색 하나를 크게
  /// 띄워 두면 작은 동그라미 24개만 볼 때보다 "이 색으로 바꾼다"가 훨씬 잘
  /// 와닿는다.
  ///
  /// 이름 아래 설명은 **할 말이 있을 때만** 붙인다. 열린 색에는 아무것도 안
  /// 붙는다. 어느 레벨에서 열었는지는 이미 지난 일이라 고르는 데 쓸모가 없고,
  /// 색마다 한 줄씩 따라붙으면 판이 설명문처럼 보인다. 잠긴 색의 조건은
  /// 지금 행동을 정하는 정보라서 남긴다.
  Widget _buildPreview(UserInfoModel? userInfo, Duration duration) {
    final inspected = _inspectedIndex;
    final isLocked = inspected != null;
    final index = inspected ?? _selectedIndex;

    final Color swatchColor;
    final Color panelAccent;
    final String overline;
    final String title;
    final String? detail;

    if (index == null) {
      // 저장된 색이 24종 어디에도 없는 경우. 예전 버전에서 고른 색일 수 있다.
      // 이름이 없는 이유를 말해 줘야 해서 이때는 한 줄 붙인다.
      swatchColor = _selectedColor ?? AppColors.borderStrong;
      panelAccent = swatchColor;
      overline = '지금 쓰는 색';
      title = _selectedColorName ?? '현재 테마';
      detail = '목록에 없는 색이에요';
    } else {
      final lane = _themeLanes[ThemeLockManager.getCategoryIndex(index)];
      final rowIndex = ThemeLockManager.getRowIndex(index);
      final requiredLevel = ThemeLockManager.getRequiredLevel(rowIndex);
      final currentLevel =
          ThemeLockManager.getCurrentLevel(lane.categoryIndex, userInfo);

      swatchColor = ThemeLockManager.getThemeColor(index);
      title = ThemeLockManager.getThemeName(index);

      if (isLocked) {
        // 잠긴 칸을 보고 있을 때는 판 전체가 그 능력치 색을 띤다. 어느 갈래를
        // 올려야 하는지가 글자보다 색으로 먼저 읽힌다.
        //
        // 능력치는 열 머리와 같은 짧은 이름으로 부른다. 긴 이름을 쓰면 좁은
        // 폭에서 두 줄이 되고, 그때 판이 커지면서 격자가 밀린다.
        panelAccent = lane.colors.accent;
        overline = '아직 잠긴 색';
        detail = '${lane.shortLabel} Lv.$requiredLevel 필요 · '
            '지금 Lv.$currentLevel';
      } else {
        panelAccent = swatchColor;
        overline = '고른 색';
        detail = null;
      }
    }

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: panelAccent),
      duration: duration,
      curve: AppMotion.standard,
      builder: (context, animatedAccent, _) {
        final accent = animatedAccent ?? panelAccent;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            // 그라데이션을 깔지 않는다. 색 24개가 주인공인 화면에서 배경까지
            // 번지면 무엇을 고르는 중인지가 흐려진다.
            color: Color.alphaBlend(
              accent.withValues(alpha: 0.10),
              AppColors.surface,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.xlarge),
              topRight: Radius.circular(AppRadius.xlarge),
            ),
          ),
          child: AnimatedSize(
            duration: duration,
            curve: AppMotion.standard,
            alignment: Alignment.topCenter,
            child: Row(
              children: [
                _PreviewSwatch(
                  color: swatchColor,
                  isLocked: isLocked,
                  duration: duration,
                ),
                // 동그라미와 이름은 한 덩어리로 읽혀야 한다. 사이가 넓으면
                // 색과 이름이 서로 다른 것을 가리키는 것처럼 보인다.
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: duration,
                    child: Column(
                      key: ValueKey<String>('$overline|$title|$detail'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StandardText(
                          text: overline,
                          fontSize: 10,
                          color: isLocked ? accent : AppColors.textTertiary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        StandardText(
                          text: title,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (detail != null)
                          StandardText(
                            text: detail,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 능력치 머리줄 ───────────────────────────────────────────

  /// 열 넷이 각각 어떤 능력치인지, 그 능력치가 지금 몇 레벨인지를 얹는다.
  ///
  /// 이 줄이 없으면 아래 격자는 그냥 색 스물네 개다. 이 줄이 있어야 세로로
  /// 늘어선 여섯 칸이 "이 능력치를 올려서 얻는 색"으로 읽힌다.
  Widget _buildLaneHeader(UserInfoModel? userInfo) {
    return Padding(
      // 위로는 미리보기 판과, 아래로는 격자와 벌린다. 머리줄이 격자에 붙어
      // 있으면 능력치 이름이 첫 줄 색의 이름표처럼 보인다.
      padding: const EdgeInsets.fromLTRB(
        _gridPadding,
        AppSpacing.lg,
        _gridPadding,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: _tierGutter),
          for (var i = 0; i < _themeLanes.length; i++) ...[
            if (i > 0) const SizedBox(width: _laneGap),
            Expanded(
              child: _LaneHeader(
                lane: _themeLanes[i],
                level: ThemeLockManager.getCurrentLevel(
                  _themeLanes[i].categoryIndex,
                  userInfo,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 격자 ───────────────────────────────────────────────────

  /// 능력치 트랙 넷을 세로로 세운다.
  ///
  /// 세로로 스크롤되게 둔 이유가 있다. 작은 폰이나 글자를 키운 기기에서는
  /// 24칸이 한 화면에 다 들어가지 않는데, 칸을 더 줄이면 색을 알아볼 수 없게
  /// 된다. 색을 알아볼 수 있는 크기를 지키고 넘치는 만큼 밀어 본다.
  Widget _buildTracks(UserInfoModel? userInfo, Duration duration) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth -
            _gridPadding * 2 -
            _tierGutter -
            _laneGap * (_themeLanes.length - 1);
        final laneWidth = trackWidth / _themeLanes.length;
        final swatchSize = (laneWidth - _laneInset * 2).clamp(26.0, _maxSwatch);
        final cellHeight = swatchSize + _cellGap;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            _gridPadding,
            0,
            _gridPadding,
            AppSpacing.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTierGutter(cellHeight),
              for (var i = 0; i < _themeLanes.length; i++) ...[
                if (i > 0) const SizedBox(width: _laneGap),
                Expanded(
                  child: AppearTransition(
                    delay: AppMotion.stagger * i,
                    child: _buildLane(
                      lane: _themeLanes[i],
                      userInfo: userInfo,
                      cellHeight: cellHeight,
                      swatchSize: swatchSize,
                      duration: duration,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 격자 왼쪽에 붙는 단계 이름. 행이 레벨이라는 것을 말로 못 박는다.
  Widget _buildTierGutter(double cellHeight) {
    return SizedBox(
      width: _tierGutter,
      child: Column(
        children: [
          for (var row = 0; row < ThemeLockManager.tierCount; row++)
            SizedBox(
              // 트랙의 칸 높이와 같아야 단계 이름이 동그라미와 나란히 선다.
              // 늘어난 자리를 어느 쪽에 주는지까지 같아야 한다.
              height: _cellHeightAt(row, cellHeight),
              child: Padding(
                padding: _cellPaddingAt(row),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: StandardText(
                        text: ThemeLockManager.getTierLabel(row),
                        fontSize: 10,
                        color: AppColors.textTertiary,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 능력치 하나의 트랙. 여섯 칸이 아래로 이어진다.
  Widget _buildLane({
    required _ThemeLane lane,
    required UserInfoModel? userInfo,
    required double cellHeight,
    required double swatchSize,
    required Duration duration,
  }) {
    final nextGoalRow = _nextGoalRow(lane, userInfo);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: ColoredBox(
        // 아직 못 올라간 구간의 바탕. 색이 칠해진 데까지가 올라온 곳이다.
        color: AppColors.surfaceMuted,
        child: Column(
          children: [
            for (var row = 0; row < ThemeLockManager.tierCount; row++)
              _ThemeCell(
                key: ThemeDialog.cellKey(
                  ThemeLockManager.themeIndexAt(row, lane.categoryIndex),
                ),
                index: ThemeLockManager.themeIndexAt(row, lane.categoryIndex),
                lane: lane,
                userInfo: userInfo,
                height: _cellHeightAt(row, cellHeight),
                padding: _cellPaddingAt(row),
                swatchSize: swatchSize,
                duration: duration,
                isSelected: _selectedIndex ==
                    ThemeLockManager.themeIndexAt(row, lane.categoryIndex),
                isInspected: _inspectedIndex ==
                    ThemeLockManager.themeIndexAt(row, lane.categoryIndex),
                isNextGoal: nextGoalRow == row,
                onSelect: _select,
                onInspect: _inspect,
              ),
          ],
        ),
      ),
    );
  }

  /// 이 줄의 칸 높이. 첫 줄과 마지막 줄만 [_laneEndPad] 만큼 더 높다.
  ///
  /// 트랙과 단계 이름 거터가 같은 식을 써야 둘이 어긋나지 않는다.
  static double _cellHeightAt(int row, double cellHeight) =>
      cellHeight + _cellPaddingAt(row).vertical;

  /// 이 줄에서 늘어난 자리를 어느 쪽에 줄지.
  ///
  /// 첫 줄은 위로만, 마지막 줄은 아래로만 준다. 가운데 줄들은 없다.
  static EdgeInsets _cellPaddingAt(int row) {
    if (row == 0) return const EdgeInsets.only(top: _laneEndPad);
    if (row == ThemeLockManager.tierCount - 1) {
      return const EdgeInsets.only(bottom: _laneEndPad);
    }
    return EdgeInsets.zero;
  }

  /// 이 트랙에서 가장 먼저 잠긴 칸. 없으면 다 연 것이다.
  ///
  /// 필요 레벨을 여기서 다시 계산하지 않고 [ThemeLockManager.isThemeUnlocked]
  /// 에 물어 본다. 판정을 두 군데 두면 언젠가 어긋난다.
  int? _nextGoalRow(_ThemeLane lane, UserInfoModel? userInfo) {
    for (var row = 0; row < ThemeLockManager.tierCount; row++) {
      final index = ThemeLockManager.themeIndexAt(row, lane.categoryIndex);
      if (!ThemeLockManager.isThemeUnlocked(index, userInfo)) return row;
    }
    return null;
  }

  // ── 아래쪽 버튼 ─────────────────────────────────────────────

  Widget _buildFooter(ThemeHandler themeProvider, Duration duration) {
    final accent = _selectedColor ?? themeProvider.primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PressableScale(
              haptic: HapticLevel.secondary,
              onTap: _isApplying ? null : () => Navigator.of(context).pop(),
              child: _FooterButton(
                label: '취소',
                background: AppColors.surfaceMuted,
                foreground: AppColors.textSecondary,
                duration: duration,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: PressableScale(
              haptic: HapticLevel.none,
              onTap: _isApplying ? null : () => _apply(themeProvider),
              child: _FooterButton(
                label: '적용하기',
                background: accent,
                foreground: _onColor(accent),
                duration: duration,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [background] 위에 올려도 읽히는 글자색.
///
/// 테마색에는 검정도 있고 베이지도 있다. 흰 글자로 고정하면 밝은 테마에서
/// 글자가 사라진다.
Color _onColor(Color background) {
  return background.computeLuminance() > 0.55
      ? AppColors.textPrimary
      : Colors.white;
}

/// 잠긴 색을 바탕에 섞어 흐리게 만든 것.
///
/// 아예 회색으로 덮지 않는다. 어떤 색인지 어렴풋이 보여야 갖고 싶어진다.
Color _lockedTint(Color color, double alpha) {
  return Color.alphaBlend(
    color.withValues(alpha: alpha),
    AppColors.surfaceMuted,
  );
}

/// 미리보기 판의 큰 동그라미.
class _PreviewSwatch extends StatelessWidget {
  final Color color;
  final bool isLocked;
  final Duration duration;

  const _PreviewSwatch({
    required this.color,
    required this.isLocked,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    const size = 54.0;

    return AnimatedContainer(
      duration: duration,
      curve: AppMotion.standard,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLocked ? _lockedTint(color, 0.35) : color,
        border: Border.all(color: AppColors.surface, width: 3),
        boxShadow: isLocked
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.38),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: isLocked
          ? const Icon(
              Icons.lock_rounded,
              size: 20,
              color: AppColors.textTertiary,
            )
          : Icon(Icons.check_rounded, size: 24, color: _onColor(color)),
    );
  }
}

/// 능력치 한 갈래의 머리. 아이콘·이름·지금 레벨.
class _LaneHeader extends StatelessWidget {
  final _ThemeLane lane;
  final int level;

  const _LaneHeader({required this.lane, required this.level});

  @override
  Widget build(BuildContext context) {
    final colors = lane.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          MissionPalette.iconOfKind(lane.kind),
          color: colors.accent,
          size: 20,
        ),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: StandardText(
            text: lane.shortLabel,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: StandardText(
              text: 'Lv.$level',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: colors.accent,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// 격자 한 칸.
///
/// 잠긴 칸은 자물쇠 대신 **필요한 레벨**을 적는다. 열 머리에 능력치 이름이
/// 있으니 `출석` 열의 `Lv.9` 칸은 그대로 "출석 Lv.9" 로 읽힌다.
class _ThemeCell extends StatelessWidget {
  final int index;
  final _ThemeLane lane;
  final UserInfoModel? userInfo;
  final double height;

  /// 늘어난 자리를 어느 쪽에 줄지. 트랙 끝 칸만 값이 있다.
  ///
  /// 색칠은 [height] 전체를 채우고 동그라미만 이 여백만큼 안쪽으로 들어간다.
  /// 그래야 끝이 벌어지면서도 색이 끊기지 않는다.
  final EdgeInsets padding;

  final double swatchSize;
  final Duration duration;
  final bool isSelected;
  final bool isInspected;

  /// 이 트랙에서 가장 먼저 잠긴 칸. 바로 다음 목표라 한 단계 더 드러낸다.
  final bool isNextGoal;

  final void Function(int index) onSelect;
  final void Function(int index) onInspect;

  const _ThemeCell({
    super.key,
    required this.index,
    required this.lane,
    required this.userInfo,
    required this.height,
    required this.padding,
    required this.swatchSize,
    required this.duration,
    required this.isSelected,
    required this.isInspected,
    required this.isNextGoal,
    required this.onSelect,
    required this.onInspect,
  });

  @override
  Widget build(BuildContext context) {
    final color = ThemeLockManager.getThemeColor(index);
    final isUnlocked = ThemeLockManager.isThemeUnlocked(index, userInfo);
    final rowIndex = ThemeLockManager.getRowIndex(index);
    final requiredLevel = ThemeLockManager.getRequiredLevel(rowIndex);
    final colors = lane.colors;

    return Semantics(
      container: true,
      label: isUnlocked
          ? '${ThemeLockManager.getThemeName(index)} 테마'
          : '${ThemeLockManager.getThemeName(index)} 테마, '
              '${lane.fullLabel} Lv.$requiredLevel 필요',
      child: PressableScale(
        haptic: isUnlocked ? HapticLevel.selection : HapticLevel.secondary,
        semanticButton: false,
        onTap: () => isUnlocked ? onSelect(index) : onInspect(index),
        child: AnimatedContainer(
          duration: duration,
          curve: AppMotion.standard,
          height: height,
          width: double.infinity,
          alignment: Alignment.center,
          padding: padding,
          // 올라온 구간만 능력치 색으로 칠한다. 색이 끝나는 자리가 지금 서
          // 있는 곳이고, 그 경계가 이 화면에서 가장 중요한 정보다.
          color: isUnlocked ? colors.surface : Colors.transparent,
          child: SelectionPop(
            selected: isSelected,
            // 트랙 폭보다 크게 튀면 클립에 잘린다.
            peak: 1.12,
            child: isUnlocked
                ? _buildUnlockedSwatch(color)
                : _buildLockedSwatch(color, colors, requiredLevel),
          ),
        ),
      ),
    );
  }

  /// 고를 수 있는 색. 고른 것에는 제 색의 링과 그림자가 붙는다.
  Widget _buildUnlockedSwatch(Color color) {
    return AnimatedContainer(
      duration: duration,
      curve: AppMotion.standard,
      width: swatchSize,
      height: swatchSize,
      padding: EdgeInsets.all(isSelected ? 3.5 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: isSelected
            ? Center(
                child: Icon(
                  Icons.check_rounded,
                  size: swatchSize * 0.44,
                  color: _onColor(color),
                ),
              )
            : null,
      ),
    );
  }

  /// 잠긴 색. 필요한 레벨이 칸 안에 적혀 있다.
  Widget _buildLockedSwatch(
    Color color,
    MissionKindColors colors,
    int requiredLevel,
  ) {
    final highlight = isNextGoal || isInspected;

    return AnimatedContainer(
      duration: duration,
      curve: AppMotion.standard,
      width: swatchSize,
      height: swatchSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _lockedTint(color, highlight ? 0.34 : 0.20),
        border: Border.all(
          color: isInspected
              ? colors.accent
              : (isNextGoal
                  ? colors.accent.withValues(alpha: 0.55)
                  : Colors.transparent),
          width: isInspected ? 2 : 1.5,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: StandardText(
              text: 'Lv.$requiredLevel',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: highlight ? colors.accent : AppColors.textTertiary,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// 아래쪽 버튼 한 짝의 겉모습.
class _FooterButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Duration duration;

  const _FooterButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: background),
      duration: duration,
      curve: AppMotion.standard,
      builder: (context, animated, _) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: animated ?? background,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: StandardText(
            text: label,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: foreground,
            maxLines: 1,
          ),
        );
      },
    );
  }
}
