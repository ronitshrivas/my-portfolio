// import UIKit
// import Flutter
// import Firebase
// import FirebaseMessaging
// import UserNotifications
// import AVFoundation

// @main
// @objc class AppDelegate: FlutterAppDelegate {

//     override func application(
//         _ application: UIApplication,
//         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//     ) -> Bool {

//         // ── 1. Video & Audio Session ─────────────────────────────────────
//         do {
//             try AVAudioSession.sharedInstance().setCategory(
//                 .playback,
//                 mode: .moviePlayback,
//                 options: [.mixWithOthers]
//             )
//             try AVAudioSession.sharedInstance().setActive(true)
//         } catch {
//             print("[AVAudioSession] Error: \(error)")
//         }

//         // ── 2. Firebase ──────────────────────────────────────────────────
//         FirebaseApp.configure()
//         Messaging.messaging().delegate = self

//         // ── 3. Notifications ─────────────────────────────────────────────
//         UNUserNotificationCenter.current().delegate = self
//         UNUserNotificationCenter.current().requestAuthorization(
//             options: [.alert, .badge, .sound]
//         ) { granted, error in
//             print("[Notifications] Permission granted: \(granted)")
//         }
//         application.registerForRemoteNotifications()

//         // ── 4. Flutter ───────────────────────────────────────────────────
//         GeneratedPluginRegistrant.register(with: self)
//         return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//     }

//     // ── APNs token → Firebase ────────────────────────────────────────────
//     override func application(
//         _ application: UIApplication,
//         didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
//     ) {
//         Messaging.messaging().apnsToken = deviceToken
//         super.application(
//             application,
//             didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
//         )
//     }

//     // ── APNs registration failed ─────────────────────────────────────────
//     override func application(
//         _ application: UIApplication,
//         didFailToRegisterForRemoteNotificationsWithError error: Error
//     ) {
//         print("[APNs] Failed: \(error.localizedDescription)")
//     }

//     // ── Show notification when app is FOREGROUND ─────────────────────────
//     // NOTE: 'override' required because FlutterAppDelegate already implements this
//     override func userNotificationCenter(
//         _ center: UNUserNotificationCenter,
//         willPresent notification: UNNotification,
//         withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
//     ) {
//         if #available(iOS 14.0, *) {
//             completionHandler([.banner, .badge, .sound])
//         } else {
//             completionHandler([.alert, .badge, .sound])
//         }
//     }

//     // ── Handle notification TAP ──────────────────────────────────────────
//     // NOTE: 'override' required because FlutterAppDelegate already implements this
//     override func userNotificationCenter(
//         _ center: UNUserNotificationCenter,
//         didReceive response: UNNotificationResponse,
//         withCompletionHandler completionHandler: @escaping () -> Void
//     ) {
//         let userInfo = response.notification.request.content.userInfo
//         print("[Notification] Tapped: \(userInfo)")
//         completionHandler()
//     }
// }

// // ── FCM Token — extension is safe here (MessagingDelegate only) ──────────────
// extension AppDelegate: MessagingDelegate {
//     func messaging(
//         _ messaging: Messaging,
//         didReceiveRegistrationToken fcmToken: String?
//     ) {
//         print("[FCM] Token: \(fcmToken ?? "nil")")
//         NotificationCenter.default.post(
//             name: Notification.Name("FCMToken"),
//             object: nil,
//             userInfo: ["token": fcmToken ?? ""]
//         )
//     }
// }


// import UIKit
// import Flutter
// import Firebase
// import FirebaseMessaging
// import UserNotifications
// import AVFoundation

// // MARK: - Reels Surface View Factory

// class ReelsSurfaceViewFactory: NSObject, FlutterPlatformViewFactory {
//     private let messenger: FlutterBinaryMessenger

//     init(messenger: FlutterBinaryMessenger) {
//         self.messenger = messenger
//         super.init()
//     }

//     func create(
//         withFrame frame: CGRect,
//         viewIdentifier viewId: Int64,
//         arguments args: Any?
//     ) -> FlutterPlatformView {
//         return ReelsSurfaceView(frame: frame, viewId: viewId, messenger: messenger, args: args)
//     }

//     func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
//         return FlutterStandardMessageCodec.sharedInstance()
//     }
// }

// class ReelsSurfaceView: NSObject, FlutterPlatformView {
//     private let playerView: UIView

//     init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
//         playerView = UIView(frame: frame)
//         playerView.backgroundColor = .black
//         super.init()
//     }

//     func view() -> UIView {
//         return playerView
//     }
// }

// // MARK: - Reels Player Channel Handler

// class ReelsPlayerHandler: NSObject {
//     static let channelName = "reels_player"
//     private var channel: FlutterMethodChannel

//     init(messenger: FlutterBinaryMessenger) {
//         channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
//         super.init()
//         channel.setMethodCallHandler(handle)
//     }

//     private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//         switch call.method {
//         case "prepare":
//             result(nil)
//         case "play":
//             result(nil)
//         case "pause":
//             result(nil)
//         case "switchSurface":
//             result(nil)
//         case "releaseAll":
//             result(nil)
//         case "onFirstFrame":
//             result(nil)
//         default:
//             result(FlutterMethodNotImplemented)
//         }
//     }
// }

// // MARK: - AppDelegate

// @main
// @objc class AppDelegate: FlutterAppDelegate {

//     private var reelsPlayerHandler: ReelsPlayerHandler?

//     override func application(
//         _ application: UIApplication,
//         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//     ) -> Bool {

//         // ── 1. Video & Audio Session ─────────────────────────────────────
//         do {
//             try AVAudioSession.sharedInstance().setCategory(
//                 .playback,
//                 mode: .moviePlayback,
//                 options: [.mixWithOthers]
//             )
//             try AVAudioSession.sharedInstance().setActive(true)
//         } catch {
//             print("[AVAudioSession] Error: \(error)")
//         }

//         // ── 2. Firebase ──────────────────────────────────────────────────
//         FirebaseApp.configure()
//         Messaging.messaging().delegate = self

//         // ── 3. Notifications ─────────────────────────────────────────────
//         UNUserNotificationCenter.current().delegate = self
//         UNUserNotificationCenter.current().requestAuthorization(
//             options: [.alert, .badge, .sound]
//         ) { granted, error in
//             print("[Notifications] Permission granted: \(granted)")
//         }
//         application.registerForRemoteNotifications()

//         // ── 4. Register reels_surface_view platform view ─────────────────
//         // MUST happen before GeneratedPluginRegistrant.register
//         let controller = window?.rootViewController as! FlutterViewController
//         let messenger = controller.binaryMessenger

//         controller.engine?.platformViewsController.registrar(forPlugin: "ReelsSurfaceViewPlugin")
//         let registrar = self.registrar(forPlugin: "ReelsSurfaceViewPlugin")!
//         registrar.register(
//             ReelsSurfaceViewFactory(messenger: registrar.messenger()),
//             withId: "reels_surface_view"
//         )

//         // ── 5. Register reels_player method channel ───────────────────────
//         reelsPlayerHandler = ReelsPlayerHandler(messenger: messenger)

//         // ── 6. Flutter plugins ───────────────────────────────────────────
//         GeneratedPluginRegistrant.register(with: self)
//         return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//     }

//     // ── APNs token → Firebase ────────────────────────────────────────────
//     override func application(
//         _ application: UIApplication,
//         didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
//     ) {
//         Messaging.messaging().apnsToken = deviceToken
//         super.application(
//             application,
//             didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
//         )
//     }

//     // ── APNs registration failed ─────────────────────────────────────────
//     override func application(
//         _ application: UIApplication,
//         didFailToRegisterForRemoteNotificationsWithError error: Error
//     ) {
//         print("[APNs] Failed: \(error.localizedDescription)")
//     }

//     // ── Show notification when app is FOREGROUND ─────────────────────────
//     override func userNotificationCenter(
//         _ center: UNUserNotificationCenter,
//         willPresent notification: UNNotification,
//         withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
//     ) {
//         if #available(iOS 14.0, *) {
//             completionHandler([.banner, .badge, .sound])
//         } else {
//             completionHandler([.alert, .badge, .sound])
//         }
//     }

//     // ── Handle notification TAP ──────────────────────────────────────────
//     override func userNotificationCenter(
//         _ center: UNUserNotificationCenter,
//         didReceive response: UNNotificationResponse,
//         withCompletionHandler completionHandler: @escaping () -> Void
//     ) {
//         let userInfo = response.notification.request.content.userInfo
//         print("[Notification] Tapped: \(userInfo)")
//         completionHandler()
//     }
// }

// // ── FCM Token ────────────────────────────────────────────────────────────────
// extension AppDelegate: MessagingDelegate {
//     func messaging(
//         _ messaging: Messaging,
//         didReceiveRegistrationToken fcmToken: String?
//     ) {
//         print("[FCM] Token: \(fcmToken ?? "nil")")
//         NotificationCenter.default.post(
//             name: Notification.Name("FCMToken"),
//             object: nil,
//             userInfo: ["token": fcmToken ?? ""]
//         )
//     }
// }


import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import UserNotifications
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {

    // Keep strong references — plugin and pool must outlive the channel
    private var reelsPool: ReelsPlayerPool!
    private var reelsPlugin: ReelsPlayerPlugin!

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // ── 1. Video & Audio Session ─────────────────────────────────────────
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AVAudioSession] Error: \(error)")
        }

        // ── 2. Firebase ──────────────────────────────────────────────────────
        FirebaseApp.configure()
        Messaging.messaging().delegate = self

        // ── 3. Notifications ─────────────────────────────────────────────────
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            print("[Notifications] Permission granted: \(granted)")
        }
        application.registerForRemoteNotifications()

        // ── 4. Reels native plugin ────────────────────────────────────────────
        // MUST happen before GeneratedPluginRegistrant.register(with: self)
        //
        // The pool is created once and lives for the app's lifetime — same
        // lifecycle as Android's ReelsPlayerPlugin onAttachedToEngine.
        //
        // We need FlutterViewController's binaryMessenger, which is available
        // as soon as the window root view controller is set (before viewDidLoad).
        let controller = window?.rootViewController as! FlutterViewController
        let messenger  = controller.binaryMessenger

        reelsPool   = ReelsPlayerPool()
        reelsPlugin = ReelsPlayerPlugin(pool: reelsPool, messenger: messenger)

        // Register the platform view factory for "reels_surface_view"
        let registrar = self.registrar(forPlugin: "ReelsSurfaceViewPlugin")!
        registrar.register(
            ReelsSurfaceViewFactory(pool: reelsPool),
            withId: "reels_surface_view"
        )

        // ── 5. Flutter plugins ───────────────────────────────────────────────
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // ── APNs token → Firebase ────────────────────────────────────────────────
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
        super.application(
            application,
            didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
        )
    }

    // ── APNs registration failed ─────────────────────────────────────────────
    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[APNs] Failed: \(error.localizedDescription)")
    }

    // ── Show notification when app is FOREGROUND ─────────────────────────────
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }

    // ── Handle notification TAP ──────────────────────────────────────────────
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("[Notification] Tapped: \(userInfo)")
        completionHandler()
    }
}

// ── FCM Token ────────────────────────────────────────────────────────────────
extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        print("[FCM] Token: \(fcmToken ?? "nil")")
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: ["token": fcmToken ?? ""]
        )
    }
}