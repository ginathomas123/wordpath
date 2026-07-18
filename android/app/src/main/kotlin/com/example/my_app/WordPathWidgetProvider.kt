package com.example.my_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget for WordPath. The left side shows a "Continue reading"
 * summary driven by data pushed from Flutter (via home_widget); the right side
 * is a [android.widget.StackView] of leather book spines that flip through with
 * Android's built-in 3D card animation — the closest thing a RemoteViews widget
 * can offer to the in-app shelf. Tapping anywhere opens the app to the last
 * chapter the reader was on.
 */
class WordPathWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.wp_widget)

            val category = widgetData.getString("wp_category", null) ?: "CONTINUE READING"
            val title = widgetData.getString("wp_title", null) ?: "Genesis 1"
            views.setTextViewText(R.id.wp_category, category)
            views.setTextViewText(R.id.wp_title, title)

            // Feed the flipping stack of spines from a RemoteViewsService.
            val serviceIntent = Intent(context, WordPathStackService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                // Make the intent unique per widget so the adapter is not reused stale.
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.wp_stack, serviceIntent)
            views.setEmptyView(R.id.wp_stack, R.id.wp_stack_empty)

            // Whole-widget tap → open the app and continue reading.
            val launchIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("wordpath://continue"),
            )
            views.setOnClickPendingIntent(R.id.wp_root, launchIntent)

            // Tapping a spine in the stack also continues reading. Collection
            // items need a (mutable) template + per-item fill-in intent.
            var templateFlags = PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= 31) {
                templateFlags = templateFlags or PendingIntent.FLAG_MUTABLE
            }
            val templateIntent = Intent(context, MainActivity::class.java).apply {
                action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
            }
            val template = PendingIntent.getActivity(context, 1, templateIntent, templateFlags)
            views.setPendingIntentTemplate(R.id.wp_stack, template)

            appWidgetManager.updateAppWidget(widgetId, views)
            // Ask the stack to (re)load its items — animates them into view.
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.wp_stack)
        }
    }
}
