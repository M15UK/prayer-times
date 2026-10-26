package com.mesharialsadoun.prayer_times.widget

import android.appwidget.AppWidgetProvider
import com.mesharialsadoun.prayer_times.R

/**
 * One widget style: its provider (named in the manifest), its layout, and
 * how its countdown reads. The styles differ only in layout; one renderer
 * fills them all (WidgetViews.kt).
 */
class WidgetStyle(
    val provider: Class<out AppWidgetProvider>,
    val layout: Int,
    val countdownFormat: String = "%s",
    /** The next prayer sits on the light pill, so its text takes the pill's text colour. */
    val nextOnPill: Boolean = false,
)

/** Every style, in the widget picker's order. */
val WIDGET_STYLES = listOf(
    WidgetStyle(MiniWidget::class.java, R.layout.widget_mini),
    WidgetStyle(DateLocationWidget::class.java, R.layout.widget_date_location, nextOnPill = true),
    WidgetStyle(PrayerStripWidget::class.java, R.layout.widget_strip),
    WidgetStyle(FullHorizontalWidget::class.java, R.layout.widget_full_horizontal),
    WidgetStyle(DigitalClockWidget::class.java, R.layout.widget_digital_clock, countdownFormat = "(%s)"),
    WidgetStyle(FullVerticalWidget::class.java, R.layout.widget_full_vertical),
)
