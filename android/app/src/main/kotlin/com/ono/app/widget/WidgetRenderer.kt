package com.ono.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Bitmap
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import com.ono.app.MainActivity
import com.ono.app.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.time.LocalDate
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/** 위젯 크기. 시안 크기(dp)는 위젯 옵션을 못 읽었을 때 쓰는 기본값이다. */
internal enum class WidgetSize(val key: String, val layout: Int, val designWidth: Float, val designHeight: Float) {
    SMALL("small", R.layout.widget_small, 170f, 170f),
    MEDIUM("medium", R.layout.widget_medium, 364f, 170f),
    LARGE("large", R.layout.widget_large, 364f, 382f),
}

/**
 * 스냅샷 하나로 위젯 한 개의 RemoteViews 를 만든다.
 *
 * 글자와 달력은 전부 [WidgetPainter] 비트맵이고, 레이아웃 XML 은 자리(여백, 누르는 영역)만 잡는다.
 * 손글씨는 연속 일수 큰 줄과 달력 월 제목에만 쓰고 나머지 글자는 시스템 글꼴이다.
 * 시스템 글꼴은 손글씨보다 2~4dp 작게 쓰되, 줄 상자 높이(크기 x lineHeight)는 손글씨 때 값을 그대로 둬서
 * 레이아웃이 흔들리지 않게 한다.
 * 비트맵 크기는 위젯 옵션의 실제 dp 크기로 정한다. 런처마다 칸 크기가 달라서 시안 크기로 그리면
 * 늘어나거나 잘린다.
 */
internal object WidgetRenderer {

    private const val TAG = "OnOWidget"

    fun update(context: Context, manager: AppWidgetManager, widgetId: Int, size: WidgetSize, prefs: SharedPreferences) {
        val model = WidgetModel(
            WidgetSnapshot.parse(prefs.getString(WidgetSnapshot.KEY_SNAPSHOT, null)),
            LocalDate.now(),
        )
        val (w, h) = widgetSizeDp(context, manager, widgetId, size)
        val density = context.resources.displayMetrics.density
        var scale = min(density, memoryScale(context, w, h))
        // 한도 계산은 추정이라, 그래도 넘치면 해상도를 반으로 내려 한 번 더 시도한다.
        // 여기서 예외가 새면 브로드캐스트 수신 중 앱 프로세스가 죽는다.
        for (attempt in 0 until 2) {
            try {
                val views = build(context, model, size, w, h, scale, prefs)
                manager.updateAppWidget(widgetId, views)
                return
            } catch (e: IllegalArgumentException) {
                Log.w(TAG, "위젯 비트맵이 한도를 넘어 해상도를 낮춘다 ($size, scale=$scale)", e)
                scale /= 2f
            } catch (e: Exception) {
                Log.w(TAG, "위젯을 그리지 못해 기본 화면으로 둔다 ($size)", e)
                break
            } catch (e: OutOfMemoryError) {
                Log.w(TAG, "위젯을 그리다 메모리가 모자라 기본 화면으로 둔다 ($size)", e)
                break
            }
        }
        try {
            manager.updateAppWidget(widgetId, RemoteViews(context.packageName, size.layout))
        } catch (e: Exception) {
            Log.w(TAG, "기본 위젯 화면도 올리지 못했다 ($size)", e)
        }
    }

    /**
     * 위젯의 지금 dp 크기. 세로 화면에서는 (최소 폭, 최대 높이), 가로 화면에서는 (최대 폭, 최소 높이)가
     * 실제 칸 크기에 가깝다 (AppWidgetManager.OPTION_APPWIDGET_* 문서의 관례).
     * 옵션이 비어 있는 런처도 있어서 그때는 시안 크기를 쓴다.
     */
    private fun widgetSizeDp(context: Context, manager: AppWidgetManager, id: Int, size: WidgetSize): Pair<Float, Float> {
        val o = try {
            manager.getAppWidgetOptions(id)
        } catch (e: Exception) {
            null
        }
        val minW = o?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0
        val maxW = o?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH) ?: 0
        val minH = o?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 0
        val maxH = o?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT) ?: 0
        val landscape = context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        var w = (if (landscape) maxW else minW).toFloat()
        var h = (if (landscape) minH else maxH).toFloat()
        if (w <= 0f) w = size.designWidth
        if (h <= 0f) h = size.designHeight
        // 비정상 값(0 에 가깝거나 태블릿에서 과하게 큰 값)에 비트맵이 끌려가지 않게 묶는다.
        return w.coerceIn(100f, 900f) to h.coerceIn(100f, 900f)
    }

    /**
     * RemoteViews 비트맵 메모리 한도는 화면 픽셀 수 x 4바이트 x 1.5 (AppWidgetManagerService 의
     * mMaxWidgetBitmapMemory). 위젯 안 비트맵을 다 더해도 위젯 면적을 크게 넘지 않으므로,
     * 위젯 면적 x 여유 1.2배가 한도의 절반 안에 들어가는 배율까지만 쓴다.
     */
    private fun memoryScale(context: Context, wDp: Float, hDp: Float): Float {
        val dm = context.resources.displayMetrics
        val limitBytes = 6.0 * dm.widthPixels * dm.heightPixels
        val budget = limitBytes / 2.0
        val perScale2 = 4.0 * wDp * hDp * 1.2
        return sqrt(budget / perScale2).toFloat().coerceAtLeast(1f)
    }

    private fun build(
        context: Context,
        model: WidgetModel,
        size: WidgetSize,
        w: Float,
        h: Float,
        scale: Float,
        prefs: SharedPreferences,
    ): RemoteViews {
        val ink = WidgetInk(model.themeColor)
        val p = WidgetPainter(context, scale, ink)
        val rv = RemoteViews(context.packageName, size.layout)
        val signed = model.signedIn

        val profileDp = if (size == WidgetSize.SMALL) 46f else 50f
        val photo = if (signed != null) {
            WidgetPainter.decodeProfile(prefs.getString(WidgetSnapshot.KEY_PROFILE, null), (profileDp * scale).toInt())
        } else {
            null
        }

        when (size) {
            WidgetSize.SMALL -> buildSmall(context, rv, p, ink, model, w, profileDp, photo)
            WidgetSize.MEDIUM -> buildMedium(context, rv, p, ink, model, w, h, profileDp, photo)
            WidgetSize.LARGE -> buildLarge(context, rv, p, ink, model, w, h, profileDp, photo)
        }
        return rv
    }

    // ---- 소형 ------------------------------------------------------------------------------

    private fun buildSmall(
        context: Context, rv: RemoteViews, p: WidgetPainter, ink: WidgetInk, model: WidgetModel,
        w: Float, profileDp: Float, photo: Bitmap?,
    ) {
        val inner = w - 32f
        rv.setImageViewBitmap(R.id.widget_tape, p.tape(60f, -4f))
        val s = model.signedIn
        if (s != null) {
            rv.setViewVisibility(R.id.widget_content, View.VISIBLE)
            rv.setViewVisibility(R.id.widget_signed_out, View.GONE)
            rv.setImageViewBitmap(R.id.widget_profile, p.profile(photo, profileDp))
            val streak = "${model.streak}일째"
            rv.setImageViewBitmap(
                R.id.widget_header_text,
                p.textBlock(
                    listOf(
                        TextLine(streak, 30f, ink.ink, 1.0f, face = WidgetFace.HAND),
                        // 줄 상자 16.8dp (손글씨 14 x 1.2 때와 같다)
                        TextLine("연속으로 공부 중", 12f, ink.soft, 1.4f, 2f),
                    ),
                    inner - profileDp - 10f, center = false,
                ),
            )
            rv.setContentDescription(R.id.widget_header_text, "$streak 연속으로 공부 중")
            rv.setImageViewBitmap(R.id.widget_week, p.week(model, inner))
            rv.setContentDescription(R.id.widget_week, "이번 주 공부한 날")
            val due = dueText(model, s)
            // 소형은 복습 수 하나만 적는다. 밀린 문제 수까지 붙이면 칸이 좁아 복잡해 보인다.
            rv.setImageViewBitmap(
                R.id.widget_review,
                p.reviewLine(due, 14f, 1.1f * 17f, null, 11f, WidgetInk.OVERDUE, sideAtEnd = false, widthDp = inner),
            )
            rv.setContentDescription(R.id.widget_review, due)
        } else {
            rv.setViewVisibility(R.id.widget_content, View.GONE)
            rv.setViewVisibility(R.id.widget_signed_out, View.VISIBLE)
            rv.setImageViewBitmap(R.id.widget_signed_out_frog, p.profile(null, 56f))
            rv.setImageViewBitmap(
                R.id.widget_signed_out_text,
                p.textBlock(listOf(TextLine(emptyMessageSmall(model), 13f, ink.ink, 1.45f)), inner, center = true, wrapLines = true),
            )
            rv.setContentDescription(R.id.widget_signed_out_text, emptyMessage(model))
        }
        rv.setOnClickPendingIntent(R.id.widget_root, launch(context, "onowidget://review-due?homeWidget&size=small"))
    }

    // ---- 중형 ------------------------------------------------------------------------------

    private fun buildMedium(
        context: Context, rv: RemoteViews, p: WidgetPainter, ink: WidgetInk, model: WidgetModel,
        w: Float, h: Float, profileDp: Float, photo: Bitmap?,
    ) {
        val left = 118f
        rv.setImageViewBitmap(R.id.widget_tape, p.tape(68f, -3f))
        rv.setImageViewBitmap(R.id.widget_profile, p.profile(photo, profileDp))
        val s = model.signedIn
        if (s != null) {
            val streak = "${model.streak}일째"
            rv.setImageViewBitmap(
                R.id.widget_header_text,
                p.textBlock(
                    listOf(
                        TextLine(streak, 32f, ink.ink, 1.0f, face = WidgetFace.HAND),
                        TextLine("연속으로 공부 중", 12f, ink.soft, 1.4f, 2f),
                    ),
                    left, center = false,
                ),
            )
            rv.setContentDescription(R.id.widget_header_text, "$streak 연속으로 공부 중")
            val due = dueText(model, s)
            rv.setViewVisibility(R.id.widget_review, View.VISIBLE)
            rv.setImageViewBitmap(
                R.id.widget_review,
                p.reviewLine(due, 14f, 1.1f * 16f, null, 0f, 0, sideAtEnd = false, widthDp = left),
            )
            rv.setContentDescription(R.id.widget_review, due)
        } else {
            rv.setImageViewBitmap(
                R.id.widget_header_text,
                p.textBlock(listOf(TextLine(emptyMessage(model), 13f, ink.ink, 1.45f)), left, center = false, wrapLines = true),
            )
            rv.setContentDescription(R.id.widget_header_text, emptyMessage(model))
            rv.setViewVisibility(R.id.widget_review, View.GONE)
        }
        val calW = max(120f, w - 40f - left - 16f)
        val calH = max(80f, h - 32f)
        rv.setImageViewBitmap(R.id.widget_calendar, p.calendar(model, 4, calW, calH, large = false))
        rv.setContentDescription(R.id.widget_calendar, "${model.monthTitle} 학습 달력")
        rv.setOnClickPendingIntent(R.id.widget_root, launch(context, "onowidget://calendar?homeWidget&size=medium"))
    }

    // ---- 대형 ------------------------------------------------------------------------------

    private fun buildLarge(
        context: Context, rv: RemoteViews, p: WidgetPainter, ink: WidgetInk, model: WidgetModel,
        w: Float, h: Float, profileDp: Float, photo: Bitmap?,
    ) {
        val inner = w - 40f
        rv.setImageViewBitmap(R.id.widget_tape, p.tape(72f, -3f))
        rv.setImageViewBitmap(R.id.widget_profile, p.profile(photo, profileDp))
        val headerW = inner - profileDp - 12f
        val s = model.signedIn

        // 달력 높이 = 위젯 높이 - 여백 32 - 머리 50 - 8 [- 점선(10 + 1.5) - 복습 머리줄 7 + 줄 + 4 - 추천 81]
        val reviewLineH = 1.1f * 18f
        var calH = h - 32f - 50f - 8f
        if (s != null) calH -= 11.5f + 7f + reviewLineH + 4f + 81f
        rv.setImageViewBitmap(R.id.widget_calendar, p.calendar(model, 5, inner, max(60f, calH), large = true))
        rv.setContentDescription(R.id.widget_calendar, "${model.monthTitle} 학습 달력")
        rv.setOnClickPendingIntent(R.id.widget_root, launch(context, "onowidget://calendar?homeWidget&size=large"))

        if (s == null) {
            rv.setImageViewBitmap(
                R.id.widget_header_text,
                p.textBlock(listOf(TextLine(emptyMessage(model), 13f, ink.ink, 1.4f)), headerW, center = false, wrapLines = true),
            )
            rv.setContentDescription(R.id.widget_header_text, emptyMessage(model))
            // 복습 칸이 없으면 점선만 맨 아래 홀로 남아 어색해서 같이 숨긴다.
            rv.setViewVisibility(R.id.widget_divider, View.GONE)
            rv.setViewVisibility(R.id.widget_review_section, View.GONE)
            return
        }

        val headline = "${model.streak}일째 공부 중"
        val sub = "이번 달엔 ${model.thisMonthStudyDays}일 공부했어요"
        rv.setImageViewBitmap(
            R.id.widget_header_text,
            p.textBlock(
                listOf(
                    TextLine(headline, 28f, ink.ink, 1.0f, face = WidgetFace.HAND),
                    TextLine(sub, 12f, ink.soft, 1.4f, 3f),
                ),
                headerW, center = false,
            ),
        )
        rv.setContentDescription(R.id.widget_header_text, "$headline, $sub")

        rv.setViewVisibility(R.id.widget_divider, View.VISIBLE)
        rv.setViewVisibility(R.id.widget_review_section, View.VISIBLE)
        val title = when {
            s.dueCount == 0 -> if (model.stale) "복습 끝! (어제)" else "오늘 복습 끝!"
            model.stale -> "복습할 문제 ${s.dueCount}개 (어제)"
            else -> "오늘 복습할 문제 ${s.dueCount}개"
        }
        val side = if (s.dueCount > 0 && s.overdueCount > 0) "밀린 문제 ${s.overdueCount}개" else null
        rv.setImageViewBitmap(
            R.id.widget_review,
            p.reviewLine(title, 14f, reviewLineH, side, 11f, ink.soft, sideAtEnd = true, widthDp = inner),
        )
        rv.setContentDescription(R.id.widget_review, listOfNotNull(title, side).joinToString(", "))
        rv.setOnClickPendingIntent(R.id.widget_review_section, launch(context, "onowidget://review-due?homeWidget&size=large"))

        val rowIds = intArrayOf(R.id.widget_rec_0, R.id.widget_rec_1, R.id.widget_rec_2)
        if (s.dueCount == 0) {
            rv.setViewVisibility(R.id.widget_rec_list, View.GONE)
            rv.setViewVisibility(R.id.widget_all_done, View.VISIBLE)
            rv.setImageViewBitmap(
                R.id.widget_all_done,
                p.textBlock(listOf(TextLine(ALL_DONE_LARGE, 13f, ink.ink, 1.2f * 17f / 13f)), inner, center = true),
            )
            rv.setContentDescription(R.id.widget_all_done, ALL_DONE_LARGE)
            return
        }
        rv.setViewVisibility(R.id.widget_rec_list, View.VISIBLE)
        rv.setViewVisibility(R.id.widget_all_done, View.GONE)
        rowIds.forEachIndexed { i, id ->
            val rec = s.recommendations.getOrNull(i)
            if (rec == null) {
                rv.setViewVisibility(id, View.GONE)
                return@forEachIndexed
            }
            val overdue = rec.overdueDays > 0
            val badge = if (overdue) "${rec.overdueDays}일 밀림" else "오늘"
            rv.setViewVisibility(id, View.VISIBLE)
            rv.setImageViewBitmap(
                id,
                p.recommendationRow(rec.title, badge, if (overdue) WidgetInk.OVERDUE else ink.soft, inner),
            )
            rv.setContentDescription(id, "${rec.title}, $badge")
            rv.setOnClickPendingIntent(id, launch(context, "onowidget://problem/${rec.problemId}?homeWidget&size=large"))
        }
    }

    // ---- 공통 ------------------------------------------------------------------------------

    private const val SIGNED_OUT = "OnO 에 로그인하면 여기에 기록이 적혀요"
    private const val SIGNED_OUT_SMALL = "OnO 에 로그인하면\n여기에 기록이 적혀요"
    private const val NO_SNAPSHOT = "OnO 를 열면 여기에 기록이 적혀요"
    private const val NO_SNAPSHOT_SMALL = "OnO 를 열면\n여기에 기록이 적혀요"
    private const val ALL_DONE_LARGE = "내일 복습할 문제는 내일 알려 줄게요"

    /** 기록 대신 적는 안내 문구. 로그아웃이면 로그인하라고, 스냅샷이 없거나 깨졌으면 앱을 열라고 적는다. */
    private fun emptyMessage(model: WidgetModel): String =
        if (model.snapshot is WidgetSnapshot.SignedOut) SIGNED_OUT else NO_SNAPSHOT

    /** 소형은 폭이 좁아 두 줄로 끊는다. */
    private fun emptyMessageSmall(model: WidgetModel): String =
        if (model.snapshot is WidgetSnapshot.SignedOut) SIGNED_OUT_SMALL else NO_SNAPSHOT_SMALL

    /** 소형과 중형 복습 문구. stale 이면 `(어제)` 를 붙인다 (계약서 「오늘과 날짜가 바뀐 경우」). */
    private fun dueText(model: WidgetModel, s: WidgetSnapshot.SignedIn): String = when {
        s.dueCount == 0 -> if (model.stale) "복습 끝! (어제)" else "오늘 복습 끝!"
        model.stale -> "복습 ${s.dueCount}문제 (어제)"
        else -> "오늘 복습 ${s.dueCount}문제"
    }

    /**
     * home_widget 의 HomeWidgetLaunchIntent 로 MainActivity 를 연다. 액션이
     * es.antonborri.home_widget.action.LAUNCH 여야 Dart 의 initiallyLaunchedFromHomeWidget 과
     * widgetClicked 가 URL 을 받는다. requestCode 가 늘 0 이지만 URL(data)이 다르면 서로 다른
     * PendingIntent 로 취급되므로(Intent.filterEquals) 영역마다 따로 걸린다.
     */
    private fun launch(context: Context, url: String): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(url))
}
