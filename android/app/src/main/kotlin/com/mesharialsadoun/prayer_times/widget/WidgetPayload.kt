package com.mesharialsadoun.prayer_times.widget

import org.json.JSONException
import org.json.JSONObject

// The widgets' data, written by the app (lib/data/widget_payload.dart). Pure
// Kotlin with no Android parts, so it is tested on the computer.

/** The payload format this version reads; any other is ignored. */
const val PAYLOAD_VERSION = 2

/**
 * One time on the widget: a prayer, or sunrise, which is never [counts]ed
 * down to. A [hidden] one is left off the widget but still counted down to.
 */
data class Row(val name: String, val time: String, val at: Long, val counts: Boolean, val hidden: Boolean = false)

/** The Android 12+ widgets' colours (ARGB) for a fixed colour choice. */
data class WidgetColours(val card: Int, val pill: Int, val onPill: Int, val icon: Int)

/** One day in the timetable's own time zone, from [start] until [end], with its two dates. */
data class Day(val start: Long, val end: Long, val date: String, val hijri: String, val rows: List<Row>)

/**
 * Everything the app saved, with the text already in the app's language
 * ([lang]). [calculated] is the mark shown when the times aren't official,
 * and empty when they are. [is24Hour] is null to follow the phone; with
 * [wallpaper] the widget reads the phone's own colours, and [colours] (if
 * any) are a fixed colour's, both Android 12+ only.
 */
data class Payload(
    val rtl: Boolean,
    val lang: String,
    val place: String,
    val calculated: String,
    val openApp: String,
    val days: List<Day>,
    val is24Hour: Boolean? = null,
    val wallpaper: Boolean = false,
    val colours: WidgetColours? = null,
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
            lang = payload.getString("lang"),
            place = payload.getString("place"),
            calculated = payload.getString("calculated"),
            openApp = payload.getString("openApp"),
            days = List(days.length()) { parseDay(days.getJSONObject(it)) },
            // Display choices: each left out by the app when it's the default.
            is24Hour = if (payload.has("is24Hour")) payload.getBoolean("is24Hour") else null,
            wallpaper = payload.optBoolean("wallpaper", false),
            colours = payload.optJSONObject("colours")?.let(::parseColours),
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
        date = day.getString("date"),
        hijri = day.getString("hijri"),
        rows = List(rows.length()) {
            val row = rows.getJSONObject(it)
            Row(
                row.getString("name"),
                row.getString("time"),
                row.getLong("at"),
                row.getBoolean("counts"),
                hidden = row.optBoolean("hidden", false),
            )
        },
    )
}

// The app writes ARGB as unsigned 32-bit numbers, so read them as Long.
private fun parseColours(colours: JSONObject) = WidgetColours(
    card = colours.getLong("card").toInt(),
    pill = colours.getLong("pill").toInt(),
    onPill = colours.getLong("onPill").toInt(),
    icon = colours.getLong("icon").toInt(),
)

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
