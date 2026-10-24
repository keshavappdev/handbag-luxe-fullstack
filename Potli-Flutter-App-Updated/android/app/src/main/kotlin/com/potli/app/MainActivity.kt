package com.potli.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.potli.app/product_share")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareProduct" -> ProductShareHandler.share(this, call, result)
                    else -> result.notImplemented()
                }
            }
    }
}
