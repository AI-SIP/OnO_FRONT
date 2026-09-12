import 'package:flutter/material.dart';

import '../../../Model/Cosmetic/CosmeticLoadoutModel.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../User/Widget/FrogCharacter.dart';

/// 무대 바닥이다. 개구리가 **액자가 아니라 장면 위에** 서게 만든다.
///
/// 배경 파츠는 512 정사각형 그림이다. 개구리 사각형에 같이 깔면 자리는 딱
/// 맞지만, 둥근 사각형에 갇힌 512 그림은 캐릭터가 선 무대가 아니라 **벽에
/// 걸린 사진 한 장**으로 보인다. 3D 로 렌더한 일러스트가 납작한 UI 카드 안에
/// 박혀 있으니 화면의 나머지와 톤도 안 맞는다. 그리고 그 그림이 무대가 깔아
/// 둔 조명과 바닥 그림자를 통째로 덮어서, 공들여 넣은 연출이 화면에 나오지도
/// 않았다.
///
/// 그래서 배경 한 장만 개구리에게서 떼어 **무대 영역 전체에 깐다.**
///
/// - **걸쳤을 때**: 폭이 아니라 높이에 맞춰 채운다([BoxFit.cover]). 정사각형
///   그림을 세로로 긴 무대에 넣으면 좌우가 잘리는 대신 하늘에서 바닥까지가
///   온전히 남는다. 위아래를 자르면 지평선이 어디로든 밀려서 개구리 발밑이
///   안 맞는다. 아래쪽에 붙여 두므로 **그림의 바닥이 무대의 바닥**이고, 그
///   위에 선 개구리의 발치가 그대로 지면이 된다.
/// - **안 걸쳤을 때**: 무대의 테마색 그라데이션이 그대로 보인다. 위아래가
///   똑같은 면이면 개구리가 허공에 뜬 조각으로 보이므로, 아래쪽에 같은
///   테마색을 한 겹 더 깔아 지평선을 만든다.
///
/// 배경을 걸쳤을 때 위쪽만 하얗게 덮는 것은 성장 카드가 앉을 자리를 만들기
/// 위해서다. 밤하늘이나 우주를 걸치면 사진 위에 바로 앉은 흰 카드의 글자가
/// 읽히지 않는다. 개구리가 선 아래쪽은 사진 그대로 둔다.
class CosmeticStageGround extends StatelessWidget {
  /// 깔아 둘 배경 파츠. `CosmeticProvider.stageBackdrop` 을 그대로 넘긴다.
  /// null 이면 지평선만 그린다.
  final CosmeticLayerModel? backdrop;

  /// 강조색. 사용자가 테마에서 고른 색이다.
  final Color color;

  const CosmeticStageGround({
    super.key,
    required this.backdrop,
    required this.color,
  });

  /// 지평선이 차지하는 높이의 비율.
  static const double _horizonFactor = 0.34;

  @override
  Widget build(BuildContext context) {
    final layer = backdrop;
    if (layer == null || layer.imageUrl.isEmpty) return _buildHorizon();

    final url = layer.imageUrl;
    final isNetwork = url.startsWith('http');

    return Stack(
      fit: StackFit.expand,
      children: [
        Image(
          image: isNetwork
              ? NetworkImage(url) as ImageProvider<Object>
              : AssetImage(url),
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          // 배경 한 장을 못 읽었다고 무대가 비면 안 된다. 지평선으로 돌아간다.
          errorBuilder: (context, error, stackTrace) => _buildHorizon(),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.72),
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.44],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 배경을 안 걸쳤을 때 개구리가 설 자리.
  Widget _buildHorizon() {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: _horizonFactor,
          widthFactor: 1.0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.0),
                  color.withValues(alpha: 0.16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 개구리가 서 있는 무대다.
///
/// 옷장의 주인공은 격자가 아니라 개구리다. 그런데 파츠 그림에는 투명한 데가
/// 많아서 흰 바탕에 그냥 두면 개구리가 허공에 뜬 조각처럼 보인다. 세 가지를
/// 겹쳐서 "서 있는" 그림으로 만든다.
///
/// 1. **빛무리**: 개구리 뒤에 흰 원을 옅게 깐다. 무대 바탕이 테마색으로
///    물들어 있어서, 그 위에 흰 원이 얹히면 위에서 조명을 받은 것처럼 보인다.
/// 2. **바닥**: 개구리 발치에 납작한 타원을 깐다. 아래쪽 절반이 개구리
///    사각형 밖으로 나와서, 배경 파츠를 걸었을 때는 카드 밑 그림자로, 안
///    걸었을 때는 발밑 그림자로 읽힌다.
/// 3. **들썩임**: 갈아입을 때마다 한 번 커졌다 돌아온다.
///
/// 금색 같은 별도의 장식색을 쓰지 않는다. 그러면 이 화면만 앱에서 겉돈다.
/// 쓰는 색은 사용자가 테마에서 고른 색 하나뿐이다.
class CosmeticStageFrog extends StatelessWidget {
  /// 겹쳐 그릴 층들. `CosmeticProvider.layers` 를 그대로 넘긴다.
  final List<CosmeticLayerModel> layers;

  /// 개구리 한 변의 길이.
  final double size;

  /// 강조색. 사용자가 테마에서 고른 색이다.
  final Color color;

  /// 갈아입은 횟수. 이 값이 바뀔 때마다 개구리가 한 번 들썩인다.
  final int equipTick;

  /// 개구리를 눌렀을 때. null 이면 누름이 아무 데도 가지 않는다.
  ///
  /// 옷장에서는 이미 꾸미는 자리에 와 있어서 갈 데가 없다. 캐릭터 탭처럼
  /// 무대만 빌려 쓰는 화면이 옷장으로 가는 문으로 쓴다.
  final VoidCallback? onTap;

  /// 눌렀을 때 격려 말풍선을 띄울지.
  ///
  /// 옷장 무대에서만 켠다. 누름이 옷장으로 가는 문인 자리에서는 한 번 누를
  /// 때 두 가지 일이 일어나면 안 된다.
  final bool showEncouragement;

  const CosmeticStageFrog({
    super.key,
    required this.layers,
    required this.size,
    required this.color,
    required this.equipTick,
    this.onTap,
    this.showEncouragement = true,
  });

  /// 바닥 타원의 높이. 개구리 크기를 따라간다.
  double get _floorHeight => size * 0.085;

  @override
  Widget build(BuildContext context) {
    final floorHeight = _floorHeight;

    return SizedBox(
      // 빛무리가 개구리보다 넓어서 자리를 조금 더 준다. 개구리 크기에
      // 비례하므로 폰과 태블릿에서 같은 비율로 보인다.
      width: size * 1.18,
      // 바닥 타원의 아래쪽 절반만 개구리 사각형 밖으로 내보낸다.
      height: size + floorHeight * 0.45,
      child: Stack(
        alignment: Alignment.topCenter,
        // 격려 말풍선이 개구리 위로 넘어간다. 잘리면 안 된다.
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: Center(child: _buildGlow())),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(child: _buildFloor(floorHeight)),
          ),
          _EquipPulse(
            tick: equipTick,
            // 격려 말풍선은 이제 여기서만 뜬다. 마이페이지와 미션의 개구리는
            // 누르면 이 화면으로 오는 문이라서 말풍선을 띄우지 않는다. 대신
            // 꾸미러 온 자리에서 개구리가 한마디 하는 쪽이 어울린다.
            child: FrogCharacter(
              layers: layers,
              size: size,
              borderRadius: AppRadius.large,
              showEncouragement: showEncouragement,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }

  /// 개구리 뒤에 깔리는 빛무리.
  Widget _buildGlow() {
    return IgnorePointer(
      child: Container(
        width: size * 1.10,
        height: size * 1.10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.72),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.30, 0.92],
          ),
        ),
      ),
    );
  }

  /// 개구리 발치의 바닥 그림자.
  ///
  /// 동그란 그라데이션을 납작하게 눌러서 만든다. `RadialGradient` 의 반지름은
  /// **상자의 짧은 변**을 기준으로 재기 때문에, 납작한 상자에 그대로 넣으면
  /// 가운데에 점만 찍힌다. 정사각형에 그린 뒤 통째로 눌러야 타원이 된다.
  Widget _buildFloor(double height) {
    return IgnorePointer(
      child: SizedBox(
        width: size * 0.70,
        height: height,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: 100,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.34),
                    color.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.85],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 갈아입을 때마다 개구리가 한 번 들썩인다.
///
/// 파츠가 소리 없이 바뀌면 눌린 것이 화면에 반영됐는지 애매하다. 아주 살짝
/// 커졌다 돌아오면 방금 그 자리에서 일어난 일이라는 것이 손끝과 이어진다.
class _EquipPulse extends StatefulWidget {
  /// 이 값이 바뀔 때마다 한 번 재생한다.
  final int tick;

  final Widget child;

  const _EquipPulse({required this.tick, required this.child});

  @override
  State<_EquipPulse> createState() => _EquipPulseState();
}

class _EquipPulseState extends State<_EquipPulse>
    with SingleTickerProviderStateMixin {
  // 늦게 만들지 않는다. "동작 줄이기"를 켠 기기에서 build 가 컨트롤러를
  // 건드리지 않고 끝나면, dispose 가 그제서야 만들면서 죽는다.
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.normal);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: AppMotion.enter)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: AppMotion.emphasized)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _EquipPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tick != widget.tick) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReduced(context)) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
