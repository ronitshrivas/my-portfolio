package com.innovation.innovator.reels

import android.content.Context
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * ReelsSurfaceViewFactory — creates the ONE shared display SurfaceView.
 * No slot parameter is needed since there is only one surface.
 */
class ReelsSurfaceViewFactory(
    private val pool: ReelsPlayerPool,
    codec: MessageCodec<Any?>
) : PlatformViewFactory(codec) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return ReelsSurfaceView(context, pool)
    }
}