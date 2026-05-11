package com.innovation.innovator.reels

import android.content.Context
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import io.flutter.plugin.platform.PlatformView

/**
 * ReelsSurfaceView — the SINGLE shared display surface.
 *
 * There is now only ONE of these in the entire app.
 * It connects to ReelsPlayerPool via attachDisplaySurface / detachDisplaySurface.
 * ExoPlayers share this surface; switching which player renders is done via switchSurface().
 */
class ReelsSurfaceView(
    context: Context,
    private val pool: ReelsPlayerPool
) : PlatformView, SurfaceHolder.Callback {

    private val surfaceView = SurfaceView(context).apply {
        holder.addCallback(this@ReelsSurfaceView)
    }

    // ── PlatformView ─────────────────────────────────────────────────────────

    override fun getView(): View = surfaceView

    override fun dispose() {
        pool.detachDisplaySurface()
        surfaceView.holder.removeCallback(this)
    }

    // ── SurfaceHolder.Callback ───────────────────────────────────────────────

    override fun surfaceCreated(holder: SurfaceHolder) {
        pool.attachDisplaySurface(holder.surface)
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        // ExoPlayer adapts internally
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        pool.detachDisplaySurface()
    }
}