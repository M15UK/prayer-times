package com.mesharialsadoun.prayer_times.widget

import android.app.PendingIntent
import android.content.Context
import android.graphics.Typeface
import android.os.SystemClock
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.RelativeSizeSpan
import android.text.style.StyleSpan
import android.view.View
import android.widget.RemoteViews
import com.mesharialsadoun.prayer_times.R
import java.util.Locale

private val CELL_IDS = intArrayOf(R.id.cell0, R.id.cell1, R.id.cell2, R.id.cell3, R.id.cell4, R.id.cell5)
private val NAME_IDS = intArrayOf(R.id.name0, R.id.name1, R.id.name2, R.id.name3, R.id.name4, R.id.name5)
private val TIME_IDS = intArrayOf(R.id.time0, R.id.time1, R.id.time2, R.id.time3, R.id.time4, R.id.time5)
private val ICON_IDS = intArrayOf(R.id.icon0, R.id.icon1, R.id.icon2, R.id.icon3, R.id.icon4, R.id.icon5)

/**
 * Fills [style]'s layout for this moment, or shows "open the app" once the
 * saved days have run out. Each layout has only some of these views;
 * Android skips the rest, so one renderer serves every style.
 */
fun styleViews(
    context: Context,
    style: WidgetStyle,
    payload: Payload?,
    pick: Pick?,
    now: Long,
    countdown: Boolean,
    is24Hour: Boolean,
): RemoteViews {
    val views = baseViews(context, style.layout, payload)
    val next = pick?.next
    if (payload == null || next == null) return views.showMessage(context, payload)
    val locale = Locale.forLanguageTag(payload.lang)
    val time = { row: Row, bold: Boolean -> timeText(clockText(row.time, is24Hour, locale), bold) }
    views.setViewVisibility(R.id.message, View.GONE)
    views.setViewVisibility(R.id.content, View.VISIBLE)
    views.setTextViewText(R.id.date, pick.today.date)
    views.setTextViewText(R.id.hijri, pick.today.hijri)
    views.setTextViewText(R.id.place, payload.place)
    views.setTextViewText(R.id.calculated, payload.calculated)
    views.setViewVisibility(R.id.calculated, if (payload.calculated.isEmpty()) View.GONE else View.VISIBLE)
    views.setViewVisibility(R.id.ampm, if (is24Hour) View.GONE else View.VISIBLE)
    views.setTextViewText(R.id.next_name, next.name)
    views.setTextViewText(R.id.next_time, time(next, false))
    views.countdownTo(next.at, now, countdown, style.countdownFormat)
    views.fillCells(context, pick.today, next, time, iconsShown = payload.calculated.isEmpty())
    return views
}

/**
 * The six times, the next one bold on the light pill. The strip's icons
 * make room for the "Calculated" mark, which must never be clipped.
 */
private fun RemoteViews.fillCells(
    context: Context,
    today: Day,
    next: Row,
    time: (Row, Boolean) -> CharSequence,
    iconsShown: Boolean,
) {
    val text = context.getColor(R.color.widget_text)
    val onPill = context.getColor(R.color.widget_on_pill)
    val icon = context.getColor(R.color.widget_icon)
    CELL_IDS.forEachIndexed { i, cellId ->
        val row = today.rows.getOrNull(i)
        setViewVisibility(cellId, if (row == null) View.GONE else View.VISIBLE)
        if (row == null) return@forEachIndexed
        val highlight = row == next // never sunrise; none after Isha, as next is tomorrow's Fajr
        setInt(cellId, "setBackgroundResource", if (highlight) R.drawable.widget_pill else 0)
        setTextViewText(NAME_IDS[i], if (highlight) bold(row.name) else row.name)
        setTextColor(NAME_IDS[i], if (highlight) onPill else text)
        setTextViewText(TIME_IDS[i], time(row, highlight))
        setTextColor(TIME_IDS[i], if (highlight) onPill else text)
        setViewVisibility(ICON_IDS[i], if (iconsShown) View.VISIBLE else View.GONE)
        setInt(ICON_IDS[i], "setColorFilter", if (highlight) onPill else icon)
    }
}

private fun bold(text: String) = SpannableStringBuilder(text).apply {
    setSpan(StyleSpan(Typeface.BOLD), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
}

/** "5:53 PM" with a smaller "PM", bold for the next prayer. */
private fun timeText(clock: ClockText, bold: Boolean): CharSequence {
    val text = SpannableStringBuilder(clock.digits)
    if (clock.suffix.isNotEmpty()) {
        val start = text.length
        text.append(' ').append(clock.suffix)
        text.setSpan(RelativeSizeSpan(0.7f), start, text.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
    if (bold) text.setSpan(StyleSpan(Typeface.BOLD), 0, text.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    return text
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

/** Counts down to [at], or hides the countdown when it can't be trusted to stop at zero. */
private fun RemoteViews.countdownTo(at: Long, now: Long, shown: Boolean, format: String) {
    setViewVisibility(R.id.countdown, if (shown) View.VISIBLE else View.GONE)
    if (!shown) return
    // The countdown runs on the phone's uptime clock, so it is set from now.
    setChronometer(R.id.countdown, SystemClock.elapsedRealtime() + (at - now), format, true)
    setChronometerCountDown(R.id.countdown, true)
}
