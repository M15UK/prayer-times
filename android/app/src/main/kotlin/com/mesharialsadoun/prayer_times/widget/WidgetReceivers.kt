package com.mesharialsadoun.prayer_times.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** The small widget: the next prayer, its time, a countdown and the place. */
class NextPrayerWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        refreshWidgets(context)

    // The last one removed: refreshing cancels the alarm if no widget is left.
    override fun onDisabled(context: Context) = refreshWidgets(context)
}

/** The larger widget: today's six times, the next highlighted, and the source. */
class TodayWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        refreshWidgets(context)

    override fun onDisabled(context: Context) = refreshWidgets(context)
}

/**
 * Redraws the widgets when they must change, and after anything that loses
 * the alarm or moves the clock: a restart, an app update or a manual change
 * of the phone's time.
 */
class RefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) = refreshWidgets(context)
}
