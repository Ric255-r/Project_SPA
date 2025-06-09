package com.example.main_resepsionis

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant



class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "id.flutter/background_service/android")
          .setMethodCallHandler { call, result ->
              if (call.method == "start") {
                  result.success("Background service started")
              } else {
                  result.notImplemented()
              }
          }

    }
}
