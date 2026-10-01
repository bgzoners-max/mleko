package com.mleko.mleko

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build

class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)

            val orders = NotificationChannel(
                "orders_high_v2",
                "Porudžbine",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikacije za porudžbine"
                enableVibration(true)
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }

            val urgent = NotificationChannel(
                "mleko_urgent_v2",
                "Hitno",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Hitne notifikacije"
                enableVibration(true)
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }

            nm.createNotificationChannel(orders)
            nm.createNotificationChannel(urgent)

            // Ukloni zastarele v1 kanale ako postoje (migracija na v2).
            // Bez ovoga korisnici koji su instalirali stariju verziju
            // zadržavaju duplirane kanale u sistemskim podešavanjima.
            nm.deleteNotificationChannel("orders_high_v1")
            nm.deleteNotificationChannel("mleko_urgent_v1")
        }
    }
}
