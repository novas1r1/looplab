package com.repeatlab.app

import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Flutter plugin for Rubber Band audio processing.
 * Provides pitch-preserving time-stretching capabilities.
 */
class RubberBandPlugin : FlutterPlugin, MethodCallHandler {
    
    companion object {
        private const val TAG = "RubberBandPlugin"
        private const val CHANNEL_NAME = "com.repeatlab.rubberband"
        
        init {
            try {
                System.loadLibrary("rubberband_flutter")
                Log.i(TAG, "Native library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Failed to load native library: ${e.message}")
            }
        }
    }
    
    private lateinit var channel: MethodChannel
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    
    // Native methods - implemented in rubberband_jni.cpp
    private external fun processFile(
        inputPath: String,
        outputPath: String,
        speed: Double,
        pitch: Double
    ): String
    
    private external fun getVersion(): String
    
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        Log.i(TAG, "RubberBandPlugin attached to engine")
    }
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        Log.i(TAG, "RubberBandPlugin detached from engine")
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "processFile" -> handleProcessFile(call, result)
            "getVersion" -> handleGetVersion(result)
            else -> result.notImplemented()
        }
    }
    
    private fun handleProcessFile(call: MethodCall, result: Result) {
        val inputPath = call.argument<String>("inputPath")
        val outputPath = call.argument<String>("outputPath")
        val speed = call.argument<Double>("speed")
        val pitch = call.argument<Double>("pitch") ?: 1.0
        
        if (inputPath == null || outputPath == null || speed == null) {
            result.error(
                "INVALID_ARGUMENTS",
                "Missing required arguments: inputPath, outputPath, speed",
                null
            )
            return
        }
        
        Log.i(TAG, "processFile: $inputPath -> $outputPath (speed=$speed, pitch=$pitch)")
        
        // Process on IO thread to avoid blocking UI
        scope.launch {
            try {
                val outputResult = withContext(Dispatchers.IO) {
                    processFile(inputPath, outputPath, speed, pitch)
                }
                
                if (outputResult.isNotEmpty()) {
                    Log.i(TAG, "Processing completed: $outputResult")
                    result.success(outputResult)
                } else {
                    Log.e(TAG, "Processing failed - empty result")
                    result.error(
                        "PROCESSING_FAILED",
                        "Failed to process audio file",
                        null
                    )
                }
            } catch (e: Exception) {
                Log.e(TAG, "Processing error: ${e.message}", e)
                result.error(
                    "PROCESSING_ERROR",
                    e.message ?: "Unknown error during audio processing",
                    e.stackTraceToString()
                )
            }
        }
    }
    
    private fun handleGetVersion(result: Result) {
        try {
            val version = getVersion()
            result.success(version)
        } catch (e: Exception) {
            result.error("VERSION_ERROR", e.message, null)
        }
    }
}

