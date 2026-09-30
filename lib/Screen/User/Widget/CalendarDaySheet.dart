import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../Model/StudyCalendar/StudyCalendarModel.dart';
import '../../../Module/Emoji/OnoEmojiImage.dart';
import '../../../Module/Motion/PressableScale.dart';
import 'DiaryTheme.dart';

/// 학습 달력 일기장의 둘째 장. 고른 날의 기분, 공부 기록 한 문장, 복습한
/// 문제, 그리고 그날의 일기가 한 장에 이어진다.
///
/// 전에는 학습 기록 박스와 일기장이 따로 된 카드였는데, 같은 날 이야기라
/// 한 장 안에서 점선으로만 나눈다. 일기 쓰기 흐름은 [diary] 로 받은
/// `DiaryPage(embedded: true)` 가 그대로 맡는다.
class CalendarDaySheet extends StatelessWidget {
  final DiaryInk ink;
  final DateTime date;
  final bool isToday;

  /// `수요일` 처럼 적힌 요일.
  final String weekdayName;

  /// 달력을 불러왔는지. 못 불러왔으면 기록 요약과 복습 목록을 숨기고 일기만
  /// 남긴다. 일기는 기기에 있어서 서버가 안 돼도 쓸 수 있어야 한다.
  final bool showRecord;

  /// 고른 날의 기록. 기록이 없는 날이면 null 이다.
  final DailyStudyRecord? record;

  /// 기분을 남기거나 바꾼다. 기분은 공부한 날에만 남길 수 있어서, 그 밖의
  /// 날에는 null 이고 기분 자리를 비운다.
  final VoidCallback? onMoodTap;

  final Widget diary;

  const CalendarDaySheet({
    super.key,
    required this.ink,
    required this.date,
    required this.isToday,
    required this.weekdayName,
    required this.showRecord,
    required this.record,
    required this.onMoodTap,
    required this.diary,
  });

  static const Key moodButtonKey = Key('calendar_mood_button');
  static const Key summaryKey = Key('calendar_day_summary');
  static const Key reviewedListKey = Key('calendar_reviewed_list');

  @override
  Widget build(BuildContext context) {
    final record = this.record;
    final studied = record != null && record.hasStudied;

    return DiarySheet(
      edgeColor: ink.edge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HandText(
                      '${date.month}월 ${date.day}일',
                      size: 30,
                      color: ink.ink,
                      height: 1.1,
                    ),
                    const SizedBox(height: 8),
                    HandText('$weekdayName의 기록', size: 16, color: ink.soft),
                  ],
                ),
              ),
              if (showRecord && studied && onMoodTap != null)
                _MoodButton(
                  ink: ink,
                  moodEmojiKey: record.moodEmojiKey,
                  onTap: onMoodTap!,
                ),
            ],
          ),
          // 칸 사이를 24 안팎으로 띄운다. 손글씨는 붙어 있으면 한 덩어리로
          // 읽혀서 어디까지가 요약이고 어디부터가 목록인지 흐려졌다.
          if (showRecord) ...[
            const SizedBox(height: 24),
            Text.rich(
              key: summaryKey,
              TextSpan(children: _summarySpans(record)),
              style: HandText.style(size: 18, color: ink.ink, height: 1.6),
            ),
            if (studied && record.reviewedItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              HandText('복습한 문제', size: 16, color: ink.soft),
              const SizedBox(height: 6),
              Column(
                key: reviewedListKey,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in record.reviewedItems)
                    _ReviewedRow(title: item, ink: ink),
                ],
              ),
            ],
          ],
          const SizedBox(height: 24),
          const DashedLine(),
          const SizedBox(height: 16),
          diary,
        ],
      ),
    );
  }

  /// `오늘은 복습 2번, 12분 공부했어요` 처럼 기록을 한 문장으로 적는다.
  ///
  /// 칩 세 개로 늘어놓으면 표처럼 읽혀서 일기장과 어울리지 않았다. 숫자가
  /// 0 인 것은 빼고, 숫자 부분에만 형광펜을 긋는다.
  List<InlineSpan> _summarySpans(DailyStudyRecord? record) {
    if (record == null || !record.hasStudied) {
      return const [TextSpan(text: '이 날은 공부 기록이 없어요')];
    }

    final parts = <String>[
      if (record.reviewCount > 0) '복습 ${record.reviewCount}번',
      if (record.noteWriteCount > 0) '오답노트 ${record.noteWriteCount}개',
      if (record.studyMinutes > 0) '${record.studyMinutes}분',
    ];

    final spans = <InlineSpan>[TextSpan(text: isToday ? '오늘은 ' : '이 날은 ')];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: ', '));
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Highlighted(
            color: ink.highlight,
            child: HandText(parts[i], size: 18, color: ink.ink, height: 1.3),
          ),
        ),
      );
    }
    spans.add(TextSpan(text: parts.isEmpty ? '공부했어요' : ' 공부했어요'));
    return spans;
  }
}

/// 머리 오른쪽의 기분 스티커. 없으면 점선 원 안에 `+` 를 그려 남길 자리를
/// 보여 준다.
class _MoodButton extends StatelessWidget {
  final DiaryInk ink;
  final String? moodEmojiKey;
  final VoidCallback onTap;

  const _MoodButton({
    required this.ink,
    required this.moodEmojiKey,
    required this.onTap,
  });

  static const double _size = 46;

  @override
  Widget build(BuildContext context) {
    final hasMood = moodEmojiKey != null;
    return Semantics(
      label: hasMood ? '기분 바꾸기' : '기분 남기기',
      button: true,
      excludeSemantics: true,
      child: PressableScale(
        key: CalendarDaySheet.moodButtonKey,
        onTap: onTap,
        semanticButton: false,
        child: Transform.rotate(
          angle: 6 * math.pi / 180,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasMood)
                  OnoEmojiImage(emojiKey: moodEmojiKey, size: _size)
                else
                  SizedBox(
                    width: _size,
                    height: _size,
                    child: CustomPaint(
                      painter: DashedCirclePainter(
                        // 종이 점선 색은 너무 옅어 누를 자리로 안 보여서 보조 잉크로 긋는다.
                        color: ink.soft.withValues(alpha: 0.7),
                        strokeWidth: 1.5,
                        dashes: 18,
                      ),
                      child: Center(
                        child: InkIcon(
                          InkGlyph.plus,
                          size: 20,
                          color: ink.soft,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 2),
                HandText(
                  hasMood ? '기분 바꾸기' : '기분 남기기',
                  size: 14,
                  color: ink.soft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 복습한 문제 한 줄. 체크한 체크박스와 제목, 줄마다 공책 밑줄.
class _ReviewedRow extends StatelessWidget {
  final String title;
  final DiaryInk ink;

  const _ReviewedRow({required this.title, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DiaryPaper.rule)),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: ink.soft, width: 1.5),
            ),
            alignment: Alignment.center,
            child: InkIcon(
              InkGlyph.check,
              size: 11,
              color: ink.ink,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: HandText(
              title,
              size: 17,
              color: ink.ink,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
