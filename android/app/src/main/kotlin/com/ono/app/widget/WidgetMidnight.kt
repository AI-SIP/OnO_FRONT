package com.ono.app.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import es.antonborri.home_widget.HomeWidgetPlugin
import java.time.LocalDate
import java.time.ZoneId

/**
 * 앱을 열지 않아도 날짜가 바뀌면 오늘 칸이 넘어가게, 다음 현지 자정에 세 위젯을 다시 그린다.
 *
 * - AlarmManager.setWindow(RTC) 정확하지 않은 알람만 쓴다. SCHEDULE_EXACT_ALARM 권한을 받으면 스토어 신고 항목이
 *   늘고, 몇 분 늦게 넘어가는 건 괜찮다. RTC(깨우지 않음)라 화면이 꺼져 있으면 다음에 깨어날 때 울린다.
 *   화면이 꺼져 있을 때는 어차피 위젯을 볼 수 없어서 배터리를 쓰며 깨울 이유가 없다.
 * - 그릴 때마다 다음 자정을 다시 건다. 알람 하나를 같은 PendingIntent 로 덮어쓰므로 쌓이지 않는다.
 * - 재부팅하면 알람이 지워지지만, 부팅 뒤 시스템이 위젯마다 APPWIDGET_UPDATE 를 보내 onUpdate 에서 다시 걸린다.
 *   BOOT_COMPLETED 는 RECEIVE_BOOT_COMPLETED 권한이 필요해서 받지 않는다.
 */
internal object WidgetMidnight {

    private const val TAG = "OnOWidget"
    const val ACTION_MIDNIGHT = "com.ono.app.widget.action.MIDNIGHT"
    private const val MIDNIGHT_WINDOW_MS = 10 * 60 * 1000L

    private val providers = arrayOf(
        OnOSmallWidgetProvider::class.java to WidgetSize.SMALL,
        OnOMediumWidgetProvider::class.java to WidgetSize.MEDIUM,
        OnOLargeWidgetProvider::class.java to WidgetSize.LARGE,
    )

    fun schedule(context: Context) {
        try {
            val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val zone = ZoneId.systemDefault()
            // 자정 직후 1분에 건다. 부정확한 알람이 조금 일찍 울려도 날짜가 이미 바뀌어 있게 하려는 것이다.
            val next = LocalDate.now(zone).plusDays(1).atStartOfDay(zone).plusMinutes(1).toInstant().toEpochMilli()
            // set() 은 시스템이 한 시간 가까이 미룰 수 있어서, 정확한 알람 권한 없이 쓸 수 있는 setWindow 로
            // 자정 뒤 10분 안에 울리게 좁힌다.
            am.setWindow(AlarmManager.RTC, next, MIDNIGHT_WINDOW_MS, pendingIntent(context))
        } catch (e: Exception) {
            Log.w(TAG, "자정 갱신 알람을 걸지 못했다", e)
        }
    }

    fun cancel(context: Context) {
        try {
            val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            am.cancel(pendingIntent(context))
        } catch (e: Exception) {
            Log.w(TAG, "자정 갱신 알람을 거두지 못했다", e)
        }
    }

    fun hasAnyWidget(context: Context): Boolean {
        val manager = AppWidgetManager.getInstance(context)
        return providers.any { (cls, _) -> manager.getAppWidgetIds(ComponentName(context, cls)).isNotEmpty() }
    }

    /** 세 크기의 모든 위젯을 스냅샷에서 다시 그린다. 서버는 부르지 않는다. */
    fun redrawAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val prefs = HomeWidgetPlugin.getData(context)
        var any = false
        for ((cls, size) in providers) {
            val ids = manager.getAppWidgetIds(ComponentName(context, cls))
            for (id in ids) {
                WidgetRenderer.update(context, manager, id, size, prefs)
                any = true
            }
        }
        if (any) schedule(context) else cancel(context)
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, WidgetMidnightReceiver::class.java).setAction(ACTION_MIDNIGHT)
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}

/**
 * 자정 알람, 시각이나 시간대 변경, 앱 업데이트 뒤에 위젯을 다시 그린다.
 *
 * TIME_SET, TIMEZONE_CHANGED 는 Android 8 이후에도 매니페스트 리시버로 받을 수 있는 예외 브로드캐스트다.
 * DATE_CHANGED 는 예외 목록에 없어 Android 8 이상에서는 오지 않지만, 7.x 에서는 자정 알람보다 먼저 올 수 있어 둔다.
 */
class WidgetMidnightReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            WidgetMidnight.ACTION_MIDNIGHT,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> WidgetMidnight.redrawAll(context)
        }
    }
}
