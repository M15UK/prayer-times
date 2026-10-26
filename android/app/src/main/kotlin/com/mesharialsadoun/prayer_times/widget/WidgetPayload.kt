package com.mesharialsadoun.prayer_times.widget

import org.json.JSONException
import org.json.JSONObject

// The widgets' data, written by the app (lib/data/widget_payload.dart). Pure
// Kotlin with no Android parts, so it is tested on the computer.

/** The payload format this version reads; any other is ignored. */
const val PAYLOAD_VERSION = 1

/** One time on the widget: a prayer, or sunrise, which is never [counts]ed down to. */
data class Row(val name: String, val time: String, val at: Long, val counts: Boolean)

/** One day in the timetable's own time zone, from [start] until [end]. */
data class Day(val start: Long, val end: Long, val rows: List<Row>)

/** Everything the app saved, with the text already in the app's language. */
data class Payload(
    val rtl: Boolean,
    val place: String,
    val placeLine: String,
    val source: String,
    val openApp: String,
    val days: List<Day>,
)

/** What to show now: today's times, the next prayer, and when to look again. */
data class Pick(val today: Day, val next: Row?, val wakeAt: Long)

/** The app's payload, or null if it is missing, broken or another version. */
fun parsePayload(json: String?): Payload? {
    if (json == null) return null
    return try {
        val payload = JSONObject(json)
        if (payload.getInt("v") != PAYLOAD_VERSION) return null
        val days = payload.getJSONArray("days")
        Payload(
            rtl = payload.getBoolean("rtl"),
            place = payload.getString("place"),
            placeLine = payload.getString("placeLine"),
            source = payload.getString("source"),
            openApp = payload.getString("openApp"),
            days = List(days.length()) { parseDay(days.getJSONObject(it)) },
        )
    } catch (_: JSONException) {
        null // the caller says so in the log
    }
}

private fun parseDay(day: JSONObject): Day {
    val rows = day.getJSONArray("rows")
    return Day(
        start = day.getLong("start"),
        end = day.getLong("end"),
        rows = List(rows.length()) {
            val row = rows.getJSONObject(it)
            Row(row.getString("name"), row.getString("time"), row.getLong("at"), row.getBoolean("counts"))
        },
    )
}

/**
 * Today and the next prayer at [now] (milliseconds since 1970), or null once
 * the saved days have run out. [Pick.wakeAt] is when the widget must change:
 * the next prayer, or midnight if that comes first.
 */
fun pick(payload: Payload, now: Long): Pick? {
    val today = payload.days.firstOrNull { now >= it.start && now < it.end } ?: return null
    val next = payload.days
        .asSequence()
        .filter { it.end > now }
        .flatMap { it.rows }
        .firstOrNull { it.counts && it.at > now }
    return Pick(today, next, minOf(next?.at ?: today.end, today.end))
}
