package com.ono.app.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.text.TextPaint
import android.text.TextUtils
import android.util.DisplayMetrics
import com.ono.app.R
import java.io.File
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** 비트맵에 적을 한 줄. 크기는 dp, lineHeight 는 글자 크기 배수(CSS line-height 와 같은 뜻). */
internal data class TextLine(
    val text: String,
    val sizeDp: Float,
    val color: Int,
    val lineHeight: Float = 1.2f,
    val gapBeforeDp: Float = 0f,
)

/**
 * 위젯에 들어가는 비트맵을 Kotlin Canvas 로 그린다.
 *
 * 크기는 전부 dp 로 받고 [scale] (dp 당 픽셀)을 곱해 그린다. scale 은 보통 화면 density 지만,
 * RemoteViews 비트맵 메모리 한도를 넘지 않게 [WidgetRenderer] 가 낮출 수 있다.
 * 비트맵 density 를 160 x scale 로 적어 두어서, ImageView 가 wrap_content 이면 dp 크기 그대로 잡힌다.
 *
 * 글자 크기를 sp 가 아닌 dp 로 쓰는 것은 위젯 칸이 고정이라 시스템 글자 크기를 키우면 넘치기 때문이다.
 */
internal class WidgetPainter(context: Context, private val scale: Float, private val ink: WidgetInk) {

    private val appContext = context.applicationContext
    private val font = WidgetFont.get(context)

    private fun dp(v: Float): Float = v * scale

    private fun newCanvas(widthDp: Float, heightDp: Float): Pair<Bitmap, Canvas> {
        val w = max(1, dp(widthDp).roundToInt())
        val h = max(1, dp(heightDp).roundToInt())
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        bmp.density = (DisplayMetrics.DENSITY_DEFAULT * scale).roundToInt().coerceAtLeast(1)
        return bmp to Canvas(bmp)
    }

    private fun textPaint(sizeDp: Float, color: Int): TextPaint =
        TextPaint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
            typeface = font
            textSize = dp(sizeDp)
            this.color = color
        }

    /** 글자 크기 lh 배 줄 상자의 세로 가운데에 오는 기준선. 이 폰트는 ascent 0.796, descent 0.230 이라 줄 높이 1 에 거의 꽉 찬다. */
    private fun baselineIn(paint: Paint, top: Float, boxHeight: Float): Float {
        val fm = paint.fontMetrics
        return top + (boxHeight - (fm.descent - fm.ascent)) / 2f - fm.ascent
    }

    private fun lineBox(sizeDp: Float, lineHeight: Float): Float = max(lineHeight, 1.03f) * sizeDp

    /**
     * 폭에 맞춰 줄인다. 연속 일수처럼 한 줄에 둬야 하는 글자는 70% 까지 줄이고(Android 의 autoSizeText 대신),
     * 그래도 넘치면 말줄임한다.
     */
    private fun fitted(paint: TextPaint, text: String, maxWidthPx: Float, minFactor: Float = 0.7f): String {
        val w = paint.measureText(text)
        if (w <= maxWidthPx || w <= 0f) return text
        val base = paint.textSize
        paint.textSize = max(base * minFactor, base * maxWidthPx / w)
        if (paint.measureText(text) <= maxWidthPx) return text
        return TextUtils.ellipsize(text, paint, maxWidthPx, TextUtils.TruncateAt.END).toString()
    }

    /** 공백 기준으로 폭 안에 들어가게 줄을 나눈다. 로그인 안내 문구처럼 여러 줄이 되는 곳에만 쓴다. */
    private fun wrap(paint: TextPaint, text: String, maxWidthPx: Float): List<String> {
        val out = ArrayList<String>()
        for (para in text.split('\n')) {
            var line = ""
            for (word in para.split(' ')) {
                val cand = if (line.isEmpty()) word else "$line $word"
                if (line.isNotEmpty() && paint.measureText(cand) > maxWidthPx) {
                    out.add(line)
                    line = word
                } else {
                    line = cand
                }
            }
            if (line.isNotEmpty()) out.add(line)
        }
        return out
    }

    /**
     * 여러 줄 글자 덩어리. 높이는 줄 상자를 더한 만큼이라, ImageView 를 wrap_content 로 두면 내용 높이가 된다.
     * [wrapLines] 면 폭을 넘는 줄을 공백에서 나눈다.
     */
    fun textBlock(lines: List<TextLine>, widthDp: Float, center: Boolean, wrapLines: Boolean = false): Bitmap {
        val maxW = dp(widthDp)
        data class Row(val text: String, val paint: TextPaint, val top: Float, val box: Float)
        val rows = ArrayList<Row>()
        var y = 0f
        for (line in lines) {
            y += dp(line.gapBeforeDp)
            val box = dp(lineBox(line.sizeDp, line.lineHeight))
            if (wrapLines) {
                val paint = textPaint(line.sizeDp, line.color)
                for (part in wrap(paint, line.text, maxW)) {
                    val p = textPaint(line.sizeDp, line.color)
                    rows.add(Row(fitted(p, part, maxW), p, y, box))
                    y += box
                }
            } else {
                // 연속 일수처럼 한 줄에 둬야 하는 글자라 절반까지 줄여서라도 말줄임(`12…`)을 피한다.
                // 삼성 2x2 처럼 좁은 칸에서 세 자리 연속 일수가 들어가야 한다.
                val p = textPaint(line.sizeDp, line.color)
                rows.add(Row(fitted(p, line.text, maxW, minFactor = 0.5f), p, y, box))
                y += box
            }
        }
        val (bmp, c) = newCanvas(widthDp, y / scale)
        for (r in rows) {
            val x = if (center) (maxW - r.paint.measureText(r.text)) / 2f else 0f
            c.drawText(r.text, x, baselineIn(r.paint, r.top, r.box), r.paint)
        }
        return bmp
    }

    /**
     * 형광펜 복습 문구 한 줄. 글자 상자 아래 45% 에 테마 색 40% 띠를 깔고(좌우 2dp 여유),
     * [side] 가 있으면 [sideAtEnd] 에 따라 오른쪽 끝(대형 `밀린 문제 2개`)에 적는다. 지금은 대형만 쓴다.
     */
    fun reviewLine(
        text: String,
        sizeDp: Float,
        side: String?,
        sideSizeDp: Float,
        sideColor: Int,
        sideAtEnd: Boolean,
        widthDp: Float,
    ): Bitmap {
        val maxW = dp(widthDp)
        val pad = dp(2f)
        val box = dp(lineBox(sizeDp, 1.1f))
        val main = textPaint(sizeDp, ink.ink)
        val sidePaint = if (side.isNullOrEmpty()) null else textPaint(sideSizeDp, sideColor)
        val sideW = sidePaint?.measureText(side) ?: 0f
        val gap = if (sidePaint != null) dp(6f) else 0f
        val mainText = fitted(main, text, maxW - pad * 2 - sideW - gap)
        val mainW = main.measureText(mainText)

        val (bmp, c) = newCanvas(widthDp, box / scale)
        val band = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = ink.highlight }
        c.drawRect(0f, box * 0.55f, mainW + pad * 2, box, band)
        val baseline = baselineIn(main, 0f, box)
        c.drawText(mainText, pad, baseline, main)
        if (sidePaint != null && side != null) {
            val x = if (sideAtEnd) maxW - sideW else pad * 2 + mainW + gap
            c.drawText(side, x, baseline, sidePaint)
        }
        return bmp
    }

    /** 대형 추천 한 줄 (높이 27): 12dp 둥근 네모 체크박스, 제목 15 한 줄 말줄임, 오른쪽 배지 13, 아래 공책 줄. */
    fun recommendationRow(title: String, badge: String, badgeColor: Int, widthDp: Float): Bitmap {
        val h = 27f
        val (bmp, c) = newCanvas(widthDp, h)
        val w = dp(widthDp)
        val cy = dp(h) / 2f

        val box = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = dp(1.5f)
            color = ink.soft
        }
        val half = dp(1.5f) / 2f
        c.drawRoundRect(RectF(half, cy - dp(6f) + half, dp(12f) - half, cy + dp(6f) - half), dp(3f), dp(3f), box)

        val badgePaint = textPaint(13f, badgeColor)
        val badgeW = badgePaint.measureText(badge)
        val titlePaint = textPaint(15f, ink.ink)
        val titleX = dp(12f + 8f)
        val titleMax = w - titleX - badgeW - dp(8f)
        val shown = TextUtils.ellipsize(title, titlePaint, max(0f, titleMax), TextUtils.TruncateAt.END).toString()
        c.drawText(shown, titleX, baselineIn(titlePaint, 0f, dp(h)), titlePaint)
        c.drawText(badge, w - badgeW, baselineIn(badgePaint, 0f, dp(h)), badgePaint)

        val rule = Paint().apply { color = WidgetInk.RULE }
        c.drawRect(0f, dp(h) - dp(1f), w, dp(h), rule)
        return bmp
    }

    /**
     * 학습 달력 (중형 4주, 대형 5주): `9월` 제목 줄, 요일 머리줄, 칸과 날짜 숫자.
     *
     * 칸 지름은 폭과 높이 중 작은 쪽에 맞춘다. 줄이 들어가는 게 먼저고 가로는 7열을 균등하게 벌린다.
     * 칸 안 숫자가 9dp 보다 작아지면 숫자를 빼고 색만 남긴다 (명세서 「UI 반응형 고려사항」).
     */
    fun calendar(model: WidgetModel, weeks: Int, widthDp: Float, heightDp: Float, large: Boolean): Bitmap {
        val (bmp, c) = newCanvas(widthDp, heightDp)
        val w = dp(widthDp)
        val signedIn = model.signedIn != null

        val gapTitle = dp(if (large) 3f else 4f)
        val gapHead = dp(if (large) 4f else 5f)
        val colW = w / 7f
        val designCell = dp(if (large) 22f else 20f)
        val pitchRatio = if (large) 0.88f else 0.8f

        // 칸 지름. 제목과 요일 줄 높이(k 배)를 뺀 나머지를 줄 수로 나눈다.
        fun cellFor(k: Float): Pair<Float, Float> {
            val top = dp(20f) * k + gapTitle + dp(12f) * k + gapHead
            val pitch = max(1f, (dp(heightDp) - top) / weeks)
            return min(pitch * pitchRatio, min(colW * 0.8f, dp(40f))) to pitch
        }
        // 태블릿처럼 칸이 시안보다 커지면 제목과 요일도 같은 비율로 키운다. 그대로 두면 숫자만 커져
        // `9월` 이 작아 보인다. 폰에서 칸이 작아질 때는 조금만 줄인다.
        val k = (cellFor(1f).first / designCell).coerceIn(0.85f, 1.35f)
        val (cell, pitch) = cellFor(k)

        // 제목 줄: `9월`(19) + stale 이면 `어제까지 기록`(12, 보조). 기준선을 맞춘다.
        val titleBox = dp(20f) * k
        val title = textPaint(19f * k, ink.ink)
        val titleBase = baselineIn(title, 0f, titleBox)
        c.drawText(model.monthTitle, 0f, titleBase, title)
        if (model.stale) {
            val note = textPaint(12f * k, ink.soft)
            c.drawText("어제까지 기록", title.measureText(model.monthTitle) + dp(6f), titleBase, note)
        }

        val headTop = titleBox + gapTitle
        val headBox = dp(12f) * k
        val headSizeDp = min(12f * k, colW / scale * 0.55f)
        val head = textPaint(headSizeDp, ink.soft)
        val headBase = baselineIn(head, headTop, headBox)
        for (i in 0 until 7) {
            val label = WEEKDAYS[i]
            c.drawText(label, colW * (i + 0.5f) - head.measureText(label) / 2f, headBase, head)
        }

        val gridTop = headTop + headBox + gapHead
        val numSizePx = cell * 0.64f
        val showNumbers = numSizePx / scale >= 9f

        val fill = Paint(Paint.ANTI_ALIAS_FLAG)
        val ring = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = dp(1.5f)
            color = ink.ink
        }
        val num = TextPaint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
            typeface = font
            textSize = numSizePx
        }

        model.calendarCells(weeks).forEachIndexed { i, cellInfo ->
            val cx = colW * (i % 7 + 0.5f)
            val cy = gridTop + pitch * (i / 7 + 0.5f)
            val r = cell / 2f
            val fillColor = ink.levelFill(cellInfo.level)
            if (cellInfo.level > 0) {
                fill.color = fillColor
                c.drawCircle(cx, cy, r, fill)
            }
            if (cellInfo.isToday && signedIn) {
                c.drawCircle(cx, cy, r - ring.strokeWidth / 2f, ring)
            }
            if (showNumbers) {
                num.color = when {
                    cellInfo.faint -> ink.faint
                    cellInfo.level > 0 -> ink.numberOn(fillColor)
                    else -> ink.ink
                }
                val label = cellInfo.date.dayOfMonth.toString()
                // 시안은 숫자에 padding-top 1px 을 줘서 손글씨가 원 가운데보다 살짝 아래에 앉는다.
                val base = baselineIn(num, cy - r, cell) + dp(0.5f)
                c.drawText(label, cx - num.measureText(label) / 2f, base, num)
            }
        }
        return bmp
    }

    /**
     * 소형 이번 주 한 줄: 요일(12, 보조) 밑에 지름 15 점 7개.
     * 공부한 날은 칠하고, 안 한 지난 날과 미래는 #E3D7C0 1.5dp 점선 원, 오늘은 잉크 테두리.
     */
    fun week(model: WidgetModel, widthDp: Float): Bitmap {
        val labelBox = 12f
        val gap = 3f
        val colW = dp(widthDp) / 7f
        val dotDp = min(15f, colW / scale - 2f).coerceAtLeast(8f)
        val (bmp, c) = newCanvas(widthDp, labelBox + gap + dotDp)

        val label = textPaint(min(12f, colW / scale * 0.6f), ink.soft)
        val labelBase = baselineIn(label, 0f, dp(labelBox))
        val fill = Paint(Paint.ANTI_ALIAS_FLAG)
        val ring = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = dp(1.5f)
            color = ink.ink
        }
        val dotted = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = dp(1.5f)
            strokeCap = Paint.Cap.ROUND
            color = WidgetInk.DOT_EMPTY
            pathEffect = DashPathEffect(floatArrayOf(0.01f, dp(3f)), 0f)
        }

        val r = dp(dotDp) / 2f
        val cy = dp(labelBox + gap) + r
        model.calendarCells(1).forEachIndexed { i, cell ->
            val cx = colW * (i + 0.5f)
            c.drawText(WEEKDAYS[i], cx - label.measureText(WEEKDAYS[i]) / 2f, labelBase, label)
            val inset = dp(1.5f) / 2f
            if (cell.level > 0) {
                fill.color = ink.levelFill(cell.level)
                c.drawCircle(cx, cy, r, fill)
            }
            when {
                cell.isToday -> c.drawCircle(cx, cy, r - inset, ring)
                cell.level == 0 -> {
                    val path = Path().apply { addCircle(cx, cy, r - inset, Path.Direction.CW) }
                    c.drawPath(path, dotted)
                }
            }
        }
        return bmp
    }

    /**
     * 마스킹테이프: 테마 색 30%, 위쪽 가운데, top -6dp, 높이 16dp, 살짝 기울임.
     * 종이 밖으로 나간 6dp 는 비트맵 밖이라 잘린다. Android 12 미만은 위젯 뷰를 모서리 모양으로 자르지 않아서
     * 넘친 부분을 뷰에 맡기지 않고 비트맵에서 미리 잘라 둔다.
     */
    fun tape(widthDp: Float, angleDeg: Float): Bitmap {
        val (bmp, c) = newCanvas(widthDp + 8f, 13f)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = ink.tape }
        val cx = dp(widthDp + 8f) / 2f
        val cy = dp(-6f + 8f)
        c.save()
        c.rotate(angleDeg, cx, cy)
        c.drawRoundRect(
            RectF(cx - dp(widthDp) / 2f, cy - dp(8f), cx + dp(widthDp) / 2f, cy + dp(8f)),
            dp(2f), dp(2f), paint,
        )
        c.restore()
        return bmp
    }

    /**
     * 프로필 스티커. 앱이 찍어 둔 ProfileAvatar PNG 가 있으면 그것을, 없으면 맨 개구리 얼굴을
     * -6도 기울여 붙인다. PNG 는 원형이라 기울여도 모서리 밖으로 크게 넘치지 않는다.
     */
    fun profile(photo: Bitmap?, sizeDp: Float): Bitmap {
        val (bmp, c) = newCanvas(sizeDp, sizeDp)
        val size = dp(sizeDp)
        c.save()
        c.rotate(-6f, size / 2f, size / 2f)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        if (photo != null) {
            c.drawBitmap(photo, null, RectF(0f, 0f, size, size), paint)
        } else {
            drawFrogCircle(c, size)
        }
        c.restore()
        return bmp
    }

    /** 로그인 안내 화면의 맨 개구리. 흰 원, #F0E7D6 1.5dp 테두리, 얼굴을 원에 꽉 채운다. */
    private fun drawFrogCircle(c: Canvas, size: Float) {
        val stroke = dp(1.5f)
        val r = size / 2f - stroke / 2f
        val cx = size / 2f
        val white = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = android.graphics.Color.WHITE }
        c.drawCircle(cx, cx, r, white)
        frogFace()?.let { face ->
            c.save()
            c.clipPath(Path().apply { addCircle(cx, cx, r, Path.Direction.CW) })
            c.drawBitmap(face, null, RectF(cx - r, cx - r, cx + r, cx + r), Paint(Paint.FILTER_BITMAP_FLAG))
            c.restore()
        }
        val edge = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = stroke
            color = WidgetInk.FROG_EDGE
        }
        c.drawCircle(cx, cx, r, edge)
    }

    private fun frogFace(): Bitmap? = try {
        BitmapFactory.decodeResource(appContext.resources, R.drawable.widget_frog_face)
    } catch (e: Exception) {
        null
    }

    companion object {
        val WEEKDAYS = arrayOf("일", "월", "화", "수", "목", "금", "토")

        /**
         * 앱이 renderFlutterWidget 으로 저장한 프로필 PNG (논리 88px x 3배 = 264px 안팎)를 위젯 크기에 맞게
         * 줄여 읽는다. 파일이 없거나(로그아웃하면 앱이 지운다) 깨졌으면 null 이고, 그러면 맨 개구리를 쓴다.
         */
        fun decodeProfile(path: String?, targetPx: Int): Bitmap? {
            if (path.isNullOrBlank()) return null
            return try {
                val file = File(path)
                if (!file.isFile) return null
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(path, bounds)
                if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
                var sample = 1
                while (bounds.outWidth / (sample * 2) >= targetPx && bounds.outHeight / (sample * 2) >= targetPx) {
                    sample *= 2
                }
                BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
            } catch (e: Exception) {
                null
            } catch (e: OutOfMemoryError) {
                null
            }
        }
    }
}
