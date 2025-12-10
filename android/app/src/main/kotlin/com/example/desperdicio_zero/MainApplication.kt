package com.example.desperdicio_zero

import androidx.multidex.MultiDexApplication
import com.google.firebase.FirebaseApp

class MainApplication : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
    }
}
