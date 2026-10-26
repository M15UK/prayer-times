package com.mesharialsadoun.prayer_times.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.util.Log

private const val PREFS = "prayer_widgets"
private const val KEY_PAYLOAD = "payload"
internal const val TAG = "PrayerWidgets"

/** Keeps the app's latest payload for the widgets. */
fun storePayload(context: Context, json: String) {
    context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        .edit()
        .putString(KEY_PAYLOAD, json)
        .apply()
}

/**
 * Redraws every widget on the home screen for this moment, then sets the one
 * alarm for when they must change next (none if no widget is placed).
 */
fun refreshWidgets(context: Context) {
    val json = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_PAYLOAD, null)
    val payload = parsePayload(json)
    if (json != null && payload == null) Log.w(TAG, "The saved widget times could not be read")
    val now = System.currentTimeMillis()
    val pick = payload?.let { pick(it, now) }
    // Without exact timing the redraw can be minutes late, and the countdown
    // would show minus times meanwhile, so it is hidden. (If exact timing is
    // taken away later, Android says nothing: the 30-minute update fixes it.)
    val countdown = canBeExact(context)

    val manager = AppWidgetManager.getInstance(context)
    val nextIds = manager.getAppWidgetIds(ComponentName(context, NextPrayerWidget::class.java))
    val todayIds = manager.getAppWidgetIds(ComponentName(context, TodayWidget::class.java))
    if (nextIds.isNotEmpty()) {
        manager.updateAppWidget(nextIds, nextPrayerViews(context, payload, pick, now, countdown))
    }
    if (todayIds.isNotEmpty()) {
        manager.updateAppWidget(todayIds, todayViews(context, payload, pick, now, countdown))
    }
    val placed = nextIds.isNotEmpty() || todayIds.isNotEmpty()
    scheduleWake(context, if (placed) pick?.wakeAt else null)
}
