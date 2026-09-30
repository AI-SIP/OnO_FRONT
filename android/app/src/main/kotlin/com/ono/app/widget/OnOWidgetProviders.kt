package com.ono.app.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 크기별 Provider 세 개의 공통 부분.
 *
 * 크기마다 Provider 를 따로 두는 것은 위젯 목록에 크기별로 따로 보여야 iOS 와 고르는 방식이 같아지기 때문이다.
 * 클래스 이름은 Dart 가 HomeWidget.updateWidget(qualifiedAndroidName: ...) 으로 부르는 이름이라
 * 계약서(위젯_데이터_계약.md)와 한 글자도 달라지면 안 된다.
 *
 * home_widget 의 HomeWidgetProvider 는 onUpdate 에서 앱과 같은 SharedPreferences(HomeWidgetPreferences)를
 * 넘겨준다. Dart 가 updateWidget 을 부르면 ACTION_APPWIDGET_UPDATE 브로드캐스트로 여기 onUpdate 가 불린다.
 */
abstract class OnOWidgetProvider internal constructor(private val size: WidgetSize) : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            WidgetRenderer.update(context, appWidgetManager, id, size, widgetData)
        }
        // 앱이 값을 쓸 때, 부팅이나 앱 업데이트 뒤 시스템이 다시 그리라고 할 때 모두 여기로 온다.
        // 그때마다 다음 자정 알람을 다시 걸어 두면 재부팅으로 알람이 지워져도 복구된다.
        WidgetMidnight.schedule(context)
    }

    /** 위젯 크기를 바꾸면 칸 크기에 맞춰 비트맵을 다시 그린다. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        WidgetRenderer.update(context, appWidgetManager, appWidgetId, size, HomeWidgetPlugin.getData(context))
    }

    /** 이 크기의 마지막 위젯이 지워졌을 때. 세 크기 모두 하나도 없으면 자정 알람도 거둔다. */
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        if (!WidgetMidnight.hasAnyWidget(context)) {
            WidgetMidnight.cancel(context)
        }
    }
}

/** 소형 (2x2). 전체를 누르면 복습 예정 화면. */
class OnOSmallWidgetProvider : OnOWidgetProvider(WidgetSize.SMALL)

/** 중형 (4x2). 전체를 누르면 학습 달력. */
class OnOMediumWidgetProvider : OnOWidgetProvider(WidgetSize.MEDIUM)

/** 대형 (4x4). 달력은 학습 달력, 복습 머리줄은 복습 예정, 추천 줄은 그 문제 상세. */
class OnOLargeWidgetProvider : OnOWidgetProvider(WidgetSize.LARGE)
