package com.mesharialsadoun.prayer_times.widget

import android.content.Context
import android.content.res.ColorStateList
import android.os.Build
import android.widget.RemoteViews

/**
 * The colours to paint the widgets, or null for the layouts' own teal: on
 * Android 7–11 (which can't recolour a widget's shapes), or when teal is
 * chosen. Wallpaper colours come from the phone's own palette, so they
 * follow a new wallpaper at the next redraw, without the app.
 */
fun widgetPalette(context: Context, payload: Payload): WidgetColours? = when {
    Build.VERSION.SDK_INT < Build.VERSION_CODES.S -> null
    // The same lightness steps as the app's fixed colours: a very dark card,
    // a very light pill and soft icons (lib/data/app_colour.dart).
    payload.wallpaper -> WidgetColours(
        card = context.getColor(android.R.color.system_accent1_900),
        pill = context.getColor(android.R.color.system_accent1_100),
        onPill = context.getColor(android.R.color.system_accent1_900),
        icon = context.getColor(android.R.color.system_accent1_200),
    )
    else -> payload.colours
}

/**
 * Tints [viewId]'s background shape with [colour], keeping its rounded
 * corners and see-through edge; null clears an earlier tint (an update is
 * applied on top of the old widget). Android 12+ only; does nothing before.
 */
fun RemoteViews.tintBackground(viewId: Int, colour: Int?) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
    setColorStateList(viewId, "setBackgroundTintList", colour?.let(ColorStateList::valueOf))
}
