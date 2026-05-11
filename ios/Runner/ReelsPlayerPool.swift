import AVFoundation
import Flutter

// ═══════════════════════════════════════════════════════════════════════════
// ReelsPlayerPool — iOS AVPlayer mirror of the Android ExoPlayer pool.
//
// ARCHITECTURE: 3-slot pool, 1 shared CALayer display surface
//
//   slot 0  previous reel  (buffering, no layer attached)
//   slot 1  current reel   (has layer, playing)
//   slot 2  next reel      (buffering, no layer attached)
//
// On swipe:
//   pause(oldSlot) -> switchSurface(newSlot) -> play(newSlot) -> prepare(recycled)
//
// AVPlayer notes vs ExoPlayer:
//   • AVPlayer has no surface — it renders via AVPlayerLayer (a CALayer subclass)
//   • "switchSurface" = swap which player is the displayLayer's .player
//   • Buffering without a layer works natively (AVPlayer prerolls in background)
//   • HLS is natively supported by AVPlayer, no extra source needed
//   • repeatMode ONE = NotificationCenter observer for AVPlayerItemDidPlayToEndTime
// ═══════════════════════════════════════════════════════════════════════════

class ReelsPlayerPool: NSObject {

    // ── Shared channel for firstFrameReady callbacks ──────────────────────────
    var methodChannel: FlutterMethodChannel?

    // ── Slot state ────────────────────────────────────────────────────────────
    private var players   = [Int: AVPlayer]()      // slot -> AVPlayer
    private var urls      = [Int: String]()        // slot -> url
    private var loopObservers = [Int: NSObjectProtocol]() // slot -> loop observer

    // ── Display ───────────────────────────────────────────────────────────────
    /// The ONE AVPlayerLayer that shows on screen.
    /// Owned by ReelsSurfaceView; we swap its .player to switch slots.
    private weak var displayLayer: AVPlayerLayer?
    private var displaySlot: Int = -1

    // ── KVO for firstFrame ────────────────────────────────────────────────────
    private var firstFrameObservers = [Int: NSKeyValueObservation]()

    deinit {
        releaseAll()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Public API  (all called from main thread via MethodChannel)
    // ─────────────────────────────────────────────────────────────────────────

    /// Load [url] into [slot] and start buffering (no display layer required).
    func prepare(slot: Int, url: String, token: String) {
        guard (0...2).contains(slot) else { return }

        // Skip if same URL already loaded
        if urls[slot] == url, players[slot] != nil { return }

        releaseSlot(slot)
        urls[slot] = url

        let player = buildPlayer(url: url, token: token)
        players[slot] = player

        // If this slot is already the display slot, attach it immediately
        if slot == displaySlot, let layer = displayLayer {
            layer.player = player
        }

        // Loop: restart when item reaches end
        let loopObs = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
        loopObservers[slot] = loopObs
    }

    /// Move the shared display layer to [slot].
    /// Call before play() when changing reels.
    func switchSurface(toSlot: Int) {
        guard (0...2).contains(toSlot) else { return }

        // Detach current display player
        if displaySlot != toSlot, displaySlot >= 0 {
            // No-op: we just reassign displayLayer.player below.
            // The old player keeps buffering in background — that's intentional.
        }

        displaySlot = toSlot
        if let layer = displayLayer, let player = players[toSlot] {
            layer.player = player
        }
    }

    func play(slot: Int) {
        guard (0...2).contains(slot) else { return }
        players[slot]?.play()
    }

    func pause(slot: Int) {
        guard (0...2).contains(slot) else { return }
        players[slot]?.pause()
    }

    func setVolume(slot: Int, volume: Float) {
        guard (0...2).contains(slot) else { return }
        players[slot]?.volume = max(0, min(1, volume))
    }

    func seekTo(slot: Int, positionMs: Int) {
        guard (0...2).contains(slot) else { return }
        let time = CMTime(value: CMTimeValue(positionMs), timescale: 1000)
        players[slot]?.seek(to: time)
    }

    func release(slot: Int) {
        guard (0...2).contains(slot) else { return }
        releaseSlot(slot)
    }

    func releaseAll() {
        for i in 0...2 { releaseSlot(i) }
        displayLayer?.player = nil
        displaySlot = -1
    }

    /// Register a one-shot callback fired when [slot] renders its first frame.
    func setOnFirstFrameListener(slot: Int) {
        guard (0...2).contains(slot), let player = players[slot] else { return }

        // Cancel any existing observer for this slot
        firstFrameObservers[slot]?.invalidate()

        // Observe readyToPlay status — this fires when the first frame is decoded
        let obs = player.currentItem?.observe(
            \.status,
            options: [.new]
        ) { [weak self] item, _ in
            guard let self = self else { return }
            if item.status == .readyToPlay {
                self.firstFrameObservers[slot]?.invalidate()
                self.firstFrameObservers.removeValue(forKey: slot)
                DispatchQueue.main.async {
                    self.methodChannel?.invokeMethod(
                        "firstFrameReady",
                        arguments: ["slot": slot]
                    )
                }
            }
        }
        if let obs = obs {
            firstFrameObservers[slot] = obs
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Surface lifecycle (called by ReelsSurfaceView)
    // ─────────────────────────────────────────────────────────────────────────

    func attachDisplayLayer(_ layer: AVPlayerLayer) {
        displayLayer = layer
        let slot = displaySlot >= 0 ? displaySlot : 0
        displaySlot = slot
        layer.player = players[slot]
    }

    func detachDisplayLayer() {
        displayLayer?.player = nil
        displayLayer = nil
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Private
    // ─────────────────────────────────────────────────────────────────────────

    private func releaseSlot(_ slot: Int) {
        // Remove first-frame observer
        firstFrameObservers[slot]?.invalidate()
        firstFrameObservers.removeValue(forKey: slot)

        // Remove loop observer
        if let obs = loopObservers[slot] {
            NotificationCenter.default.removeObserver(obs)
            loopObservers.removeValue(forKey: slot)
        }

        // Detach from display if this was the display slot
        if slot == displaySlot {
            displayLayer?.player = nil
        }

        // Pause and release
        players[slot]?.pause()
        players[slot]?.replaceCurrentItem(with: nil)
        players[slot] = nil
        urls[slot] = nil
    }

    private func buildPlayer(url: String, token: String) -> AVPlayer {
        var asset: AVURLAsset

        if token.isEmpty {
            asset = AVURLAsset(url: URL(string: url)!)
        } else {
            // Inject Authorization header — mirrors Android's DefaultHttpDataSource token
            let headers = ["Authorization": "Bearer \(token)"]
            asset = AVURLAsset(
                url: URL(string: url)!,
                options: ["AVURLAssetHTTPHeaderFieldsKey": headers]
            )
        }

        // ── Preroll: buffer aggressively like Android's 3s/30s LoadControl ───
        // AVPlayer automatically buffers. We hint to prefer forward buffering.
        let item = AVPlayerItem(asset: asset)

        // Prefer forward buffer of ~30s to match Android LoadControl.
        // AVPlayer will buffer as much as memory allows by default;
        // preferredForwardBufferDuration nudges the heuristic.
        item.preferredForwardBufferDuration = 30.0

        // Use the auto-stall heuristic (equivalent to Android's adaptive track selector)
        item.preferredPeakBitRate = 0 // adaptive

        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = true
        player.volume = 1.0

        // Do NOT set a rate/play yet — just buffer like Android's prepare()
        // with playWhenReady = false.

        return player
    }
}
