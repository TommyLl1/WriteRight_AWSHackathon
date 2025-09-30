import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';
import 'logger.dart';

class PerformanceUtils {
  /// Preload critical images to avoid frame drops during runtime
  static Future<void> preloadImages(List<String> imagePaths) async {
    final futures = imagePaths.map((path) async {
      try {
        await rootBundle.load(path);
        AppLogger.debug('✓ Preloaded: $path');
      } catch (e) {
        AppLogger.warning('✗ Failed to preload: $path', e);
      }
    });

    await Future.wait(futures);
  }

  /// Optimize image cache settings for better memory usage
  static void optimizeImageCache() {
    // Reduce image cache size on lower-end devices
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        50 * 1024 * 1024; // 50MB
  }

  /// Clear image cache when memory is low
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Log performance metrics
  static void logPerformanceMetrics(String operation, Duration duration) {
    if (kDebugMode) {
      AppLogger.debug(
          'Performance: $operation took ${duration.inMilliseconds}ms');
    }
  }
}
