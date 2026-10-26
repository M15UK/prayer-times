package com.mesharialsadoun.prayer_times.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

private const val ACTION_WAKE = "com.mesharialsadoun.prayer_times.widget.WAKE"

/** Android stretches any shorter window to 10 minutes (AlarmManager.setWindow). */
private const val WINDOW_MS = 10 * 60 * 1000L

/** Whether alarms may come at the exact minute. Android 12+ asks the user. */
fun canBeExact(context: Context): Boolean =
    Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
        context.getSystemService(AlarmManager::class.java).canScheduleExactAlarms()

/**
 * Asks to redraw the widgets at [at] (null: never). It never wakes the phone:
 * with the screen off, the widgets redraw when it next comes on.
 */
fun scheduleWake(context: Context, at: Long?) {
    val alarms = context.getSystemService(AlarmManager::class.java)
    val wake = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, RefreshReceiver::class.java).setAction(ACTION_WAKE),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )
    if (at == null) {
        alarms.cancel(wake)
        return
    }
    if (canBeExact(context)) {
        try {
            alarms.setExact(AlarmManager.RTC, at, wake)
            return
        } catch (e: SecurityException) {
            Log.w(TAG, "Exact timing was refused; redrawing within 10 minutes instead", e)
        }
    }
    alarms.setWindow(AlarmManager.RTC, at, WINDOW_MS, wake)
}
