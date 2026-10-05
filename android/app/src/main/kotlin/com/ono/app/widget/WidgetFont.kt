package com.ono.app.widget

import android.content.Context
import android.graphics.Typeface
import android.os.Build
import com.ono.app.R
import java.io.File

/** 위젯 글자에 쓰는 글꼴. 손글씨는 연속 일수 큰 줄과 달력 월 제목에만 쓴다. */
internal enum class WidgetFace {
    /** 손글씨 (연속 일수, `9월`) */
    HAND,

    /** 시스템 sans-serif. 추천 문제 제목처럼 긴 본문 */
    TEXT,

    /** 시스템 sans-serif-medium. 보조 문장, 요일, 날짜 숫자, 복습 문구, 배지, 안내 문구 */
    MEDIUM,
}

/**
 * 위젯 손글씨 폰트(res/font/handwrite_widget.ttf, 계약서의 HandWriteWidget.ttf 서브셋).
 *
 * 문장, 요일, 날짜 숫자까지 손글씨로 쓰면 작은 글자가 뭉개져 읽기 어려워서 손글씨는 두 자리에만 쓰고
 * 나머지는 시스템 글꼴([text], [medium])로 그린다. 시스템 글꼴도 비트맵에 그리는 것은 같다.
 *
 * 위젯 글자는 TextView 가 아니라 이 Typeface 로 비트맵에 그린다. 이유:
 * - 런처는 RemoteViews 를 우리 앱 리소스로 펼칠 때 `createApplicationContext(.., CONTEXT_RESTRICTED)` 를 쓴다
 *   (android-34 RemoteViews.getContextForResourcesEnsuringCorrectCachedApkPaths).
 * - TextView 는 fontFamily 가 폰트 리소스여도 `!context.isRestricted()` 일 때만 불러온다
 *   (android-34 TextView.readTextAppearance, TextAppearance_fontFamily). 제한된 컨텍스트에서는
 *   리소스 경로 문자열을 패밀리 이름으로 보고 시스템 글꼴로 떨어진다.
 * - RemoteViews 에는 setTypeface 도 없다.
 * 그래서 API 레벨과 상관없이 TextView + @font 로는 손글씨가 나오지 않는다. API 26 미만은 애초에
 * 폰트 리소스를 모른다. 우리 프로세스에서 비트맵으로 그리면 모든 버전(24 이상)에서 같은 글씨가 나온다.
 */
internal object WidgetFont {

    @Volatile
    private var cached: Typeface? = null

    val text: Typeface by lazy { Typeface.create("sans-serif", Typeface.NORMAL) }
    val medium: Typeface by lazy { Typeface.create("sans-serif-medium", Typeface.NORMAL) }

    fun of(context: Context, face: WidgetFace): Typeface = when (face) {
        WidgetFace.HAND -> get(context)
        WidgetFace.TEXT -> text
        WidgetFace.MEDIUM -> medium
    }

    fun get(context: Context): Typeface {
        cached?.let { return it }
        synchronized(this) {
            cached?.let { return it }
            val loaded = load(context.applicationContext)
            cached = loaded
            return loaded
        }
    }

    private fun load(context: Context): Typeface {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.resources.getFont(R.font.handwrite_widget)
            } else {
                // API 24~25 는 Resources.getFont 가 없다. 폰트 리소스도 결국 APK 안의 파일이라
                // openRawResource 로 읽어 캐시 폴더에 한 번 풀어 두고 파일에서 만든다.
                val file = File(context.cacheDir, "widget_font_handwrite.ttf")
                if (!file.exists() || file.length() == 0L) {
                    val tmp = File(context.cacheDir, "widget_font_handwrite.ttf.tmp")
                    context.resources.openRawResource(R.font.handwrite_widget).use { input ->
                        tmp.outputStream().use { input.copyTo(it) }
                    }
                    tmp.renameTo(file)
                }
                Typeface.createFromFile(file)
            }
        } catch (e: Exception) {
            // 폰트를 못 읽어도 위젯이 비지 않게 기본 글꼴로 그린다.
            Typeface.DEFAULT
        }
    }
}
