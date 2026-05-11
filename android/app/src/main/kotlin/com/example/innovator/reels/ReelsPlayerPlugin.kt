package com.innovation.innovator.reels

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMessageCodec

/**
 * Bridges Flutter MethodChannel "reels_player" <-> ReelsPlayerPool.
 * No fallbackUrl handling needed here — setEnableDecoderFallback(true)
 * in the pool handles all codec issues transparently.
 */
class ReelsPlayerPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var pool: ReelsPlayerPool
    private val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pool    = ReelsPlayerPool(binding.applicationContext)
        channel = MethodChannel(binding.binaryMessenger, "reels_player")
        channel.setMethodCallHandler(this)
        binding.platformViewRegistry.registerViewFactory(
            "reels_surface_view",
            ReelsSurfaceViewFactory(pool, StandardMessageCodec.INSTANCE)
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pool.releaseAll()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {

            "prepare" -> {
                val slot  = call.argument<Int>("slot")    ?: return result.error("ARG","slot missing",null)
                val url   = call.argument<String>("url")  ?: return result.error("ARG","url missing",null)
                val token = call.argument<String>("token") ?: ""
                pool.prepare(slot, url, token)
                result.success(null)
            }

            "switchSurface" -> {
                val slot = call.argument<Int>("slot") ?: return result.error("ARG","slot missing",null)
                pool.switchSurface(slot)
                result.success(null)
            }

            "play" -> {
                val slot = call.argument<Int>("slot") ?: return result.error("ARG","slot missing",null)
                pool.play(slot)
                result.success(null)
            }

            "pause" -> {
                val slot = call.argument<Int>("slot") ?: return result.error("ARG","slot missing",null)
                pool.pause(slot)
                result.success(null)
            }

            "setVolume" -> {
                val slot   = call.argument<Int>("slot")          ?: return result.error("ARG","slot missing",null)
                val volume = call.argument<Double>("volume")?.toFloat() ?: 1f
                pool.setVolume(slot, volume)
                result.success(null)
            }

            "seekTo" -> {
                val slot  = call.argument<Int>("slot")      ?: return result.error("ARG","slot missing",null)
                val posMs = call.argument<Int>("positionMs")?.toLong() ?: 0L
                pool.seekTo(slot, posMs)
                result.success(null)
            }

            "release" -> {
                val slot = call.argument<Int>("slot") ?: return result.error("ARG","slot missing",null)
                pool.release(slot)
                result.success(null)
            }

            "onFirstFrame" -> {
                val slot = call.argument<Int>("slot") ?: return result.error("ARG","slot missing",null)
                pool.setOnFirstFrameListener(slot) {
                    mainHandler.post { channel.invokeMethod("firstFrameReady", mapOf("slot" to slot)) }
                }
                result.success(null)
            }

            "releaseAll" -> { pool.releaseAll(); result.success(null) }

            else -> result.notImplemented()
        }
    }
}