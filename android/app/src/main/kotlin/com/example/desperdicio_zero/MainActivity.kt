package com.example.desperdicio_zero

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    // Handle configuration of Flutter engine
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Plugin configuration if needed
    }
    
    // Handle new intents when the app is already open
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    // Handle the initial intent when the app is launched
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }
    
    // Process the received intent
    private fun handleIntent(intent: Intent?) {
        intent?.data?.let { uri ->
            if (uri.scheme == "com.example.desperdicio_zero") {
                // The Flutter deep linking plugins will handle this
                // This ensures the link is processed even if the app is already open
                intent.data?.let { data ->
                    // This will trigger the deep link handling in Flutter
                    // No need to manually call platformChannelHandler
                }
            }
        }
    }
}
