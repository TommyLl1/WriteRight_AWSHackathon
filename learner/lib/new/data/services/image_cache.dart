import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/logger.dart';

/// Common image cache utility for optimized image loading and caching
/// Consolidates all image caching logic across the application
class CommonImageCache {
  static final CommonImageCache _instance = CommonImageCache._internal();
  factory CommonImageCache() => _instance;
  CommonImageCache._internal();

  // Cache for pre-built image widgets
  final Map<String, Widget> _widgetCache = {};

  // Cache for image providers
  final Map<String, ImageProvider> _providerCache = {};

  /// Image paths used throughout the app
  static const String oceanBackground = 'assets/images/ocean-bg.png';
  static const String dolphinCharacter = 'assets/images/dolphin.png';
  static const String diverAvatar = 'assets/images/diver.png';
  static const String avatarProfile = 'assets/images/avatar.png';
  static const String incorrectWordIcon = 'assets/images/incorrect_word.png';

  /// Initialize the image cache system
  static Future<void> initialize() async {
    await _instance._preloadCriticalImages();
    _instance._optimizeImageCache();
  }

  /// Preload critical images to avoid frame drops during runtime
  Future<void> _preloadCriticalImages() async {
    final criticalImages = [
      oceanBackground,
      dolphinCharacter,
      diverAvatar,
      avatarProfile,
      incorrectWordIcon,
    ];
    final futures = criticalImages.map((path) async {
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
  void _optimizeImageCache() {
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        50 * 1024 * 1024; // 50MB
  }

  /// Get cached background widget
  Widget getBackgroundWidget({bool darkened = false}) {
    final key = darkened ? '${oceanBackground}_darkened' : oceanBackground;

    return _widgetCache[key] ??= Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(oceanBackground),
          fit: BoxFit.cover,
          colorFilter: darkened
              ? ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.3),
                  BlendMode.darken,
                )
              : null,
        ),
      ),
    );
  }

  /// Get cached character widget with glow effect
  Widget getCharacterWidget({
  
    String imagePath = dolphinCharacter,
    double height = 200,
    bool withGlow = true,
  }) {
    final key = '${imagePath}_${height}_$withGlow';

    return _widgetCache[key] ??= _buildCharacterWidget(
      imagePath: imagePath,
      height: height,
      withGlow: withGlow,
    );
  }

  Widget _buildCharacterWidget({
    required String imagePath,
    required double height,
    required bool withGlow,
  }) {
    if (!withGlow) {
      return Image.asset(
        imagePath,
        height: height,
        cacheHeight: (height * 2).toInt(),
        filterQuality: FilterQuality.medium,
        errorBuilder: _imageErrorBuilder,
      );
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow layer
          Transform.scale(
            scale: 1.1,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: 0.4),
                BlendMode.modulate,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withAlpha((0.6 * 255).toInt()),
                      blurRadius: 20,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Image.asset(
                  imagePath,
                  height: height,
                  cacheHeight: (height * 2).toInt(),
                  filterQuality: FilterQuality.medium,
                  errorBuilder: _imageErrorBuilder,
                ),
              ),
            ),
          ),
          // Inner glow layer
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.white.withValues(alpha: 0.7),
              BlendMode.modulate,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.lightBlueAccent.withAlpha((0.8 * 255).toInt()),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.asset(
                imagePath,
                height: height,
                cacheHeight: (height * 2).toInt(),
                filterQuality: FilterQuality.medium,
                errorBuilder: _imageErrorBuilder,
              ),
            ),
          ),
          // Main character image
          Image.asset(
            imagePath,
            height: height,
            cacheHeight: (height * 2).toInt(),
            filterQuality: FilterQuality.medium,
            errorBuilder: _imageErrorBuilder,
          ),
        ],
      ),
    );
  }

  /// Get optimized image widget for exercise cards
  Widget getExerciseCardImage({
    required String imagePath,
    double size = 120,
    BoxFit fit = BoxFit.cover,
  }) {
    final key = '${imagePath}_card_$size';

    return _widgetCache[key] ??= ClipOval(
      child: Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: fit,
        cacheWidth: (size * 2).toInt(),
        cacheHeight: (size * 2).toInt(),
        filterQuality: FilterQuality.medium,
        errorBuilder: _imageErrorBuilder,
      ),
    );
  }

  /// Get cached image provider
  ImageProvider getImageProvider(String imagePath) {
    return _providerCache[imagePath] ??= AssetImage(imagePath);
  }

  /// Error builder for failed image loads
  Widget _imageErrorBuilder(
      BuildContext context, Object error, StackTrace? stackTrace) {
    AppLogger.error('Image load error', error, stackTrace);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.error_outline,
        color: Colors.grey,
        size: 50,
      ),
    );
  }

  /// Clear specific cached widgets (useful for memory management)
  void clearWidgetCache([String? key]) {
    if (key != null) {
      _widgetCache.remove(key);
    } else {
      _widgetCache.clear();
    }
  }

  /// Clear Flutter's internal image cache
  void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    _providerCache.clear();
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': imageCache.currentSize,
      'maximumSize': imageCache.maximumSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
      'widgetCacheSize': _widgetCache.length,
      'providerCacheSize': _providerCache.length,
    };
  }

  /// Log performance metrics
  static void logPerformanceMetrics(String operation, Duration duration) {
    AppLogger.debug(
        'ImageCache Performance: $operation took ${duration.inMilliseconds}ms');
  }
}
