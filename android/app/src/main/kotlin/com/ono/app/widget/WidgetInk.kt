package com.ono.app.widget

import android.graphics.Color
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

/**
 * 테마 색 하나에서 위젯 글씨와 칠 색을 뽑는다.
 *
 * 검정, 회색 글씨는 파스텔 테마와 어울리지 않아서, 테마 색의 색상(hue)은 두고 채도와 밝기만 내린
 * "잉크 색"을 쓴다. 값은 계약서 디자인 토큰 그대로다 (iOS 위젯과 같은 식).
 */
internal class WidgetInk(val theme: Int) {

    private val hsl = toHsl(theme)

    /** 본문: hue 유지, saturation = min(s, 0.5), lightness = 0.32 */
    val ink: Int = fromHsl(hsl[0], min(hsl[1], 0.5f), 0.32f)

    /** 보조: saturation = min(s, 0.35), lightness = 0.48 */
    val soft: Int = fromHsl(hsl[0], min(hsl[1], 0.35f), 0.48f)

    /** 흐림: 지난달과 미래 날짜 숫자. 보조 잉크를 saturation 0.30 이하로, 알파 0.45 */
    val faint: Int = withAlpha(fromHsl(hsl[0], min(hsl[1], 0.30f), 0.48f), 0.45f)

    /** 공부한 날 동그라미. level 1~3 → 테마 색 알파 0.30, 0.55, 0.85 */
    fun levelFill(level: Int): Int = when (level) {
        1 -> withAlpha(theme, 0.30f)
        2 -> withAlpha(theme, 0.55f)
        3 -> withAlpha(theme, 0.85f)
        else -> Color.TRANSPARENT
    }

    val tape: Int = withAlpha(theme, 0.30f)
    val highlight: Int = withAlpha(theme, 0.40f)

    /**
     * 칠한 동그라미 위 숫자 색. 대부분 테마는 잉크 색이 그대로 읽히지만, 진한 테마에서 level 3 처럼
     * 진하게 칠한 칸은 잉크와 바탕 명도가 비슷해질 수 있다. 종이 위에 칠한 실제 색과 대비가 3:1 보다
     * 낮고 흰색이 더 잘 읽히면 그 칸만 흰 숫자로 쓴다 (명세서 「진한 테마에서 동그라미 위 숫자」).
     */
    fun numberOn(fill: Int): Int {
        if (Color.alpha(fill) == 0) return ink
        val bg = composite(fill, PAPER)
        val inkContrast = contrast(ink, bg)
        return if (inkContrast < 3.0 && contrast(Color.WHITE, bg) > inkContrast) Color.WHITE else ink
    }

    companion object {
        val PAPER: Int = Color.parseColor("#FFFCF5")
        val RULE: Int = Color.parseColor("#F1E9D8")
        val DOT_EMPTY: Int = Color.parseColor("#E3D7C0")
        val FROG_EDGE: Int = Color.parseColor("#F0E7D6")

        /** 밀린 문제는 테마 색에 묻히지 않게 테라코타 하나로 고정한다. hsl(18, 50%, 44%) */
        val OVERDUE: Int = fromHsl(18f, 0.50f, 0.44f)

        fun withAlpha(color: Int, alpha: Float): Int =
            Color.argb((alpha * 255f + 0.5f).toInt(), Color.red(color), Color.green(color), Color.blue(color))

        fun toHsl(color: Int): FloatArray {
            val r = Color.red(color) / 255f
            val g = Color.green(color) / 255f
            val b = Color.blue(color) / 255f
            val mx = max(r, max(g, b))
            val mn = min(r, min(g, b))
            val l = (mx + mn) / 2f
            if (mx == mn) return floatArrayOf(0f, 0f, l)
            val d = mx - mn
            val s = if (l > 0.5f) d / (2f - mx - mn) else d / (mx + mn)
            val h = when (mx) {
                r -> (g - b) / d + (if (g < b) 6f else 0f)
                g -> (b - r) / d + 2f
                else -> (r - g) / d + 4f
            }
            return floatArrayOf(h * 60f, s, l)
        }

        fun fromHsl(h: Float, s: Float, l: Float): Int {
            val c = (1f - abs(2f * l - 1f)) * s
            val hp = ((h % 360f) + 360f) % 360f / 60f
            val x = c * (1f - abs(hp % 2f - 1f))
            val (r1, g1, b1) = when {
                hp < 1f -> Triple(c, x, 0f)
                hp < 2f -> Triple(x, c, 0f)
                hp < 3f -> Triple(0f, c, x)
                hp < 4f -> Triple(0f, x, c)
                hp < 5f -> Triple(x, 0f, c)
                else -> Triple(c, 0f, x)
            }
            val m = l - c / 2f
            fun ch(v: Float) = ((v + m) * 255f + 0.5f).toInt().coerceIn(0, 255)
            return Color.rgb(ch(r1), ch(g1), ch(b1))
        }

        private fun composite(top: Int, bottom: Int): Int {
            val a = Color.alpha(top) / 255f
            fun mix(t: Int, b: Int) = (t * a + b * (1f - a) + 0.5f).toInt()
            return Color.rgb(
                mix(Color.red(top), Color.red(bottom)),
                mix(Color.green(top), Color.green(bottom)),
                mix(Color.blue(top), Color.blue(bottom)),
            )
        }

        private fun luminance(color: Int): Double {
            fun lin(c: Int): Double {
                val v = c / 255.0
                return if (v <= 0.03928) v / 12.92 else ((v + 0.055) / 1.055).pow(2.4)
            }
            return 0.2126 * lin(Color.red(color)) + 0.7152 * lin(Color.green(color)) + 0.0722 * lin(Color.blue(color))
        }

        private fun contrast(a: Int, b: Int): Double {
            val la = luminance(a)
            val lb = luminance(b)
            return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
        }
    }
}
