package com.example.gym_connect_app

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.example.gym_connect_app/health_settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "openHealthConnectSettings") {
                try {
                    val intent = if (Build.VERSION.SDK_INT >= 34) {
                        Intent("androidx.health.connect.action.MANAGE_HEALTH_PERMISSIONS").apply {
                            putExtra("android.intent.extra.PACKAGE_NAME", packageName)
                        }
                    } else {
                        Intent("androidx.health.connect.action.HEALTH_CONNECT_SETTINGS")
                    }
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    try {
                        val fallbackIntent = Intent("androidx.health.connect.action.HEALTH_CONNECT_SETTINGS").apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(fallbackIntent)
                        result.success(true)
                    } catch (e2: Exception) {
                        result.error("UNAVAILABLE", e2.message, null)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
