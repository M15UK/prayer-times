package com.mesharialsadoun.prayer_times.widget

import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetTimeTest {
    private val english = Locale.ENGLISH
    private val arabic = Locale.forLanguageTag("ar")

    @Test
    fun twentyFourHourTimeIsShownAsTheTimetableGivesIt() {
        assertEquals(ClockText("17:53", ""), clockText("17:53", is24Hour = true, english))
    }

    @Test
    fun twelveHourTimeSplitsOffAmOrPm() {
        assertEquals(ClockText("5:53", "PM"), clockText("17:53", is24Hour = false, english))
        assertEquals(ClockText("5:04", "AM"), clockText("05:04", is24Hour = false, english))
    }

    @Test
    fun midnightAndNoonAreTwelve() {
        assertEquals(ClockText("12:05", "AM"), clockText("00:05", is24Hour = false, english))
        assertEquals(ClockText("12:30", "PM"), clockText("12:30", is24Hour = false, english))
    }

    @Test
    fun amAndPmAreInTheAppsLanguage() {
        assertEquals(ClockText("5:53", "م"), clockText("17:53", is24Hour = false, arabic))
        assertEquals(ClockText("5:04", "ص"), clockText("05:04", is24Hour = false, arabic))
    }

    @Test
    fun anythingElseIsShownAsItIs() {
        assertEquals(ClockText("soon", ""), clockText("soon", is24Hour = false, english))
        assertEquals(ClockText("25:00", ""), clockText("25:00", is24Hour = false, english))
    }
}
