package com.mesharialsadoun.prayer_times.widget

import android.app.AlarmManager
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * What every style's provider does: redraw all the widgets. When the last
 * widget of a style is removed, redrawing also cancels the alarm if no
 * widget is left at all.
 */
abstract class StyleWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        refreshWidgets(context)

    override fun onDisabled(context: Context) = refreshWidgets(context)
}

class MiniWidget : StyleWidget()
class DateLocationWidget : StyleWidget()
class PrayerStripWidget : StyleWidget()
class FullHorizontalWidget : StyleWidget()
class DigitalClockWidget : StyleWidget()
class FullVerticalWidget : StyleWidget()

/**
 * Redraws the widgets when they must change, and after anything that loses
 * the alarm or moves the clock: a restart, an app update, a manual change
 * of the phone's time, or exact timing being allowed.
 */
class RefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action in REFRESH_ACTIONS) refreshWidgets(context)
    }
}

/** The manifest's actions for RefreshReceiver, plus the widget's own alarm. */
private val REFRESH_ACTIONS = setOf(
    ACTION_WAKE,
    Intent.ACTION_TIME_CHANGED,
    Intent.ACTION_BOOT_COMPLETED,
    Intent.ACTION_MY_PACKAGE_REPLACED,
    AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED,
)
