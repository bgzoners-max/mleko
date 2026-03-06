package com.mleko.mleko

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)

            val orders = NotificationChannel(
                "orders_high",
                "Porudžbine",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikacije za porudžbine"
                enableVibration(true)
            }

            val urgent = NotificationChannel(
                "mleko_urgent",
                "Hitno",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Hitne notifikacije"
                enableVibration(true)
            }

            nm.createNotificationChannel(orders)
            nm.createNotificationChannel(urgent)
        }
    }
}
