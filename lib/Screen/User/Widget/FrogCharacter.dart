import 'dart:math';

import 'package:flutter/material.dart';

import '../../../Module/Text/StandardText.dart';

class FrogCharacter extends StatefulWidget {
  final int level;
  final VoidCallback? onTap;

  const FrogCharacter({
    super.key,
    required this.level,
    this.onTap,
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getFrogImagePath(int level) {
    if (level >= 15) return 'assets/FrogCharacter/FROG_LEVEL15.png';
    if (level >= 13) return 'assets/FrogCharacter/FROG_LEVEL13.png';
    if (level >= 11) return 'assets/FrogCharacter/FROG_LEVEL11.png';
    if (level >= 9) return 'assets/FrogCharacter/FROG_LEVEL9.png';
    if (level >= 7) return 'assets/FrogCharacter/FROG_LEVEL7.png';
    if (level >= 5) return 'assets/FrogCharacter/FROG_LEVEL5.png';
    if (level >= 3) return 'assets/FrogCharacter/FROG_LEVEL3.png';
    if (level >= 1) return 'assets/FrogCharacter/FROG_LEVEL1.png';
    return 'assets/FrogCharacter/FROG_LEVEL1.png';
  }

  void _onCharacterTap() {
    // 애니메이션 실행
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

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

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onCharacterTap,
      child: Stack(
        alignment: Alignment.center,
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
            child: Image.asset(
              _getFrogImagePath(widget.level),
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
          // 격려 메시지
          if (_showMessage && _displayMessage != null)
            Positioned(
              top: -10,
              child: AnimatedOpacity(
                opacity: _showMessage ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: StandardText(
                    text: _displayMessage!,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
