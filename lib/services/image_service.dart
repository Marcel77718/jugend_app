import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jugend_app/core/logging_service.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  static ImageService get instance => _instance;

  final _cacheManager = DefaultCacheManager();

  ImageService._internal();

  Widget getOptimizedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder:
          (context, url) =>
              placeholder ?? const Center(child: CircularProgressIndicator()),
      errorWidget:
          (context, url, error) =>
              errorWidget ?? const Icon(Icons.error_outline, color: Colors.red),
      cacheManager: _cacheManager,
      memCacheWidth: (width?.toInt() ?? 300) * 2, // 2x für Retina Displays
      memCacheHeight: (height?.toInt() ?? 300) * 2,
    );
  }

  Future<void> preloadImage(String imageUrl) async {
    try {
      await _cacheManager.getSingleFile(imageUrl);
    } catch (e) {
      LoggingService.instance.log(
        'Fehler beim Vorladen des Bildes: $e',
        level: LogLevel.error,
        error: e,
      );
    }
  }

  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      LoggingService.instance.log(
        'Fehler beim Leeren des Bild-Caches: $e',
        level: LogLevel.error,
        error: e,
      );
    }
  }
}
