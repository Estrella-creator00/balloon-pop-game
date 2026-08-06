import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef HapticPerformer = Future<void> Function();

/// A single, short haptic response for a confirmed gameplay interaction.
///
/// Flutter Web maps [HapticFeedback.lightImpact] to the browser vibration API
/// when it is available. Unsupported browsers safely do nothing. This service
/// deliberately owns no timer, ticker, or repeating work.
abstract final class HapticService {
  static HapticPerformer _perform = HapticFeedback.lightImpact;

  static void shortImpact() {
    try {
      unawaited(_ignoreFailure(_perform()));
    } catch (_) {
      // Some platforms may reject haptics synchronously. Gameplay continues.
    }
  }

  static Future<void> _ignoreFailure(Future<void> operation) async {
    try {
      await operation;
    } catch (_) {
      // Unsupported or denied vibration is intentionally silent.
    }
  }

  @visibleForTesting
  static void setPerformerForTest(HapticPerformer performer) {
    _perform = performer;
  }

  @visibleForTesting
  static void resetPerformerForTest() {
    _perform = HapticFeedback.lightImpact;
  }
}
