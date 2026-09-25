package com.example.eventease_new

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import java.util.concurrent.TimeUnit

/**
 * EventCountdownWidget
 *
 * Android home-screen AppWidget that reads the next upcoming event from
 * SharedPreferences (written by the Flutter [home_widget] package) and
 * displays a live countdown in Days / Hours / Minutes.
 *
 * SharedPreferences keys (set from Flutter via home_widget):
 *   - "event_title"   : String  — display name of the event
 *   - "event_time_ms" : Long    — event start time in epoch milliseconds
 */
class EventCountdownWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {

        /** SharedPreferences file name used by home_widget Flutter package */
        private const val PREFS_NAME = "FlutterSharedPreferences"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            // home_widget prefixes all keys with "flutter."
            val title = prefs.getString("flutter.event_title", null)
            val eventTimeMs = prefs.getLong("flutter.event_time_ms", -1L)

            val views = RemoteViews(context.packageName, R.layout.event_countdown_widget)

            if (title == null || eventTimeMs == -1L) {
                // No event stored yet
                views.setTextViewText(R.id.widget_event_title, context.getString(R.string.widget_no_event))
                views.setTextViewText(R.id.widget_days, "--")
                views.setTextViewText(R.id.widget_hours, "--")
                views.setTextViewText(R.id.widget_minutes, "--")
            } else {
                val nowMs = System.currentTimeMillis()
                val diffMs = eventTimeMs - nowMs

                if (diffMs <= 0) {
                    // Event has started or passed
                    views.setTextViewText(R.id.widget_event_title, title)
                    views.setTextViewText(R.id.widget_days, "🎉")
                    views.setTextViewText(R.id.widget_hours, "00")
                    views.setTextViewText(R.id.widget_minutes, "00")
                } else {
                    val days = TimeUnit.MILLISECONDS.toDays(diffMs)
                    val hours = TimeUnit.MILLISECONDS.toHours(diffMs) % 24
                    val minutes = TimeUnit.MILLISECONDS.toMinutes(diffMs) % 60

                    views.setTextViewText(R.id.widget_event_title, title)
                    views.setTextViewText(
                        R.id.widget_days,
                        days.toString().padStart(2, '0')
                    )
                    views.setTextViewText(
                        R.id.widget_hours,
                        hours.toString().padStart(2, '0')
                    )
                    views.setTextViewText(
                        R.id.widget_minutes,
                        minutes.toString().padStart(2, '0')
                    )
                }
            }

            // Tap on widget opens the app
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("navigate_to", "event_countdown")
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
