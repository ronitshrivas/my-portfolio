import AVFoundation
import Flutter
import UIKit

// ═══════════════════════════════════════════════════════════════════════════
// ReelsSurfaceViewFactory
//
// Registered under viewType = "reels_surface_view"
// Mirrors Android's ReelsSurfaceViewFactory.
// There should be ONE instance of ReelsSurfaceView in the widget tree.
// ═══════════════════════════════════════════════════════════════════════════

class ReelsSurfaceViewFactory: NSObject, FlutterPlatformViewFactory {

    private let pool: ReelsPlayerPool

    init(pool: ReelsPlayerPool) {
        self.pool = pool
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return ReelsSurfaceView(frame: frame, pool: pool)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// ReelsSurfaceView
//
// The ONE shared display surface.
// Connects to ReelsPlayerPool via attachDisplayLayer / detachDisplayLayer.
// ExoPlayers share this layer; switching which player renders is done
// via switchSurface() → pool.displayLayer.player = players[slot].
//
// Android equivalent: ReelsSurfaceView implements SurfaceHolder.Callback
// iOS equivalent:     AVPlayerLayer hosted inside a UIView
//
// Never remove this from the widget tree — layer destruction causes
// black frames on the next reel (same as Android comment in the Kotlin code).
// ═══════════════════════════════════════════════════════════════════════════

class ReelsSurfaceView: NSObject, FlutterPlatformView {

    private let containerView: ReelsVideoView
    private let pool: ReelsPlayerPool

    init(frame: CGRect, pool: ReelsPlayerPool) {
        self.pool = pool
        self.containerView = ReelsVideoView(frame: frame)
        super.init()

        // Tell the pool about our AVPlayerLayer so it can assign .player
        pool.attachDisplayLayer(containerView.playerLayer)
    }

    // ── FlutterPlatformView ───────────────────────────────────────────────────

    func view() -> UIView {
        return containerView
    }

    func dispose() {
        pool.detachDisplayLayer()
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// ReelsVideoView
//
// A UIView whose backing layer IS an AVPlayerLayer.
// This is the canonical iOS pattern for full-view video rendering.
// Resizing is automatic because the layer fills its parent view.
// ═══════════════════════════════════════════════════════════════════════════

class ReelsVideoView: UIView {

    // Override layerClass so UIView uses AVPlayerLayer as its backing layer.
    // This is more efficient than adding a sublayer because layout is free.
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black

        // Match Android's SurfaceView behavior: video fills the view,
        // letterboxing on aspect ratio mismatch.
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = UIColor.black.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // CALayer doesn't auto-resize with UIView — we must update manually.
        // (Only needed when layerClass is overridden AND frame changes at runtime)
        playerLayer.frame = bounds
    }
}
