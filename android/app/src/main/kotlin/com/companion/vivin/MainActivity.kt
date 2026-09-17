package com.companion.vivin

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() 
{
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent screenshot capture, screen recording, and task switcher preview across the entire app
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
