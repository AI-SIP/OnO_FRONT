import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../Model/LearningReport/LearningReportResponseModel.dart';
import '../../Model/User/UserInfoModel.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Util/AppErrorReporter.dart';
import '../../Util/AppSnackBar.dart';

class AchievementCardScreen extends StatefulWidget {
  final UserInfoModel userInfo;
  final LearningPeriodReport weeklyReport;

  const AchievementCardScreen({
    super.key,
    required this.userInfo,
    required this.weeklyReport,
  });

  @override
  State<AchievementCardScreen> createState() => _AchievementCardScreenState();
}

class _AchievementCardScreenState extends State<AchievementCardScreen> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareCardAsImage() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      FirebaseAnalytics.instance.logEvent(name: 'achievement_card_share_tap');

      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted) return;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final screenSize = MediaQuery.of(context).size;
      final boundary = _globalKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final rect =
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      canvas.drawRect(rect, Paint()..color = Colors.white);
      canvas.drawImage(image, Offset.zero, Paint());
      final picture = recorder.endRecording();
      final composited = await picture.toImage(image.width, image.height);

      final byteData =
          await composited.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/achievement_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = await File(filePath).create();
      await file.writeAsBytes(pngBytes);

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'OnO에서 이번 주 학습 결과야! 📚\n\nOnO 다운로드: https://ono-app.com/home',
        sharePositionOrigin: Rect.fromPoints(
          Offset.zero,
          Offset(screenSize.width * 2 / 3, screenSize.height),
        ),
      );

      if (result.status == ShareResultStatus.success && mounted) {
        final themeProvider = Provider.of<ThemeHandler>(
          context,
          listen: false,
        );
        _showShareCompletedSnackBar(themeProvider);
      }
    } catch (e, stackTrace) {
      await AppErrorReporter.report(
        e,
        stackTrace,
        source: 'achievement_card_share',
        severity: AppErrorSeverity.error,
      );
      if (mounted) {
        AppSnackBar.showError('이미지를 공유하지 못했습니다. 잠시 후 다시 시도해주세요.');
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _showShareCompletedSnackBar(ThemeHandler themeProvider) {
    final messenger = AppSnackBar.messengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const StandardText(
          text: '학습 성취 카드 공유가 완료되었습니다.',
          fontSize: 14,
          color: Colors.white,
        ),
        backgroundColor: themeProvider.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.grey.shade100,
        title: StandardText(
          text: '학습 성취 카드',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              // 그림자는 RepaintBoundary 밖에 둬서 미리보기에만 보임
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: RepaintBoundary(
                  key: _globalKey,
                  child: _AchievementCard(
                    userInfo: widget.userInfo,
                    weeklyReport: widget.weeklyReport,
                  ),
                ),
              ),
            ),
          ),
          _buildShareButton(themeProvider),
        ],
      ),
    );
  }

  Widget _buildShareButton(ThemeHandler themeProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: ElevatedButton.icon(
        onPressed: _isSharing ? null : _shareCardAsImage,
        icon: _isSharing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.share_rounded, size: 18, color: Colors.white),
        label: StandardText(
          text: _isSharing ? '공유 중...' : '공유하기',
          fontSize: 14,
          color: Colors.white,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeProvider.primaryColor,
          minimumSize: const Size(double.infinity, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final UserInfoModel userInfo;
  final LearningPeriodReport weeklyReport;

  const _AchievementCard({
    required this.userInfo,
    required this.weeklyReport,
  });

  // "2025-05-12" → "5/12", "2025.05.12" → "5/12" 등 연도 제거
  static String _formatTrendLabel(String label) {
    final dt = DateTime.tryParse(label);
    if (dt != null) return '${dt.month}/${dt.day}';
    final parts = label.split(RegExp(r'[-./]'));
    if (parts.length >= 3) {
      final m = int.tryParse(parts[parts.length - 2]);
      final d = int.tryParse(parts[parts.length - 1]);
      if (m != null && d != null) return '$m/$d';
    }
    return label.length > 5 ? label.substring(5) : label;
  }

  static String _formatStudyTime(double minutes) {
    if (minutes < 1) return '0분';
    if (minutes < 60) return '${minutes.round()}분';
    final h = (minutes / 60).floor();
    final m = (minutes % 60).round();
    return m == 0 ? '$h시간' : '$h시간 $m분';
  }

  // 높이 합계: 160 + 200 + 148 + 92 = 600px
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return SizedBox(
      width: 360,
      height: 600,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
          Container(color: Colors.white),
          Column(
            children: [
              _buildTopSection(themeProvider), // 160px
              _buildStatsGrid(themeProvider), // 200px
              _buildTrendChart(themeProvider), // 148px
              _buildStreakCompact(themeProvider), //  92px
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: themeProvider.primaryColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // ── 상단 160px: 레벨 + 유저명 ────────────────────────────────────────
  Widget _buildTopSection(ThemeHandler themeProvider) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeProvider.primaryColor.withValues(alpha: 0.96),
            themeProvider.primaryColor.withValues(alpha: 0.88),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.24),
                    Colors.white.withValues(alpha: 0.03),
                    Colors.black.withValues(alpha: 0.04),
                  ],
                  stops: const [0.0, 0.46, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단: Lv 배지만 우측 정렬
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Lv.${userInfo.totalStudyLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'PretendardBold',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              // 메인 텍스트 — 좌측 정렬, weight contrast 타이포
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이번 주 공부 기록',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontFamily: 'PretendardLight',
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 7),
                      // 이름 + "의 한 주" 한 줄, weight contrast
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: userInfo.name ?? '사용자',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontFamily: 'PretendardBold',
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            TextSpan(
                              text: '의 한 주',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 18,
                                fontFamily: 'PretendardLight',
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ],
      ),
    );
  }

  // ── 스탯 2×2 그리드 200px ────────────────────────────────────────────
  // padding v:10 → 각 행 85px
  Widget _buildStatsGrid(ThemeHandler themeProvider) {
    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(themeProvider,
                        emoji: '📚',
                        value: weeklyReport.reviewCount.toString(),
                        unit: '회',
                        label: '복습 횟수'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(themeProvider,
                        emoji: '🎯',
                        value: weeklyReport.averageAccuracy.toStringAsFixed(0),
                        unit: '%',
                        label: '평균 정답률'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(themeProvider,
                        emoji: '⏱',
                        value: _formatStudyTime(
                            weeklyReport.averageStudyTimeMinutes),
                        unit: '',
                        label: '평균 학습 시간'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(themeProvider,
                        emoji: '📝',
                        value: weeklyReport.noteWriteCount.toString(),
                        unit: '개',
                        label: '오답노트'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 숫자 행 + 이모지·라벨 행 (2줄)
  Widget _buildStatCard(
    ThemeHandler themeProvider, {
    required String emoji,
    required String value,
    required String unit,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 숫자 + 단위
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: themeProvider.darkPrimaryColor,
                    fontSize: 22,
                    fontFamily: 'PretendardBold',
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: themeProvider.primaryColor,
                      fontSize: 12,
                      fontFamily: 'PretendardBold',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          // 이모지 + 라벨
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 11, height: 1.0)),
              const SizedBox(width: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 10,
                  fontFamily: 'PretendardBold',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 복습 추이 bar chart 148px ─────────────────────────────────────────
  // padding top:12 bottom:8 h:16 → label(14) + gap(8) + chart(106px)
  Widget _buildTrendChart(ThemeHandler themeProvider) {
    final trend = weeklyReport.trend;
    return SizedBox(
      height: 148,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('📈', style: TextStyle(fontSize: 12)),
                SizedBox(width: 4),
                Text(
                  '복습 추이',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    fontFamily: 'PretendardBold',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: trend.isEmpty
                  ? const Center(
                      child: Text(
                        '이번 주 데이터가 없어요',
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: 11,
                          fontFamily: 'PretendardLight',
                        ),
                      ),
                    )
                  : _buildBars(themeProvider, trend),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBars(ThemeHandler themeProvider, List<LearningTrendItem> trend) {
    final maxCount =
        trend.map((e) => e.reviewCount).fold(0, (a, b) => a > b ? a : b);
    const maxBarH = 78.0;
    const minBarH = 4.0; // 0회일 때도 흐린 바 표시

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: trend.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final hasValue = item.reviewCount > 0;
        final ratio =
            (maxCount > 0 && hasValue) ? item.reviewCount / maxCount : 0.0;
        // 데이터 있으면 비율에 따른 높이(최소 minBarH), 없으면 minBarH만
        final barH =
            hasValue ? (maxBarH * ratio).clamp(minBarH, maxBarH) : minBarH;
        final labelText = _formatTrendLabel(item.label);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < trend.length - 1 ? 4 : 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: barH,
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor
                        .withValues(alpha: hasValue ? 0.8 : 0.12),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labelText,
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 9,
                    fontFamily: 'PretendardLight',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 연속 학습 컴팩트 92px ─────────────────────────────────────────────
  Widget _buildStreakCompact(ThemeHandler themeProvider) {
    final days = weeklyReport.consecutiveLearningDays;
    final progress = (days / 30).clamp(0.0, 1.0);

    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            '연속 $days일',
            style: TextStyle(
              color: themeProvider.darkPrimaryColor,
              fontSize: 11,
              fontFamily: 'PretendardBold',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor:
                    themeProvider.primaryColor.withValues(alpha: 0.15),
                color: themeProvider.primaryColor,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$days / 30일',
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 9,
              fontFamily: 'PretendardLight',
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
