import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Cosmetic/CosmeticItemModel.dart';
import '../../Model/Cosmetic/CosmeticSlotModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Design/AppToast.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossDialog.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/CosmeticProvider.dart';
import 'CosmeticCombinationPreviewScreen.dart';
import 'Widget/CosmeticCollectionMeter.dart';
import 'Widget/CosmeticDebugLevelPanel.dart';
import 'Widget/CosmeticItemTile.dart';
import 'Widget/CosmeticNextUnlockCard.dart';
import 'Widget/CosmeticSlotTabs.dart';
import 'Widget/CosmeticStage.dart';

/// 개구리를 꾸미는 화면이다.
///
/// 화면은 두 층이다. 위에는 개구리가 **붙박이로** 있고, 아래에서 자리를 골라
/// 아이템을 갈아 끼운다. 무엇을 눌러도 위쪽 개구리가 바로 바뀌는 것이 이
/// 화면의 전부라서, 개구리는 스크롤을 따라 사라지지 않는다.
///
/// 예전에는 개구리 아래에 레벨 슬라이더가 하나 붙박이로 있었다. 해금이
/// 능력치별로 갈리면서 조절할 것이 다섯이 됐고, 다섯을 다 세우면 개구리보다
/// 조절기가 큰 화면이 된다. 접이식 [CosmeticDebugLevelPanel] 로 옮겨 접어
/// 뒀고 [kDebugMode] 에서만 들어간다. 출시본에는 이 줄이 아예 없다.
///
/// **시착하는 화면이다.** 아이템을 눌러도 그 자리에서 확정되지 않는다. 고른
/// 것은 이 화면이 [_fitting] 에 들고 있다가 **저장**을 눌러야
/// [CosmeticProvider] 로 넘어간다. 그냥 나가면 원래 차림으로 돌아가고, 바뀐
/// 것이 있는데 나가려 하면 한 번 물어본다.
///
/// 시착 중인 차림을 프로바이더에 넣지 않는 데는 이유가 있다. 하단 탭 아이콘과
/// 프로필 사진이 프로바이더의 개구리를 보고 있어서, 입어 보는 중에 그것들까지
/// 따라 바뀌면 아직 정하지도 않은 차림이 앱 전체에 퍼진다.
///
/// 서버를 타지 않는다. 카탈로그도 장착 상태도 [CosmeticProvider] 가 더미로
/// 들고 있다.
class CosmeticClosetScreen extends StatefulWidget {
  const CosmeticClosetScreen({super.key});

  @override
  State<CosmeticClosetScreen> createState() => _CosmeticClosetScreenState();
}

class _CosmeticClosetScreenState extends State<CosmeticClosetScreen> {
  /// 지금 보고 있는 자리. [CosmeticProvider.slots] 의 순번이다.
  int _slotIndex = 0;

  /// 갈아입은 횟수. 개구리를 한 번 들썩이게 하는 신호로만 쓴다.
  int _equipTick = 0;

  /// 지금 입어 보고 있는 차림. 슬롯 키 → 아이템 키.
  ///
  /// null 이면 아직 아무것도 안 만졌다는 뜻이라 프로바이더의 차림을 그대로
  /// 따른다. 저장하거나 되돌리면 다시 null 이 된다.
  Map<String, String>? _fitting;

  /// 화면에 그릴 차림. 못 쓰게 된 것은 매번 걷어 낸다.
  ///
  /// 시착하는 동안 레벨 슬라이더를 내리거나 전체 해금을 끄면 방금 입어 본 것이
  /// 못 가진 것이 된다. 그 판정은 프로바이더가 한다.
  Map<String, String> _fittingOf(CosmeticProvider cosmetic) =>
      cosmetic.usableOf(_fitting ?? cosmetic.equipped);

  /// 저장할 것이 있는지. 없으면 저장 줄을 아예 띄우지 않는다.
  bool _isDirty(CosmeticProvider cosmetic) =>
      !mapEquals(_fittingOf(cosmetic), cosmetic.equipped);

  /// 아이템 칸을 눌렀을 때.
  ///
  /// 가진 것이면 걸치고, 이미 걸쳐 둔 것을 다시 누르면 벗는다. 못 가진 것도
  /// 눌리기는 한다. 왜 안 되는지를 프로바이더에 물어 알림으로 띄운다. 알림은
  /// 화면 위를 덮지 않아서 계속 다른 것을 눌러 볼 수 있다.
  void _onItemTap(
    CosmeticProvider cosmetic,
    CosmeticSlotModel slot,
    CosmeticItemModel item,
  ) {
    if (!item.owned) {
      AppHaptic.secondary();
      final reason = cosmetic.lockReasonOf(item.itemKey);
      if (reason != null) AppToast.info(reason);
      return;
    }

    AppHaptic.selection();
    final current = _fittingOf(cosmetic);
    final worn = current[slot.slot] == item.itemKey;
    _wear(
      cosmetic.previewEquip(
        current,
        slot: slot.slot,
        itemKey: worn ? null : item.itemKey,
      ),
    );
  }

  /// 자리를 비운다. 이미 비어 있으면 아무 일도 하지 않는다.
  void _onEmptyTap(CosmeticProvider cosmetic, CosmeticSlotModel slot) {
    final current = _fittingOf(cosmetic);
    if (current[slot.slot] == null) return;

    AppHaptic.selection();
    _wear(cosmetic.previewEquip(current, slot: slot.slot, itemKey: null));
  }

  /// 걸친 것을 전부 벗는다. 이것도 시착이라 저장해야 진짜로 벗겨진다.
  void _onResetTap(CosmeticProvider cosmetic) {
    if (_fittingOf(cosmetic).isEmpty) return;

    AppHaptic.selection();
    _wear(const {});
  }

  /// 시착 차림을 갈아 끼우고 개구리를 한 번 들썩이게 한다.
  void _wear(Map<String, String> next) {
    if (!mounted) return;
    setState(() {
      _fitting = next;
      _equipTick++;
    });
  }

  /// 저장한다. 여기서야 하단 탭 아이콘과 프로필 사진까지 바뀐다.
  void _onSaveTap(CosmeticProvider cosmetic) {
    AppHaptic.primary();
    cosmetic.save(_fittingOf(cosmetic));
    setState(() => _fitting = null);
    AppToast.success('새 차림으로 갈아입었어요.');
  }

  /// 입어 본 것을 버리고 원래 차림으로 돌아간다.
  void _onRevertTap() {
    AppHaptic.selection();
    setState(() {
      _fitting = null;
      _equipTick++;
    });
  }

  /// 저장하지 않고 나가려 할 때 한 번 물어본다.
  ///
  /// 여러 개를 걸쳐 보고 나서 뒤로 가기를 누르면 그동안 고른 것이 통째로
  /// 사라진다. 되돌릴 수 없는 일이라 한 번 막는다.
  Future<bool> _confirmDiscard(Color color) async {
    final leave = await showTossDialog<bool>(
      context: context,
      builder: (dialogContext) => _DiscardDialog(color: color),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    // LayoutBuilder 안에서는 watch 가 듣지 않는다. build 최상단에서 받는다.
    final cosmetic = context.watch<CosmeticProvider>();

    final slots = cosmetic.slots;
    final slotIndex = slots.isEmpty ? 0 : _slotIndex.clamp(0, slots.length - 1);
    final fitting = _fittingOf(cosmetic);
    final dirty = _isDirty(cosmetic);

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // 창을 띄우고 나서 돌아오면 context 가 이미 죽어 있을 수 있다.
        // 돌아갈 길은 물어보기 전에 잡아 둔다.
        final navigator = Navigator.of(context);
        final leave = await _confirmDiscard(themeProvider.primaryColor);
        if (!leave) return;
        navigator.pop();
      },
      child: _buildScaffold(
        themeProvider: themeProvider,
        cosmetic: cosmetic,
        slots: slots,
        slotIndex: slotIndex,
        fitting: fitting,
        dirty: dirty,
      ),
    );
  }

  Widget _buildScaffold({
    required ThemeHandler themeProvider,
    required CosmeticProvider cosmetic,
    required List<CosmeticSlotModel> slots,
    required int slotIndex,
    required Map<String, String> fitting,
    required bool dirty,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: StandardText(
          text: '꾸미기',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
        actions: [
          // 능력치 넷을 골고루 올려 둔 사람은 드물어서 기본 레벨에서는
          // 쉰다섯 중 절반쯤만 열린다. 시안을 보는 동안은 전부 입어 볼 수
          // 있어야 해서 잠금을 통째로 푸는 스위치를 둔다. 출시본에는 이
          // 버튼이 아예 없다.
          if (kDebugMode)
            IconButton(
              icon: Icon(
                cosmetic.unlockAll
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline_rounded,
                color: cosmetic.unlockAll
                    ? themeProvider.primaryColor
                    : AppColors.textSecondary,
              ),
              tooltip: cosmetic.unlockAll ? '잠금 되돌리기' : '전부 입어 보기',
              onPressed: () {
                final next = !cosmetic.unlockAll;
                cosmetic.setUnlockAll(next);
                AppHaptic.selection();
                AppToast.show(
                  message: next ? '잠긴 아이템까지 전부 열었어요.' : '레벨대로 다시 잠갔어요.',
                  context: context,
                );
              },
            ),
          // 조합이 자리 수의 곱으로 늘어나서 옷장에서 하나씩 입혀 보는 것으로는
          // 겹침이 이상한 짝을 찾을 수 없다. 한꺼번에 펼쳐 보는 화면을 개발
          // 중에만 열어 둔다. 출시본에는 이 버튼이 아예 없다.
          if (kDebugMode)
            IconButton(
              icon: Icon(
                Icons.grid_view_rounded,
                color: themeProvider.primaryColor,
              ),
              tooltip: '조합 검수',
              onPressed: () => Navigator.push(
                context,
                TossPageRoute(
                  builder: (_) => const CosmeticCombinationPreviewScreen(),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 개구리는 화면이 좁으면 너비를, 낮으면 높이를 따라간다. 위쪽이
            // 붙박이라서 개구리가 크면 아래 아이템 자리가 없어진다.
            final frogSize = _frogSizeFor(constraints);

            return Center(
              child: ConstrainedBox(
                // 태블릿에서 격자가 끝없이 넓어지지 않게 가운데로 모은다.
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        0,
                        AppSpacing.screenHorizontal,
                        AppSpacing.md,
                      ),
                      child: Column(
                        children: [
                          _buildStage(
                            cosmetic,
                            themeProvider,
                            frogSize,
                            fitting,
                          ),
                          if (kDebugMode) _buildDebugLevels(cosmetic),
                          const SizedBox(height: AppSpacing.md),
                          CosmeticSlotTabs(
                            slots: slots,
                            index: slotIndex,
                            color: themeProvider.primaryColor,
                            onChanged: (index) =>
                                setState(() => _slotIndex = index),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: slots.isEmpty
                          ? _buildEmpty()
                          : _buildSlotItems(
                              cosmetic,
                              slots[slotIndex],
                              themeProvider.primaryColor,
                              fitting,
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      // 저장할 것이 있을 때만 아래에서 줄 하나가 올라온다. 늘 자리를 차지하고
      // 있으면 아이템 격자가 그만큼 좁아지고, 눌러도 아무 일이 없는 버튼을
      // 계속 보게 된다.
      bottomNavigationBar: AnimatedSize(
        duration: AppMotion.normal,
        curve: AppMotion.emphasized,
        alignment: Alignment.topCenter,
        child: dirty
            ? _buildSaveBar(cosmetic, themeProvider.primaryColor)
            : const SizedBox(width: double.infinity),
      ),
    );
  }

  /// 입어 본 것을 확정하거나 버리는 줄.
  Widget _buildSaveBar(CosmeticProvider cosmetic, Color color) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.md,
            AppSpacing.screenHorizontal,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              PressableScale(
                onTap: _onRevertTap,
                haptic: HapticLevel.none,
                scale: 0.94,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: StandardText(
                    text: '되돌리기',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PressableScale(
                  onTap: () => _onSaveTap(cosmetic),
                  haptic: HapticLevel.none,
                  scale: 0.97,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded,
                              size: 18, color: Colors.white),
                          SizedBox(width: AppSpacing.sm),
                          StandardText(
                            text: '저장',
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 개구리가 서는 자리. 이 화면의 주인공이다.
  ///
  /// 바탕은 위가 밝고 아래로 갈수록 테마색이 도는 세로 그라데이션이다. 위에서
  /// 빛이 들어오고 아래가 바닥인 무대의 결이라, 그 위에 선 개구리가 조각이
  /// 아니라 장면으로 읽힌다. 빛무리와 바닥 그림자는
  /// [CosmeticStageFrog] 가 그린다.
  ///
  /// 금색 같은 별도의 장식색을 쓰지 않는다. 그러면 이 화면만 앱에서 겉돈다.
  Widget _buildStage(
    CosmeticProvider cosmetic,
    ThemeHandler themeProvider,
    double frogSize,
    Map<String, String> fitting,
  ) {
    final color = themeProvider.primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(color.withValues(alpha: 0.05), Colors.white),
            Color.alphaBlend(color.withValues(alpha: 0.13), Colors.white),
            Color.alphaBlend(color.withValues(alpha: 0.20), Colors.white),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        // 무대가 바닥에서 살짝 떠 보이게 한다. 카드가 아니라 장면이라는
        // 신호라서 테마색 그림자를 옅게 쓴다.
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 수집률과 되돌리기는 개구리 위에 겹치지 않게 한 줄을 따로 쓴다.
          // 겹쳐 두면 배경을 입은 개구리의 모서리를 가린다.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CosmeticCollectionMeter(
                  owned: cosmetic.items.where((item) => item.owned).length,
                  total: cosmetic.items.length,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _buildResetButton(cosmetic, color),
            ],
          ),
          // 게이지 바로 아래에 개구리를 붙여 두면 둘이 한 덩어리로 읽혀서
          // 무대가 좁아 보인다. 눈에 띄게 벌려 게이지는 머리말, 개구리는
          // 무대 위 주인공으로 갈라 놓는다.
          const SizedBox(height: AppSpacing.xl),
          CosmeticStageFrog(
            // 저장하기 전에도 개구리는 바로 갈아입는다. 그래야 써 보는
            // 의미가 있다. 바뀌지 않는 것은 하단 탭과 프로필의 개구리다.
            layers: cosmetic.layersOf(fitting),
            size: frogSize,
            color: color,
            equipTick: _equipTick,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  /// 이것저것 입혀 보다 엉망이 됐을 때 돌아올 자리.
  ///
  /// 지금 레벨에서 자동으로 입게 되는 차림으로 되돌린다. 개구리 옆에 두는
  /// 이유는, 되돌린 결과가 바로 그 자리에서 보여야 무엇이 일어났는지 알기
  /// 때문이다.
  Widget _buildResetButton(CosmeticProvider cosmetic, Color color) {
    return PressableScale(
      onTap: () => _onResetTap(cosmetic),
      haptic: HapticLevel.none,
      scale: 0.92,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
            StandardText(
              text: '전부 벗기',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  /// 개구리 한 변의 길이. 좁은 쪽과 낮은 쪽 중 더 빡빡한 쪽을 따른다.
  double _frogSizeFor(BoxConstraints constraints) {
    final byWidth = constraints.maxWidth * 0.50;
    final byHeight = constraints.maxHeight * 0.28;
    final smaller = byWidth < byHeight ? byWidth : byHeight;
    // 태블릿에서는 폭이 남아도 여기서 멈춘다. 더 키우면 아이템 격자가 첫
    // 화면에서 사라진다. 무대가 주인공이 되면서 280 으로는 넓은 무대 한가운데
    // 작은 조각이 놓인 것처럼 보여 한 단계 키웠다.
    return smaller.clamp(96.0, 340.0);
  }

  /// **디버그 전용.** 능력치 레벨 다섯을 직접 옮겨 보는 접이식 패널.
  ///
  /// 시안의 절반이 여기 달려 있다. 출석만 올린 사람과 복습만 한 사람이 각각
  /// 무엇을 보게 되는지, 잠긴 칸에 적히는 조건이 어떻게 읽히는지를 이걸로
  /// 훑는다. 실제 출시 화면에는 들어가지 않는다.
  Widget _buildDebugLevels(CosmeticProvider cosmetic) {
    return CosmeticDebugLevelPanel(
      levels: cosmetic.levels,
      onChanged: cosmetic.setMockLevel,
      onReplaced: cosmetic.setMockLevels,
    );
  }

  /// 고른 자리의 아이템들.
  ///
  /// 자리를 옮기면 격자가 옅게 갈린다. 자리마다 아이템 수가 달라서 목록을
  /// 그대로 바꾸면 화면이 툭 끊긴다.
  Widget _buildSlotItems(
    CosmeticProvider cosmetic,
    CosmeticSlotModel slot,
    Color color,
    Map<String, String> fitting,
  ) {
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      // 페이드만 한다. 크기를 건드리면 격자 가장자리에 틈이 생긴다.
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      child: KeyedSubtree(
        key: ValueKey<String>(slot.slot),
        child: _buildGrid(cosmetic, slot, color, fitting),
      ),
    );
  }

  Widget _buildGrid(
    CosmeticProvider cosmetic,
    CosmeticSlotModel slot,
    Color color,
    Map<String, String> fitting,
  ) {
    final items = cosmetic.itemsOfSlot(slot.slot);
    // 격자의 체크 표시는 **지금 입어 보고 있는 것**을 따른다. 저장한 차림이
    // 아니라 눈앞의 개구리와 같은 것을 가리켜야 한다.
    final equippedKey = fitting[slot.slot];
    final backdrop = _isBackdrop(cosmetic.slots, slot);
    // 지금 레벨에서 막 열린 것들. 쉰다섯 칸을 눈으로 훑어 무엇이 늘었는지
    // 찾게 하면 안 된다. 능력치가 넷으로 갈린 뒤로 "이번 레벨"이 하나가
    // 아니어서, 넷 중 어느 쪽을 올렸든 그쪽에서 막 열린 것에 붙는다.
    final newKeys = <String>{
      for (final item in cosmetic.justUnlocked) item.itemKey,
    };

    final tiles = <Widget>[
      CosmeticSlotEmptyTile(
        selected: equippedKey == null,
        color: color,
        onTap: () => _onEmptyTap(cosmetic, slot),
      ),
      for (final item in items)
        CosmeticItemTile(
          item: item,
          equipped: item.itemKey == equippedKey,
          backdrop: backdrop,
          isNew: newKeys.contains(item.itemKey),
          color: color,
          onTap: () => _onItemTap(cosmetic, slot, item),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // 칸 하나가 120 언저리가 되게 나눈다. 폰은 셋, 태블릿은 여섯까지.
        final columns = (constraints.maxWidth / 118).floor().clamp(3, 6);

        return CustomScrollView(
          slivers: [
            // 격자보다 먼저 온다. 잠긴 칸을 훑기 전에 "다음은 이것"이 눈에
            // 들어와야 격자가 모으는 중인 목록으로 읽힌다.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xs,
                AppSpacing.screenHorizontal,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: AppearTransition(
                  child: CosmeticNextUnlockCard(
                    items: items,
                    slotName: slot.nameKo,
                    backdrop: backdrop,
                    color: color,
                    levels: cosmetic.levels,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xs,
                AppSpacing.screenHorizontal,
                AppSpacing.xxl,
              ),
              sliver: SliverGrid.count(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                // 정사각 그림 아래에 이름 한 줄이 들어갈 만큼만 더 길다.
                childAspectRatio: 0.82,
                children: AppearTransition.stagger(tiles, maxStaggered: 6),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 개구리 **뒤에** 깔리는 자리인지.
  ///
  /// 가장 뒤에 그려지는 자리가 배경이다. 슬롯 키를 박아 두지 않는 이유는
  /// 자리 이름이 서버가 정하는 값이기 때문이다. 그리는 순서만 보면 된다.
  bool _isBackdrop(List<CosmeticSlotModel> slots, CosmeticSlotModel slot) {
    var lowest = slot.layerOrder;
    for (final entry in slots) {
      if (entry.layerOrder < lowest) lowest = entry.layerOrder;
    }
    return slot.layerOrder == lowest;
  }

  /// 자리 자체가 하나도 없을 때. 더미에서는 나지 않지만 서버가 붙으면 난다.
  Widget _buildEmpty() {
    return const Center(
      child: StandardText(
        text: '아직 꾸밀 수 있는 것이 없어요.',
        fontSize: 13,
        color: AppColors.textTertiary,
        textAlign: TextAlign.center,
        maxLines: 2,
      ),
    );
  }
}

/// 저장하지 않고 나가려 할 때 뜨는 확인 창.
///
/// 스터디룸의 확인 창과 같은 틀이다. 여러 개를 걸쳐 보고 나서 뒤로 가기를
/// 누르면 그동안 고른 것이 통째로 사라지는데, 되돌릴 수 없는 일이라 한 번
/// 막는다. 겁주는 일이 아니라서 빨간색을 쓰지 않는다.
class _DiscardDialog extends StatelessWidget {
  final Color color;

  const _DiscardDialog({required this.color});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child:
                        Icon(Icons.checkroom_rounded, color: color, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Flexible(
                    child: StandardText(
                      text: '저장하지 않고 나갈까요?',
                      fontSize: 17,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const StandardText(
                text: '입어 본 차림은 저장하지 않으면 사라져요.',
                fontSize: 14,
                color: AppColors.textSecondary,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.normal,
                fontFamily: 'PretendardLight',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.surfaceMuted,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                      ),
                      child: const StandardText(
                        text: '계속 꾸미기',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                      ),
                      child: const StandardText(
                        text: '나가기',
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
