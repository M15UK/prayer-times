package com.mesharialsadoun.prayer_times.widget

import android.app.PendingIntent
import android.content.Context
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import com.mesharialsadoun.prayer_times.R

private val ROW_IDS = intArrayOf(R.id.row0, R.id.row1, R.id.row2, R.id.row3, R.id.row4, R.id.row5)
private val NAME_IDS = intArrayOf(R.id.name0, R.id.name1, R.id.name2, R.id.name3, R.id.name4, R.id.name5)
private val TIME_IDS = intArrayOf(R.id.time0, R.id.time1, R.id.time2, R.id.time3, R.id.time4, R.id.time5)

/** The small widget, or a message to open the app if there's no next prayer saved. */
fun nextPrayerViews(context: Context, payload: Payload?, pick: Pick?, now: Long, countdown: Boolean): RemoteViews {
    val views = baseViews(context, R.layout.widget_next, payload)
    val next = pick?.next
    if (payload == null || next == null) return views.showMessage(context, payload)
    views.showContent()
    views.setTextViewText(R.id.next_name, next.name)
    views.setTextViewText(R.id.next_time, next.time)
    views.setTextViewText(R.id.place, payload.placeLine)
    views.countdownTo(next.at, now, countdown)
    return views
}

/** The larger widget, or a message to open the app once the saved days run out. */
fun todayViews(context: Context, payload: Payload?, pick: Pick?, now: Long, countdown: Boolean): RemoteViews {
    val views = baseViews(context, R.layout.widget_today, payload)
    if (payload == null || pick == null) return views.showMessage(context, payload)
    views.showContent()
    views.setTextViewText(R.id.place, payload.place)
    views.setTextViewText(R.id.source, payload.source)
    ROW_IDS.forEachIndexed { i, rowId ->
        val row = pick.today.rows.getOrNull(i)
        views.setViewVisibility(rowId, if (row == null) View.INVISIBLE else View.VISIBLE)
        views.setTextViewText(NAME_IDS[i], row?.name)
        views.setTextViewText(TIME_IDS[i], row?.time)
        val highlight = row != null && row == pick.next
        views.setInt(rowId, "setBackgroundResource", if (highlight) R.drawable.widget_next_row else 0)
    }
    val next = pick.next // none after Isha on the last saved day
    if (next == null) views.setViewVisibility(R.id.countdown, View.GONE) else views.countdownTo(next.at, now, countdown)
    return views
}

private fun baseViews(context: Context, layout: Int, payload: Payload?) =
    RemoteViews(context.packageName, layout).apply {
        // The app's language may differ from the phone's, so set either way.
        // With nothing saved yet, the phone's own direction is kept.
        payload?.let {
            setInt(R.id.root, "setLayoutDirection", if (it.rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
        }
        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { launch ->
            val open = PendingIntent.getActivity(
                context,
                0,
                launch,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            setOnClickPendingIntent(R.id.root, open)
        }
    }

private fun RemoteViews.showMessage(context: Context, payload: Payload?): RemoteViews {
    setViewVisibility(R.id.content, View.GONE)
    setViewVisibility(R.id.message, View.VISIBLE)
    setTextViewText(R.id.message, payload?.openApp ?: context.getString(R.string.widget_open_app))
    return this
}

private fun RemoteViews.showContent() {
    setViewVisibility(R.id.message, View.GONE)
    setViewVisibility(R.id.content, View.VISIBLE)
}

/** Counts down to [at], or hides the countdown when it can't be trusted to stop at zero. */
private fun RemoteViews.countdownTo(at: Long, now: Long, shown: Boolean) {
    setViewVisibility(R.id.countdown, if (shown) View.VISIBLE else View.GONE)
    if (!shown) return
    // The countdown runs on the phone's uptime clock, so it is set from now.
    setChronometer(R.id.countdown, SystemClock.elapsedRealtime() + (at - now), null, true)
    setChronometerCountDown(R.id.countdown, true)
}
