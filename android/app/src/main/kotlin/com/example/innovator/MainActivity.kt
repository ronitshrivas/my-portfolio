package com.innovation.innovator
import com.innovation.innovator.reels.ReelsPlayerPlugin
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(ReelsPlayerPlugin())
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            notificationManager.createNotificationChannel(
                NotificationChannel(
                    "chat_messages", "Chat Messages",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Chat message notifications"
                    enableLights(true)
                    enableVibration(true)
                    setShowBadge(true)
                }
            )
            notificationManager.createNotificationChannel(
                NotificationChannel(
                    "general_notifications", "General Notifications",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply { description = "General app notifications" }
            )
        }
    }
}