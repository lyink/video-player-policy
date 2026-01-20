package com.lyinkjr.videodownloader

import android.content.Intent
import android.net.Uri
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.lyinkjr.videodownloader/intent"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialIntent" -> {
                    val intentData = getIntentData(intent)
                    result.success(intentData)
                }
                else -> result.notImplemented()
            }
        }
    }


    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        // Notify Flutter about the new intent
        val intentData = getIntentData(intent)
        if (intentData != null) {
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                .invokeMethod("onNewIntent", intentData)
        }
    }

    private fun getIntentData(intent: Intent): Map<String, String>? {
        if (intent.action == Intent.ACTION_VIEW && intent.data != null) {
            val uri = intent.data!!
            val path = when (uri.scheme) {
                "file" -> uri.path
                "content" -> uri.toString()
                else -> uri.toString()
            }

            return mapOf(
                "action" to intent.action!!,
                "uri" to uri.toString(),
                "path" to (path ?: ""),
                "type" to (intent.type ?: "")
            )
        }
        return null
    }
}
