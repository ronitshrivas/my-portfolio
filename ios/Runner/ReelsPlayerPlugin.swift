import Flutter
import AVFoundation

// ═══════════════════════════════════════════════════════════════════════════
// ReelsPlayerPlugin
//
// Bridges Flutter MethodChannel "reels_player" <-> ReelsPlayerPool.
// Mirrors Android's ReelsPlayerPlugin exactly — same method names,
// same argument keys, same error codes.
//
// Registration: called from AppDelegate BEFORE GeneratedPluginRegistrant.
// ═══════════════════════════════════════════════════════════════════════════

class ReelsPlayerPlugin: NSObject {

    static let channelName = "reels_player"

    private let pool: ReelsPlayerPool
    private var channel: FlutterMethodChannel!

    init(pool: ReelsPlayerPool, messenger: FlutterBinaryMessenger) {
        self.pool = pool
        super.init()

        channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler(handle)

        // Give the pool a reference so it can call firstFrameReady back to Dart
        pool.methodChannel = channel
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Method call handler
    // ─────────────────────────────────────────────────────────────────────────

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // All calls are already on the main thread (Flutter platform channel guarantee)
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {

        case "prepare":
            guard let slot = args["slot"] as? Int else {
                return result(FlutterError(code: "ARG", message: "slot missing", details: nil))
            }
            guard let url = args["url"] as? String else {
                return result(FlutterError(code: "ARG", message: "url missing", details: nil))
            }
            let token = args["token"] as? String ?? ""
            pool.prepare(slot: slot, url: url, token: token)
            result(nil)

        case "switchSurface":
            guard let slot = args["slot"] as? Int else {
                return result(FlutterError(code: "ARG", message: "slot missing", details: nil))
            }
            pool.switchSurface(toSlot: slot)
            result(nil)

        case "play":
            guard let slot = args["slot"] as? Int else {
                return result(FlutterError(code: "ARG", message: "slot missing", details: nil))
            }
            pool.play(slot: slot)
            result(nil)

        case "pause":
            guard let slot = args["slot"] as? Int else {
                return result(FlutterError(code: "ARG", message: "slot missing", details: nil))
            }
            pool.pause(slot: slot)
            result(nil)

        case "setVolume":
            guard let slot = args["slot"] as? Int else {
                return result(FlutterError(code: "ARG", message: "slot missing", details: nil))
            }
            let volume = (args["volume"] as? Double).map { Float($0) } ?? 1.0
            pool.setVolume(slot: slot, volume: volume)
            result(nil)

        case "seekTo":
            guard let slot = args["slot"] as? Int else {
                return result(FlutterError(code: "ARG", message: "slot missing", details: nil))
            }
            let posMs = args["positionMs"] as? Int ?? 0
            pool.seekTo(slot: slot, positionMs: posMs)
            result(nil)

        case "release":
            guard let slot = args["slot"] as? Int else {
                return result(FlutterError(code: "ARG", message: "slot missing", details: nil))
            }
            pool.release(slot: slot)
            result(nil)

        case "onFirstFrame":
            guard let slot = args["slot"] as? Int else {
                return result(FlutterError(code: "ARG", message: "slot missing", details: nil))
            }
            pool.setOnFirstFrameListener(slot: slot)
            result(nil)

        case "releaseAll":
            pool.releaseAll()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
