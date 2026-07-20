package com.kurandakimesaj.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Ezan saati ana ekran widget'ı. home_widget paylaşılan deposundan okur;
/// tıklama uygulamayı homeWidget://prayer ile açar (deep-link → /prayer).
class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.prayer_widget).apply {
                setTextViewText(R.id.tv_hijri, widgetData.getString("hijri_date", "") ?: "")
                setTextViewText(R.id.tv_next_name, widgetData.getString("prayer_next_name", "—") ?: "—")
                setTextViewText(R.id.tv_next_time, widgetData.getString("prayer_next_time", "--:--") ?: "--:--")
                setTextViewText(R.id.tv_location, widgetData.getString("prayer_location", "") ?: "")

                val intent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("homeWidget://prayer"),
                )
                setOnClickPendingIntent(R.id.widget_root, intent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
