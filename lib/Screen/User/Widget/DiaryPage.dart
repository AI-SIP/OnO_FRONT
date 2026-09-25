import 'package:flutter/material.dart';

import '../../../Model/Cosmetic/CosmeticLoadoutModel.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppSpacing.dart';
import '../../../Module/Emoji/OnoEmojiImage.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Text/StandardText.dart';
import 'FrogCharacter.dart';

/// 학습 달력에서 고른 날의 일기장 한 쪽이다.
///
/// 전에는 입력칸과 저장 버튼뿐이라, 저장해도 같은 입력칸이 그대로 남아
/// 일기를 썼다는 느낌이 없었다. 이제 쓴 날은 **손글씨로 줄 위에 적힌 한 쪽**
/// 으로 보이고, 끝에 개구리 도장이 찍힌다. 고치려면 `고쳐 쓰기` 를
/// 눌러야 입력칸으로 바뀐다.
///
/// 날짜마다 따로 두려면 바깥에서 날짜로 `key` 를 줘야 한다. 그래야 다른 날을
/// 고르면 쓰던 상태가 따라오지 않는다.
class DiaryPage extends StatefulWidget {
  /// 저장된 일기. 아직 불러오는 중이면 null, 안 쓴 날이면 빈 문자열이다.
  final String? savedText;

  final DateTime date;

  /// `목요일` 처럼 적힌 요일.
  final String weekdayName;

  /// 그날 고른 기분. 쪽 오른쪽 위에 스티커처럼 붙는다.
  final String? moodEmojiKey;

  /// 도장에 찍을 개구리. `CosmeticProvider.layersWithoutBackdrop` 이다.
  final List<CosmeticLayerModel> frogLayers;

  final Color primaryColor;

  /// 저장한다. 빈 문자열이면 지운다. 실패하면 false 를 돌려주고, 그러면
  /// 쓰던 글을 그대로 둔 채 입력칸에 머문다.
  final Future<bool> Function(String text) onSave;

  const DiaryPage({
    super.key,
    required this.savedText,
    required this.date,
    required this.weekdayName,
    required this.primaryColor,
    required this.frogLayers,
    required this.onSave,
    this.moodEmojiKey,
  });

  static const int maxLength = 300;

  static const Key writeButtonKey = Key('diary_write_button');
  static const Key editButtonKey = Key('diary_edit_button');
  static const Key saveButtonKey = Key('diary_save_button');
  static const Key cancelButtonKey = Key('diary_cancel_button');
  static const Key stampKey = Key('diary_stamp');

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

enum _DiaryMode { empty, reading, writing }

class _DiaryPageState extends State<DiaryPage> {
  final TextEditingController _controller = TextEditingController();
  bool _writing = false;
  bool _saving = false;

  /// 방금 저장했는지. 이때만 도장이 쾅 찍히는 모습을 보인다. 이미 써 둔 날을
  /// 열 때마다 찍히면 요란하다.
  bool _justSaved = false;

  // 일기장 종이. 흰 화면 위에서 한 장 올려 둔 것처럼 보이도록 살짝 누렇게 둔다.
  static const Color _paper = Color(0xFFFFFCF5);
  static const Color _paperEdge = Color(0xFFF0E7D6);
  static const Color _rule = Color(0xFFEDE3CF);
  static const Color _ink = Color(0xFF3D3A35);

  static const String _handFont = 'HandWrite';
  static const double _bodyFontSize = 19;
  static const double _lineFactor = 1.6;

  /// 비어 있어도 쪽이 쪽처럼 보이는 줄 수.
  static const int _minLines = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _DiaryMode get _mode {
    if (_writing) return _DiaryMode.writing;
    return (widget.savedText ?? '').isEmpty
        ? _DiaryMode.empty
        : _DiaryMode.reading;
  }

  void _startWriting() {
    _controller.text = widget.savedText ?? '';
    setState(() {
      _writing = true;
      _justSaved = false;
    });
  }

  void _cancel() {
    FocusScope.of(context).unfocus();
    setState(() => _writing = false);
  }

  Future<void> _save() async {
    // 버튼은 다시 그린 뒤에야 잠기므로, 같은 프레임에 두 번 눌린 것도 여기서 막는다.
    if (_saving) return;
    final text = _controller.text.trim();
    FocusScope.of(context).unfocus();

    // 고친 것이 없으면 저장하지 않고 읽는 모습으로 돌아간다.
    if (text == (widget.savedText ?? '')) {
      setState(() => _writing = false);
      return;
    }

    setState(() => _saving = true);
    final ok = await widget.onSave(text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) {
        _writing = false;
        _justSaved = text.isNotEmpty;
      }
    });
    if (ok && text.isNotEmpty) AppHaptic.primary();
  }

  @override
  Widget build(BuildContext context) {
    // 불러오는 동안 빈 쪽을 잠깐 보여 주면 `일기 쓰기` 가 번쩍했다 사라진다.
    if (widget.savedText == null) return const SizedBox.shrink();

    final reduced = AppMotion.isReduced(context);
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(_bodyFontSize) * _lineFactor;
    final mode = _mode;
    final body = AnimatedSwitcher(
      duration: reduced ? Duration.zero : AppMotion.normal,
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, if (current != null) current],
      ),
      child: KeyedSubtree(
        key: ValueKey(mode),
        child: switch (mode) {
          _DiaryMode.empty => _buildEmpty(lineHeight),
          _DiaryMode.reading => _buildReading(lineHeight, reduced),
          _DiaryMode.writing => _buildWriting(lineHeight),
        },
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: _paperEdge),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A6D3B).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.md),
              // 동작 줄이기를 켰으면 AnimatedSize 를 아예 뺀다. 길이 0 으로 두면
              // 자기 레이아웃 도중에 다시 레이아웃을 요청해 오류가 난다.
              if (reduced)
                body
              else
                AnimatedSize(
                  duration: AppMotion.normal,
                  curve: AppMotion.emphasized,
                  alignment: Alignment.topCenter,
                  child: body,
                ),
            ],
          ),
        ),
        // 쪽 위쪽 가운데에 붙인 마스킹테이프.
        Positioned(
          top: -7,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                width: 68,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StandardText(
                text: '${widget.date.month}월 ${widget.date.day}일',
                fontSize: 24,
                fontFamily: _handFont,
                fontWeight: FontWeight.normal,
                color: _ink,
                height: 1.2,
              ),
              const SizedBox(height: 2),
              StandardText(
                text: '${widget.weekdayName}의 일기',
                fontSize: 11,
                color: AppColors.textTertiary,
                height: 1.3,
              ),
            ],
          ),
        ),
        if (widget.moodEmojiKey != null)
          Transform.rotate(
            angle: 0.14,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: OnoEmojiImage(emojiKey: widget.moodEmojiKey, size: 34),
            ),
          ),
      ],
    );
  }

  TextStyle get _bodyStyle => const TextStyle(
        fontFamily: _handFont,
        fontSize: _bodyFontSize,
        height: _lineFactor,
        color: _ink,
      );

  /// 글줄마다 줄이 맞게 줄 높이를 억지로 고정한다. 손글씨 글꼴에 없는 글자가
  /// 다른 글꼴로 대신 그려지면 그 줄만 높아져 밑줄과 어긋난다.
  StrutStyle get _strut => const StrutStyle(
        fontFamily: _handFont,
        fontSize: _bodyFontSize,
        height: _lineFactor,
        forceStrutHeight: true,
      );

  Widget _ruled({required double lineHeight, required Widget child}) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: lineHeight * _minLines),
      child: CustomPaint(
        painter: _RulePainter(lineHeight: lineHeight, color: _rule),
        child: child,
      ),
    );
  }

  Widget _buildEmpty(double lineHeight) {
    return PressableScale(
      onTap: _startWriting,
      scale: 1,
      semanticButton: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ruled(
            lineHeight: lineHeight,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                '이 날은 어떤 하루였나요?',
                style: _bodyStyle.copyWith(color: AppColors.textDisabled),
                strutStyle: _strut,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: _PillButton(
              key: DiaryPage.writeButtonKey,
              icon: Icons.edit_rounded,
              label: '일기 쓰기',
              color: widget.primaryColor,
              filled: true,
              onTap: _startWriting,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReading(double lineHeight, bool reduced) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ruled(
          lineHeight: lineHeight,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              widget.savedText!,
              style: _bodyStyle,
              strutStyle: _strut,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _PillButton(
              key: DiaryPage.editButtonKey,
              icon: Icons.edit_outlined,
              label: '고쳐 쓰기',
              color: widget.primaryColor,
              onTap: _startWriting,
            ),
            const Spacer(),
            _FrogStamp(
              key: DiaryPage.stampKey,
              layers: widget.frogLayers,
              color: widget.primaryColor,
              animate: _justSaved && !reduced,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWriting(double lineHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ruled(
          lineHeight: lineHeight,
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLength: DiaryPage.maxLength,
            minLines: _minLines,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: _bodyStyle,
            strutStyle: _strut,
            cursorColor: widget.primaryColor,
            // 글자 수는 아래 줄에 따로 적는다. 기본 카운터는 줄 사이에 끼어 든다.
            buildCounter: (_,
                    {required currentLength,
                    required isFocused,
                    required maxLength}) =>
                null,
            decoration: InputDecoration.collapsed(
              hintText: '이 날은 어떤 하루였나요?',
              hintStyle: _bodyStyle.copyWith(color: AppColors.textDisabled),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (_, value, __) => StandardText(
                text: '${value.text.characters.length}/${DiaryPage.maxLength}',
                fontSize: 11,
                color: AppColors.textTertiary,
                height: 1.2,
              ),
            ),
            const Spacer(),
            _PillButton(
              key: DiaryPage.cancelButtonKey,
              label: '취소',
              color: AppColors.textSecondary,
              onTap: _saving ? null : _cancel,
            ),
            const SizedBox(width: AppSpacing.sm),
            _PillButton(
              key: DiaryPage.saveButtonKey,
              label: '저장',
              color: widget.primaryColor,
              filled: true,
              onTap: _saving ? null : _save,
            ),
          ],
        ),
      ],
    );
  }
}

/// 일기장의 가로줄. 글줄 하나마다 그 아래에 한 줄씩 긋는다.
class _RulePainter extends CustomPainter {
  final double lineHeight;
  final Color color;

  const _RulePainter({required this.lineHeight, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (lineHeight <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    // 손글씨는 줄 칸 바닥보다 조금 위에 앉는다. 칸 바닥에 그으면 글자와 줄
    // 사이가 떠 보여서 살짝 끌어올린다.
    final lift = lineHeight * 0.08;
    for (var y = lineHeight - lift; y <= size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RulePainter old) =>
      old.lineHeight != lineHeight || old.color != color;
}

/// 일기 끝에 찍는 개구리 도장. 방금 저장했으면 크게 내려와 쾅 찍힌다.
class _FrogStamp extends StatelessWidget {
  final List<CosmeticLayerModel> layers;
  final Color color;
  final bool animate;

  const _FrogStamp({
    super.key,
    required this.layers,
    required this.color,
    required this.animate,
  });

  static const double _size = 58;

  @override
  Widget build(BuildContext context) {
    final stamp = Transform.rotate(
      angle: -0.18,
      child: Container(
        width: _size,
        height: _size,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: FrogHeadAvatar(layers: layers, size: _size * 0.62),
        ),
      ),
    );

    if (!animate) return stamp;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow,
      curve: AppMotion.emphasized,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 1.8 - 0.8 * t, child: child),
      ),
      child: stamp,
    );
  }
}

/// 일기장 아래에 놓는 작은 알약 버튼.
class _PillButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  const _PillButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final foreground = filled ? Colors.white : color;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: PressableScale(
        onTap: onTap,
        enabled: enabled,
        child: Container(
          // 위아래 여백은 손가락으로 누르기 모자라지 않은 높이(36 언저리)에 맞춘다.
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: filled ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 4),
              ],
              StandardText(
                text: label,
                fontSize: 13,
                color: foreground,
                height: 1.3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
