package com.example.my_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.TypedValue
import android.widget.RemoteViews
import android.widget.RemoteViewsService

/** Supplies the leather book spines shown in the widget's flipping StackView. */
class WordPathStackService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        WordPathStackFactory(applicationContext)
}

private class WordPathStackFactory(
    private val context: Context,
) : RemoteViewsService.RemoteViewsFactory {

    private data class Spine(val title: String, val image: Int)

    private val spines = listOf(
        Spine("Genesis", R.drawable.wp_spine_1),
        Spine("Exodus", R.drawable.wp_spine_2),
        Spine("Leviticus", R.drawable.wp_spine_3),
        Spine("Matthew", R.drawable.wp_spine_4),
        Spine("Romans", R.drawable.wp_spine_5),
    )

    override fun onCreate() {}

    override fun onDataSetChanged() {}

    override fun onDestroy() {}

    override fun getCount(): Int = spines.size

    override fun getViewAt(position: Int): RemoteViews {
        val spine = spines[position]
        return RemoteViews(context.packageName, R.layout.wp_widget_item).apply {
            setImageViewResource(R.id.wp_item_image, spine.image)
            setTextViewText(R.id.wp_item_title, spine.title)
            // Round the leather card's corners. Clipping a RemoteViews bitmap
            // needs the outline API (S+); older devices simply stay square.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                setViewOutlinePreferredRadius(
                    R.id.wp_item_root,
                    6f,
                    TypedValue.COMPLEX_UNIT_DIP,
                )
            }
            val fillIn = Intent().apply { data = Uri.parse("wordpath://continue") }
            setOnClickFillInIntent(R.id.wp_item_root, fillIn)
        }
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
