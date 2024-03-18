package io.ente.photos

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.BitmapDrawable
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class SlideshowWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
            widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views =
                    RemoteViews(context.packageName, R.layout.slideshow_layout).apply {
                        // Open App on Widget Click
                        val pendingIntent =
                                HomeWidgetLaunchIntent.getActivity(
                                        context,
                                        MainActivity::class.java
                                )
                        setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                        // Show Images saved with `renderFlutterWidget`
                        val imagePath = widgetData.getString("slideshow", null)
                        var imageExists: Boolean = false
                        if (imagePath != null) {
                            val imageFile = File(imagePath)
                            imageExists = imageFile.exists()
                        }
                        if (imageExists) {
                            Log.d("SlideshowWidgetProvider", "Image exists: $imagePath")
                            setViewVisibility(R.id.widget_img, View.VISIBLE)
                            setViewVisibility(R.id.widget_placeholder, View.GONE)

                            val bitmap: Bitmap = BitmapFactory.decodeFile(imagePath)
                            setImageViewBitmap(R.id.widget_img, bitmap)
                        } else {
                            Log.d("SlideshowWidgetProvider", "Image doesn't exists")
                            setViewVisibility(R.id.widget_img, View.GONE)
                            setViewVisibility(R.id.widget_placeholder, View.VISIBLE)

                            val drawable =
                                    ContextCompat.getDrawable(
                                            context,
                                            R.drawable.ic_home_widget_default
                                    )
                            val bitmap = (drawable as BitmapDrawable).bitmap
                            setImageViewBitmap(R.id.widget_placeholder, bitmap)
                        }
                    }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
