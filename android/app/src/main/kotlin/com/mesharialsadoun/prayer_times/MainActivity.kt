package com.mesharialsadoun.prayer_times

import com.mesharialsadoun.prayer_times.widget.refreshWidgets
import com.mesharialsadoun.prayer_times.widget.storePayload
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The app hands the home-screen widgets their times here
        // (lib/data/widget_channel.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                val json = call.arguments as? String
                when {
                    call.method != "publish" -> result.notImplemented()
                    json == null -> result.error("bad_payload", "The widget times must be text", null)
                    else -> {
                        storePayload(this, json)
                        refreshWidgets(this)
                        result.success(null)
                    }
                }
            }
    }

    private companion object {
        const val WIDGET_CHANNEL = "com.mesharialsadoun.prayer_times/widgets"
    }
}
