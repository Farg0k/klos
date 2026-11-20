package com.example.klos

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

/**
 * Keeps the Flutter process alive while the local HTTP server is running.
 * The server itself lives in Dart; this service only provides the Android
 * foreground-service guarantee and a partial wake lock.
 */
class ServerService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val port = intent?.getIntExtra(EXTRA_PORT, 0) ?: 0
        val channelName = intent?.getStringExtra(EXTRA_CHANNEL_NAME)
            ?: "Локальний сервер"
        val channelDescription = intent?.getStringExtra(EXTRA_CHANNEL_DESCRIPTION)
            ?: "Повідомлення про роботу OPDS-сервера для Kindle"
        val text = intent?.getStringExtra(EXTRA_TEXT)
            ?: if (port > 0) "Сервер працює · порт $port" else "Сервер працює"
        createChannel(channelName, channelDescription)
        startForeground(NOTIFICATION_ID, buildNotification(text))
        acquireWakeLock()
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        releaseWakeLock()
        super.onDestroy()
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val manager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = manager
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "klos:local-server")
            .apply {
                setReferenceCounted(false)
                acquire()
            }
    }

    private fun releaseWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    private fun createChannel(name: String, description: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val channel = NotificationChannel(
            CHANNEL_ID,
            name,
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            this.description = description
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(text: String): Notification {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("klos")
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(getColor(R.color.brand))
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "klos_server"
        private const val NOTIFICATION_ID = 4242
        private const val EXTRA_PORT = "port"
        private const val EXTRA_CHANNEL_NAME = "channelName"
        private const val EXTRA_CHANNEL_DESCRIPTION = "channelDescription"
        private const val EXTRA_TEXT = "text"

        fun start(
            context: Context,
            port: Int,
            channelName: String?,
            channelDescription: String?,
            text: String?,
        ) {
            val intent = Intent(context, ServerService::class.java)
                .putExtra(EXTRA_PORT, port)
                .putExtra(EXTRA_CHANNEL_NAME, channelName)
                .putExtra(EXTRA_CHANNEL_DESCRIPTION, channelDescription)
                .putExtra(EXTRA_TEXT, text)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, ServerService::class.java))
        }
    }
}
