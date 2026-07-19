package com.example.my_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.util.SizeF
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
        val category = widgetData.getString("wp_category", null) ?: "CONTINUE STUDYING"
        val title = widgetData.getString("wp_title", null) ?: "Genesis 1"

        for (widgetId in appWidgetIds) {
            // On Android 12+ we hand the launcher several layouts keyed by size
            // so the widget reshapes itself as the user resizes it: a compact
            // text card when small, the card + spine stack at medium, and a
            // taller version with a tagline when large.
            val remoteViews = if (Build.VERSION.SDK_INT >= 31) {
                RemoteViews(
                    mapOf(
                        // Tiny & short: text-only, no room for books.
                        SizeF(120f, 100f) to
                            buildViews(context, widgetId, R.layout.wp_widget_small, false, category, title),
                        // Narrow but tall: portrait layout that keeps the book stack.
                        SizeF(120f, 160f) to
                            buildViews(context, widgetId, R.layout.wp_widget_tall, true, category, title),
                        // Wide & short: the classic card + stack.
                        SizeF(240f, 110f) to
                            buildViews(context, widgetId, R.layout.wp_widget, true, category, title),
                        // Wide & tall: card + stack + tagline.
                        SizeF(240f, 190f) to
                            buildViews(context, widgetId, R.layout.wp_widget_large, true, category, title),
                    ),
                )
            } else {
                buildViews(context, widgetId, R.layout.wp_widget, true, category, title)
            }

            appWidgetManager.updateAppWidget(widgetId, remoteViews)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.wp_stack)
        }
    }

    /** Builds one size variant, wiring text, taps and (optionally) the stack. */
    private fun buildViews(
        context: Context,
        widgetId: Int,
        layoutId: Int,
        withStack: Boolean,
        category: String,
        title: String,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, layoutId)
        views.setTextViewText(R.id.wp_category, category)
        views.setTextViewText(R.id.wp_title, title)

        // Whole-widget tap → open the app and continue reading.
        val launchIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("wordpath://continue"),
        )
        views.setOnClickPendingIntent(R.id.wp_root, launchIntent)

        if (withStack) {
            // Feed the flipping stack of spines from a RemoteViewsService.
            val serviceIntent = Intent(context, WordPathStackService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                // Unique per widget so the adapter is not reused stale.
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.wp_stack, serviceIntent)
            views.setEmptyView(R.id.wp_stack, R.id.wp_stack_empty)

            // Tapping a spine also continues reading. Collection items need a
            // (mutable) template + per-item fill-in intent.
            var templateFlags = PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= 31) {
                templateFlags = templateFlags or PendingIntent.FLAG_MUTABLE
            }
            val templateIntent = Intent(context, MainActivity::class.java).apply {
                action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
            }
            val template = PendingIntent.getActivity(context, 1, templateIntent, templateFlags)
            views.setPendingIntentTemplate(R.id.wp_stack, template)
        }
        return views
    }
}
