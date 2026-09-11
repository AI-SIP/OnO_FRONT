import 'dart:math';

import 'package:flutter/material.dart';

import '../../../Model/Cosmetic/CosmeticLoadoutModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppColors.dart';

/// 개구리를 층층이 겹쳐 그리는 것만 하는 위젯이다.
///
/// 파츠가 전부 같은 512×512 좌표계로 그려져 있어서, 같은 크기의 사각형에
/// 포개기만 하면 자리가 맞는다. 오프셋을 따로 계산하지 않는다.
///
/// 누름이나 말풍선은 여기에 없다. 그게 필요하면 [FrogCharacter] 를 쓴다.
/// 레벨업 연출처럼 개구리 두 장을 겹쳐 놓고 직접 움직여야 하는 곳은 이쪽이
/// 편하다.
class FrogLayerStack extends StatelessWidget {
  /// 뒤에서 앞 순서로 겹쳐 그릴 층들. `CosmeticProvider.layers` 를 그대로 넘긴다.
  ///
  /// 비어 있으면 개구리 본체 한 장만 그린다. 치장을 아직 모르는 화면도 개구리
  /// 자리가 비어 있으면 안 된다.
  final List<CosmeticLayerModel> layers;

  /// 한 변의 길이. 정사각형이다.
  final double size;

  /// 모서리 둥글기.
  ///
  /// 배경 파츠는 투명한 데가 없는 정사각형이라 그냥 깔면 각진 판이 된다.
  /// 카드처럼 보이도록 잘라 낸다. 배경을 안 걸었으면 잘라도 보이는 변화가 없다.
  final double borderRadius;

  const FrogLayerStack({
    super.key,
    this.layers = const [],
    this.size = 180,
    this.borderRadius = AppRadius.large,
  });

  /// 실제로 그릴 층들. 비어 있으면 개구리 본체 한 장으로 메운다.
  List<CosmeticLayerModel> get _resolved => layers.isEmpty
      ? const [
          CosmeticLayerModel(
            imageUrl: CosmeticLoadoutModel.defaultBaseImageUrl,
            layerOrder: 0,
          ),
        ]
      : layers;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final layer in _resolved) _buildLayer(layer),
          ],
        ),
      ),
    );
  }

  Widget _buildLayer(CosmeticLayerModel layer) {
    final url = layer.imageUrl;
    if (url.isEmpty) return const SizedBox.shrink();

    final isNetwork = url.startsWith('http');

    return Image(
      key: ValueKey(layer.itemKey ?? 'BASE'),
      image: isNetwork
          ? NetworkImage(url) as ImageProvider<Object>
          : AssetImage(url),
      width: size,
      height: size,
      fit: BoxFit.contain,
      // 그림 한 장을 못 읽었다고 개구리가 통째로 깨지면 안 된다. 그 층만 비운다.
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

/// 마이페이지와 미션 화면에 서 있는 개구리다.
///
/// 누르면 살짝 커지면서 격려 한마디를 띄운다. 그림은 [FrogLayerStack] 이
/// 그린다.
class FrogCharacter extends StatefulWidget {
  /// 겹쳐 그릴 층들. `CosmeticProvider.layers` 를 그대로 넘긴다.
  ///
  /// 비어 있으면 개구리 본체 한 장만 그린다.
  final List<CosmeticLayerModel> layers;

  final VoidCallback? onTap;
  final double size;

  /// 눌렀을 때 격려 말풍선을 띄울지.
  ///
  /// 튜토리얼 안내처럼 개구리가 장식으로만 서 있는 자리에서는 끈다.
  final bool showEncouragement;

  /// 모서리 둥글기. [FrogLayerStack.borderRadius] 로 그대로 간다.
  final double borderRadius;

  const FrogCharacter({
    super.key,
    this.layers = const [],
    this.onTap,
    this.size = 180,
    this.showEncouragement = true,
    this.borderRadius = AppRadius.large,
  });

  @override
  State<FrogCharacter> createState() => _FrogCharacterState();
}

class _FrogCharacterState extends State<FrogCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String? _displayMessage;
  bool _showMessage = false;

  final List<String> _encouragementMessages = [
    '오늘도 화이팅!',
    '잘하고 있어요!',
    '꾸준히 성장 중이에요!',
    '대단해요!',
    '멋져요!',
    '계속 이렇게!',
    '최고예요!',
    '실수는 성공의 밑거름!',
    '지금 정말 잘하고 있어요!',
    '어제보다 더 성장했네요!',
    '개굴! 만점까지 달려볼까요?',
    '집중하는 모습에 반해버렸어요!',
    '내가 지켜보고 있어요, 화이팅!',
    '고생 많았어요. 개굴!',
    '할 수 있다! 할 수 있다!',
    '내가 항상 응원하고 있어요.'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onCharacterTap() {
    // 애니메이션 실행
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    if (widget.showEncouragement) {
      // 랜덤 메시지 표시
      setState(() {
        _displayMessage = _encouragementMessages[
            Random().nextInt(_encouragementMessages.length)];
        _showMessage = true;
      });

      // 2초 후 메시지 숨김
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showMessage = false;
          });
        }
      });
    }

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onCharacterTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 개구리 캐릭터
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: FrogLayerStack(
              layers: widget.layers,
              size: widget.size,
              borderRadius: widget.borderRadius,
            ),
          ),
          // 격려 메시지
          if (_showMessage && _displayMessage != null)
            Positioned(
              bottom: widget.size * 0.82,
              child: AnimatedOpacity(
                opacity: _showMessage ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 120,
                        maxWidth: 220,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.xlarge),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: StandardText(
                        text: _displayMessage!,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // 말풍선 꼬리
                    CustomPaint(
                      size: const Size(20, 10),
                      painter: _SpeechBubbleTailPainter(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 말풍선 꼬리를 그리는 CustomPainter
class _SpeechBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height) // 아래 끝점
      ..lineTo(size.width / 2 - 8, 0) // 왼쪽 상단
      ..lineTo(size.width / 2 + 8, 0) // 오른쪽 상단
      ..close();

    // 그림자 효과
    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.1),
      2.0,
      false,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
