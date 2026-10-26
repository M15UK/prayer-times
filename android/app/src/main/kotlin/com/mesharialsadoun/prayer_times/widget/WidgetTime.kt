package com.mesharialsadoun.prayer_times.widget

import java.text.DateFormatSymbols
import java.util.Locale

// Pure Kotlin, so it is tested on the computer.

/** A clock time ready to show: its digits and, in 12-hour time, AM or PM (else empty). */
data class ClockText(val digits: String, val suffix: String)

private val HOURS_MINUTES = Regex("""(\d{2}):(\d{2})""")

/**
 * A timetable time ("17:53") as the phone shows times: unchanged in 24-hour
 * time, otherwise "5:53" with "PM" in [locale]'s words. Anything that isn't
 * a valid time is shown as it is.
 */
fun clockText(time: String, is24Hour: Boolean, locale: Locale): ClockText {
    val match = HOURS_MINUTES.matchEntire(time) ?: return ClockText(time, "")
    val hour = match.groupValues[1].toInt()
    if (is24Hour || hour > 23) return ClockText(time, "")
    val amPm = DateFormatSymbols.getInstance(locale).amPmStrings
    val twelveHour = if (hour % 12 == 0) 12 else hour % 12
    return ClockText("$twelveHour:${match.groupValues[2]}", amPm[if (hour < 12) 0 else 1])
}
