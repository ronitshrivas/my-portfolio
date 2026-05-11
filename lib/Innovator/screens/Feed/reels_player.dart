// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// /// Dart wrapper around the native "reels_player" MethodChannel.
// ///
// /// Codec compatibility (avc1.F4001E etc.) is handled entirely on the native
// /// side via DefaultRenderersFactory.setEnableDecoderFallback(true).
// /// No fallback URL is needed here.
// class ReelsPlayer {
//   static const _ch = MethodChannel('reels_player');

//   /// Load [url] into [slot] and start buffering (no surface required).
//   /// [token] is sent as the Authorization Bearer header.
//   static Future<void> prepare(int slot, String url, String token) async {
//     assert(slot >= 0 && slot <= 2);
//     try {
//       await _ch.invokeMethod('prepare', {
//         'slot': slot,
//         'url': url,
//         'token': token,
//       });
//     } catch (e) {
//       debugPrint('[ReelsPlayer] prepare: $e');
//     }
//   }

//   /// Move the single shared SurfaceView to [slot].
//   /// Call this before play() when changing reels.
//   static Future<void> switchSurface(int slot) async {
//     assert(slot >= 0 && slot <= 2);
//     try {
//       await _ch.invokeMethod('switchSurface', {'slot': slot});
//     } catch (e) {
//       debugPrint('[ReelsPlayer] switchSurface: $e');
//     }
//   }

//   static Future<void> play(int slot) async {
//     try {
//       await _ch.invokeMethod('play', {'slot': slot});
//     } catch (e) {
//       debugPrint('[ReelsPlayer] play: $e');
//     }
//   }

//   static Future<void> pause(int slot) async {
//     try {
//       await _ch.invokeMethod('pause', {'slot': slot});
//     } catch (e) {
//       debugPrint('[ReelsPlayer] pause: $e');
//     }
//   }

//   static Future<void> setVolume(int slot, double volume) async {
//     try {
//       await _ch.invokeMethod('setVolume', {'slot': slot, 'volume': volume});
//     } catch (e) {
//       debugPrint('[ReelsPlayer] setVolume: $e');
//     }
//   }

//   static Future<void> seekTo(int slot, int positionMs) async {
//     try {
//       await _ch.invokeMethod('seekTo', {
//         'slot': slot,
//         'positionMs': positionMs,
//       });
//     } catch (e) {
//       debugPrint('[ReelsPlayer] seekTo: $e');
//     }
//   }

//   static Future<void> release(int slot) async {
//     try {
//       await _ch.invokeMethod('release', {'slot': slot});
//     } catch (e) {
//       debugPrint('[ReelsPlayer] release: $e');
//     }
//   }

//   static Future<void> releaseAll() async {
//     try {
//       await _ch.invokeMethod('releaseAll');
//     } catch (e) {
//       debugPrint('[ReelsPlayer] releaseAll: $e');
//     }
//   }

//   /// Register a one-shot callback fired when [slot] renders its first frame.
//   /// Use this to hide the loading shimmer at the exact right moment.
//   static void listenFirstFrame(int slot, VoidCallback onReady) {
//     _ch.invokeMethod('onFirstFrame', {'slot': slot});
//     _ch.setMethodCallHandler((call) async {
//       if (call.method == 'firstFrameReady' && call.arguments['slot'] == slot) {
//         onReady();
//       }
//     });
//   }
// }

// /// The ONE shared SurfaceView that all ExoPlayers render into.
// /// Only one instance should ever exist in the widget tree.
// /// Never remove it — surface destruction causes black frames.
// class ReelsSurfaceWidget extends StatelessWidget {
//   const ReelsSurfaceWidget({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) => AndroidView(
//     viewType: 'reels_surface_view',
//     layoutDirection: TextDirection.ltr,
//     creationParamsCodec: const StandardMessageCodec(),
//   );
// }

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReelsPlayer {
  static const _ch = MethodChannel('reels_player');

  static Future<void> prepare(int slot, String url, String token) async {
    assert(slot >= 0 && slot <= 2);
    try {
      await _ch.invokeMethod('prepare', {
        'slot': slot,
        'url': url,
        'token': token,
      });
    } catch (e) {
      debugPrint('[ReelsPlayer] prepare: $e');
    }
  }

  static Future<void> switchSurface(int slot) async {
    assert(slot >= 0 && slot <= 2);
    try {
      await _ch.invokeMethod('switchSurface', {'slot': slot});
    } catch (e) {
      debugPrint('[ReelsPlayer] switchSurface: $e');
    }
  }

  static Future<void> play(int slot) async {
    try {
      await _ch.invokeMethod('play', {'slot': slot});
    } catch (e) {
      debugPrint('[ReelsPlayer] play: $e');
    }
  }

  static Future<void> pause(int slot) async {
    try {
      await _ch.invokeMethod('pause', {'slot': slot});
    } catch (e) {
      debugPrint('[ReelsPlayer] pause: $e');
    }
  }

  static Future<void> setVolume(int slot, double volume) async {
    try {
      await _ch.invokeMethod('setVolume', {'slot': slot, 'volume': volume});
    } catch (e) {
      debugPrint('[ReelsPlayer] setVolume: $e');
    }
  }

  static Future<void> seekTo(int slot, int positionMs) async {
    try {
      await _ch.invokeMethod('seekTo', {
        'slot': slot,
        'positionMs': positionMs,
      });
    } catch (e) {
      debugPrint('[ReelsPlayer] seekTo: $e');
    }
  }

  static Future<void> release(int slot) async {
    try {
      await _ch.invokeMethod('release', {'slot': slot});
    } catch (e) {
      debugPrint('[ReelsPlayer] release: $e');
    }
  }

  static Future<void> releaseAll() async {
    try {
      await _ch.invokeMethod('releaseAll');
    } catch (e) {
      debugPrint('[ReelsPlayer] releaseAll: $e');
    }
  }

  static void listenFirstFrame(int slot, VoidCallback onReady) {
    _ch.invokeMethod('onFirstFrame', {'slot': slot});
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'firstFrameReady' && call.arguments['slot'] == slot) {
        onReady();
      }
    });
  }
}

class ReelsSurfaceWidget extends StatelessWidget {
  const ReelsSurfaceWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ── iOS ──────────────────────────────────────────────────────────────────
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const UiKitView(
        viewType: 'reels_surface_view',
        layoutDirection: TextDirection.ltr,
        creationParamsCodec: StandardMessageCodec(),
      );
    }

    // ── Android (default) ────────────────────────────────────────────────────
    return const AndroidView(
      viewType: 'reels_surface_view',
      layoutDirection: TextDirection.ltr,
      creationParamsCodec: StandardMessageCodec(),
    );
  }
}
