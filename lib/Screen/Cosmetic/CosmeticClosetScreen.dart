import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/CosmeticProvider.dart';
import '../User/Widget/FrogCharacter.dart';

/// 개구리 옷장이다.
///
/// **아직 뼈대다.** 지금은 개구리 미리보기와 레벨 슬라이더만 있다. 슬롯별 탭과
/// 아이템 목록은 옷장 화면 담당이 이 아래에 붙인다.
///
/// 서버를 타지 않는다. 카탈로그도 장착 상태도 [CosmeticProvider] 가 더미로
/// 들고 있다.
class CosmeticClosetScreen extends StatelessWidget {
  const CosmeticClosetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final cosmetic = context.watch<CosmeticProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const StandardText(
          text: '개구리 꾸미기',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 태블릿에서 개구리가 화면을 다 먹지 않게 위쪽에서 잘라 둔다.
            final frogSize = (constraints.maxWidth * 0.62).clamp(160.0, 320.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: FrogCharacter(
                      layers: cosmetic.layers,
                      size: frogSize,
                      borderRadius: AppRadius.xlarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildLevelSlider(cosmetic, themeProvider),
                  const SizedBox(height: AppSpacing.xl),
                  _buildPlaceholder(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 레벨을 직접 옮겨 보는 슬라이더.
  ///
  /// 시안의 핵심이다. Lv.1 부터 Lv.15 까지 훑으면서 해금이 어떻게 쌓이는지
  /// 개구리에 바로 보이게 한다. 실제 출시 화면에는 들어가지 않는다.
  Widget _buildLevelSlider(
    CosmeticProvider cosmetic,
    ThemeHandler themeProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: StandardText(
                  text: '레벨 미리보기',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StandardText(
                text: 'Lv.${cosmetic.level}',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: themeProvider.primaryColor,
              ),
            ],
          ),
          Slider(
            value: cosmetic.level.toDouble(),
            min: 1,
            max: cosmetic.maxLevel.toDouble(),
            divisions: cosmetic.maxLevel - 1,
            label: 'Lv.${cosmetic.level}',
            activeColor: themeProvider.primaryColor,
            onChanged: (value) => cosmetic.setMockLevel(value.round()),
          ),
          const StandardText(
            text: '레벨을 옮기면 그 레벨에서 열리는 것들을 입은 모습이 보여요.',
            fontSize: 12,
            color: AppColors.textTertiary,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// 옷장 담당이 채울 자리. 지금은 비어 있다는 것만 알린다.
  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: const StandardText(
        text: '아이템 목록은 여기에 들어갑니다.',
        fontSize: 13,
        color: AppColors.textTertiary,
        textAlign: TextAlign.center,
        maxLines: 2,
      ),
    );
  }
}
