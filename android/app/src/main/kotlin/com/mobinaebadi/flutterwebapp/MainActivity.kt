package com.mobinaebadi.flutterwebapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.os.Build
import android.view.View
import android.view.WindowInsetsController

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Full transparent system bars on Android
        if (Build.VERSION.SDK_INT >= Build.VERSION_10) {
            window.setDecorFitsSystemWindows(false)
            window.navigationBarColor = 0
        }
    }
}
