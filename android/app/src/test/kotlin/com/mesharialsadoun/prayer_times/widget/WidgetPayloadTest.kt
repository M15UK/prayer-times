package com.mesharialsadoun.prayer_times.widget

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Uses the same payload file as the app's Dart test, so the two can't drift. */
class WidgetPayloadTest {
    private val payload = parsePayload(
        File("../../test/unit/data/widget_payload_fixture.json").readText(),
    )!!

    // Moments in milliseconds since 1970 (UTC), as the payload stores them.
    private val lunchtime25th = 1792930140000 // 12:09 on 25 October 2026
    private val asr25th = 1792937820000
    private val midnight26th = 1792972800000
    private val fajr26th = 1792991100000

    @Test
    fun readsTheAppsPayload() {
        assertEquals("London", payload.place)
        assertFalse(payload.rtl)
        assertEquals("en", payload.lang)
        assertEquals("", payload.calculated) // official times: no mark
        assertEquals(2, payload.days.size)
        assertEquals("Sun 25 Oct", payload.days[0].date)
        assertEquals("14 Jum I", payload.days[0].hijri)
        assertEquals(
            listOf("Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"),
            payload.days[0].rows.map { it.name },
        )
    }

    @Test
    fun withNoDisplayChoicesEverythingIsAsTheWidgetsDefault() {
        assertNull(payload.is24Hour) // follow the phone
        assertFalse(payload.wallpaper)
        assertNull(payload.colours)
        assertFalse(payload.days[0].rows.any { it.hidden })
    }

    @Test
    fun readsTheDisplayChoices() {
        val display = parsePayload(
            File("../../test/unit/data/widget_payload_display_fixture.json").readText(),
        )!!

        assertEquals(false, display.is24Hour)
        assertTrue(display.wallpaper)
        assertEquals(listOf("Sunrise"), display.days[0].rows.filter { it.hidden }.map { it.name })
    }

    @Test
    fun readsAFixedColoursWidgetColours() {
        // The app writes colours as unsigned 32-bit numbers, beyond Int.MAX_VALUE.
        val json = File("../../test/unit/data/widget_payload_fixture.json").readText()
            .replaceFirst("\"days\"", "\"colours\": {\"card\": 4278190080, \"pill\": 4294967295, \"onPill\": 4278190335, \"icon\": 4278255360}, \"days\"")

        assertEquals(
            WidgetColours(card = 0xFF000000.toInt(), pill = 0xFFFFFFFF.toInt(), onPill = 0xFF0000FF.toInt(), icon = 0xFF00FF00.toInt()),
            parsePayload(json)!!.colours,
        )
    }

    @Test
    fun atLunchtimeTheNextPrayerIsAsr() {
        val pick = pick(payload, lunchtime25th)!!

        assertEquals(payload.days[0], pick.today)
        assertEquals("Asr", pick.next?.name)
        assertEquals(asr25th, pick.wakeAt)
    }

    @Test
    fun afterIshaTheNextIsTomorrowsFajrButMidnightComesFirst() {
        val pick = pick(payload, 1792958400000)!! // 20:00 on 25 October

        assertEquals(payload.days[0], pick.today)
        assertEquals(fajr26th, pick.next?.at)
        assertEquals(midnight26th, pick.wakeAt)
    }

    @Test
    fun theExtraHourWhenTheClocksGoBackIsStillTheSameDay() {
        // 01:30 GMT, after 01:00–02:00 BST: the 25th has 25 hours.
        val pick = pick(payload, 1792891800000)!!

        assertEquals(payload.days[0], pick.today)
        assertEquals("Fajr", pick.next?.name)
    }

    @Test
    fun sunriseIsShownButNeverCountedDownTo() {
        val pick = pick(payload, 1792905000000)!! // 05:10, after Fajr

        assertEquals("Dhuhr", pick.next?.name)
    }

    @Test
    fun afterIshaOnTheLastDayThereIsNoNextPrayer() {
        val lastDay = payload.days[1]
        val pick = pick(payload, 1793044800000)!! // 20:00 on 26 October

        assertEquals(lastDay, pick.today)
        assertNull(pick.next)
        assertEquals(lastDay.end, pick.wakeAt)
    }

    @Test
    fun outsideTheSavedDaysThereIsNothingToShow() {
        assertNull(pick(payload, 1792882799999)) // just before the first day
        assertNull(pick(payload, 1793059200000)) // the moment the last one ends
    }

    @Test
    fun atTheMomentAPrayerStartsTheNextIsTheOneAfter() {
        assertEquals("Maghrib", pick(payload, asr25th)?.next?.name)
    }

    @Test
    fun atMidnightTheNewDayBegins() {
        assertEquals(payload.days[1], pick(payload, midnight26th)?.today)
    }

    @Test
    fun aMissingDayShowsNothingAndIsSkippedForTheNextPrayer() {
        val dayAfter = payload.days[1].movedBy(DAY_MS)
        val gapped = payload.copy(days = listOf(payload.days[0], dayAfter))

        assertNull(pick(gapped, midnight26th + 3_600_000)) // inside the missing 26th
        assertEquals(fajr26th + DAY_MS, pick(gapped, 1792958400000)?.next?.at) // 20:00 on the 25th
    }

    @Test
    fun theWidgetAlwaysWakesLaterThanNow() {
        // Every 7 minutes across both days: an alarm at or before now would loop.
        for (now in payload.days.first().start until payload.days.last().end step 7 * 60_000L) {
            val pick = pick(payload, now)!!
            assertTrue("wakeAt must be after $now", pick.wakeAt > now)
        }
    }

    @Test
    fun rejectsAnotherVersionOrBrokenText() {
        assertNull(parsePayload("""{"v":1}""")) // saved by the previous version
        assertNull(parsePayload("""{"v":3}"""))
        assertNull(parsePayload("not json"))
        assertNull(parsePayload(null))
    }

    private companion object {
        const val DAY_MS = 24 * 60 * 60 * 1000L

        /** The same day [ms] later, for building a gap between saved days. */
        fun Day.movedBy(ms: Long) = copy(start = start + ms, end = end + ms, rows = rows.map { it.copy(at = it.at + ms) })
    }
}
