package com.ono.app.widget

import android.graphics.Color
import org.json.JSONObject
import java.time.LocalDate
import java.time.YearMonth

/**
 * 앱이 `ono_widget_snapshot` 키에 써 둔 JSON 한 개를 읽은 결과.
 *
 * 모양과 규칙은 docs/홈 화면 위젯/위젯_데이터_계약.md 가 기준이다. iOS 위젯과 같은 결과가 나와야 해서
 * 계약서에 없는 해석은 넣지 않는다. 계약서와 다르게 읽는 곳은 주석으로 이유를 남긴다.
 */
internal sealed class WidgetSnapshot {

    /** 앱이 쓴 로그아웃 스냅샷(`loggedIn: false`). 로그인하라는 안내 화면이다. */
    object SignedOut : WidgetSnapshot()

    /**
     * 스냅샷이 아직 없거나(위젯만 새로 두고 앱을 안 연 경우) 깨졌거나 모르는 버전일 때.
     * [SignedOut] 과 같은 화면이고 앱을 열라는 문구만 다르다.
     */
    object NoSnapshot : WidgetSnapshot()

    data class SignedIn(
        val today: LocalDate,
        val themeColor: Int,
        val currentStreak: Int,
        val thisMonthStudyDays: Int,
        val lastStudiedDate: LocalDate?,
        val dueCount: Int,
        val overdueCount: Int,
        val recommendations: List<Recommendation>,
        val levels: Map<LocalDate, Int>,
        val profileVersion: Int,
    ) : WidgetSnapshot()

    data class Recommendation(val problemId: Long, val title: String, val overdueDays: Int)

    companion object {
        const val KEY_SNAPSHOT = "ono_widget_snapshot"
        const val KEY_PROFILE = "ono_widget_profile"

        /** 위젯이 아는 스키마 버전. 이보다 큰 v 는 스냅샷이 없는 것과 같은 안내 화면으로 보여 준다. */
        private const val KNOWN_VERSION = 1

        /** 로그아웃 스냅샷에는 테마 색이 없어서, 안내 화면은 앱 기본 테마 색으로 그린다. */
        val DEFAULT_THEME_COLOR: Int = Color.parseColor("#F48FB1")

        fun parse(json: String?): WidgetSnapshot {
            if (json.isNullOrBlank()) return NoSnapshot
            return try {
                val o = JSONObject(json)
                val v = o.optInt("v", 0)
                if (v < 1 || v > KNOWN_VERSION) return NoSnapshot
                if (!o.optBoolean("loggedIn", false)) return SignedOut
                SignedIn(
                    today = LocalDate.parse(o.getString("today")),
                    themeColor = parseColor(o.opt("themeColor") as? String),
                    currentStreak = o.optInt("currentStreak", 0).coerceAtLeast(0),
                    thisMonthStudyDays = o.optInt("thisMonthStudyDays", 0).coerceAtLeast(0),
                    lastStudiedDate = parseDateOrNull(o.opt("lastStudiedDate")),
                    dueCount = o.optInt("dueCount", 0).coerceAtLeast(0),
                    overdueCount = o.optInt("overdueCount", 0).coerceAtLeast(0),
                    recommendations = parseRecommendations(o),
                    levels = parseLevels(o),
                    profileVersion = o.optInt("profileVersion", 0),
                )
            } catch (e: Exception) {
                // 필수 값(today)이 없거나 JSON 이 깨졌으면 앞 사용자 값이 섞여 보일 수 있는 화면보다
                // 안내 화면이 안전하다. 앱을 한 번 열면 다시 써진다.
                NoSnapshot
            }
        }

        private fun parseColor(hex: String?): Int = try {
            if (hex != null && hex.length == 7 && hex[0] == '#') Color.parseColor(hex) else DEFAULT_THEME_COLOR
        } catch (e: IllegalArgumentException) {
            DEFAULT_THEME_COLOR
        }

        private fun parseDateOrNull(value: Any?): LocalDate? {
            if (value !is String || value.isBlank()) return null
            return try {
                LocalDate.parse(value)
            } catch (e: Exception) {
                null
            }
        }

        private fun parseRecommendations(o: JSONObject): List<Recommendation> {
            val arr = o.optJSONArray("recommendations") ?: return emptyList()
            val out = ArrayList<Recommendation>(3)
            for (i in 0 until arr.length()) {
                val r = arr.optJSONObject(i) ?: continue
                val id = r.optLong("problemId", -1L)
                if (id < 0) continue
                // optString 은 JSON null 을 "null" 글자로 돌려주므로 문자열일 때만 쓴다.
                val title = ((r.opt("title") as? String)?.trim()).orEmpty().ifEmpty { "문제 $id" }
                out.add(Recommendation(id, title, r.optInt("overdueDays", 0).coerceAtLeast(0)))
                if (out.size == 3) break
            }
            return out
        }

        private fun parseLevels(o: JSONObject): Map<LocalDate, Int> {
            val arr = o.optJSONArray("days") ?: return emptyMap()
            val out = HashMap<LocalDate, Int>(arr.length())
            for (i in 0 until arr.length()) {
                val d = arr.optJSONObject(i) ?: continue
                val date = parseDateOrNull(d.opt("date")) ?: continue
                out[date] = d.optInt("level", 0).coerceIn(0, 3)
            }
            return out
        }
    }
}

/** 달력 한 칸. 그리는 쪽은 이 값만 보고, 날짜 규칙은 [WidgetModel] 이 정한다. */
internal data class CalendarCell(
    val date: LocalDate,
    val level: Int,
    val faint: Boolean,
    val isToday: Boolean,
    val future: Boolean,
)

/**
 * 스냅샷을 기기 오늘 날짜에 맞춰 푼 값. 계약서 「오늘과 날짜가 바뀐 경우」 규칙이 여기 모여 있다.
 */
internal class WidgetModel(val snapshot: WidgetSnapshot, val deviceToday: LocalDate) {

    val signedIn: WidgetSnapshot.SignedIn? = snapshot as? WidgetSnapshot.SignedIn

    val themeColor: Int = signedIn?.themeColor ?: WidgetSnapshot.DEFAULT_THEME_COLOR

    /** 스냅샷을 만든 날보다 오늘이 뒤면 stale. 기기 시계를 되돌린 경우는 stale 로 보지 않는다. */
    val stale: Boolean = signedIn != null && deviceToday.isAfter(signedIn.today)

    /**
     * 연속 일수. lastStudiedDate 가 어제 이후면 서버 값 그대로, 아니면 끊긴 것으로 0.
     * 서버도 "오늘 공부했으면 오늘부터, 아니면 어제부터" 세기 때문에 같은 결과가 나온다.
     */
    val streak: Int = signedIn?.let { s ->
        val last = s.lastStudiedDate
        if (last != null && !last.isBefore(deviceToday.minusDays(1))) s.currentStreak else 0
    } ?: 0

    /**
     * 이번 달 공부한 날. 계약서에는 없는 해석이다: 스냅샷을 만든 달이 지나 새 달이 됐으면 0 으로 적는다.
     * 앱을 열어야만 공부할 수 있고, 앱을 열면 스냅샷이 새로 써지므로 새 달에 공부한 날은 아직 없다.
     */
    val thisMonthStudyDays: Int = signedIn?.let { s ->
        if (YearMonth.from(s.today) == YearMonth.from(deviceToday)) s.thisMonthStudyDays else 0
    } ?: 0

    val monthTitle: String = "${deviceToday.monthValue}월"

    /**
     * 오늘이 속한 주가 맨 아래 줄인 달력 칸들. weeks 줄 x 7칸, 일요일 시작.
     * - 오늘보다 뒤: 미래 칸 (흐린 숫자, 칠하지 않음)
     * - 스냅샷 today 보다 뒤: level 0 (앱을 안 연 날은 모른다)
     * - 그 밖: days 에서 찾고 없으면 0
     * - 로그아웃이면 숫자만 적고 칠하지 않는다
     */
    fun calendarCells(weeks: Int): List<CalendarCell> {
        val sunday = deviceToday.minusDays((deviceToday.dayOfWeek.value % 7).toLong())
        val start = sunday.minusWeeks((weeks - 1).toLong())
        val thisMonth = YearMonth.from(deviceToday)
        return (0 until weeks * 7).map { i ->
            val date = start.plusDays(i.toLong())
            val future = date.isAfter(deviceToday)
            val s = signedIn
            val level = when {
                s == null -> 0
                future -> 0
                date.isAfter(s.today) -> 0
                else -> s.levels[date] ?: 0
            }
            CalendarCell(
                date = date,
                level = level,
                faint = future || YearMonth.from(date) != thisMonth,
                isToday = date == deviceToday,
                future = future,
            )
        }
    }
}
