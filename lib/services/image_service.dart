import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jugend_app/core/logging_service.dart';
import 'package:jugend_app/core/memory_optimizer.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  static ImageService get instance => _instance;

  final _cacheManager = DefaultCacheManager();
  final _preloadedUrls = <String>{};
  final _loadingQueue = <String>[];
  bool _isProcessingQueue = false;

  ImageService._internal();

  Widget getOptimizedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool useLazyLoading = true,
  }) {
    if (useLazyLoading && !_preloadedUrls.contains(imageUrl)) {
      _addToLoadingQueue(imageUrl);
    }

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
      memCacheWidth: (width?.toInt() ?? 300) * 2,
      memCacheHeight: (height?.toInt() ?? 300) * 2,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      imageBuilder:
          (context, imageProvider) => Image(
            image: imageProvider,
            fit: fit,
            width: width,
            height: height,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: child,
              );
            },
          ),
    );
  }

  void _addToLoadingQueue(String imageUrl) {
    if (_loadingQueue.contains(imageUrl)) return;
    _loadingQueue.add(imageUrl);
    _processLoadingQueue();
  }

  Future<void> _processLoadingQueue() async {
    if (_isProcessingQueue || _loadingQueue.isEmpty) return;
    _isProcessingQueue = true;

    try {
      while (_loadingQueue.isNotEmpty) {
        final url = _loadingQueue.removeAt(0);
        if (_preloadedUrls.contains(url)) continue;

        try {
          final file = await _cacheManager.getSingleFile(url);
          _preloadedUrls.add(url);

          // Tracke Cache-Größe
          final fileSize = await file.length();
          MemoryOptimizer.instance.trackCacheEntry(url, fileSize);
        } catch (e) {
          LoggingService.instance.log(
            'Fehler beim Vorladen des Bildes: $e',
            level: LogLevel.error,
            error: e,
          );
        }
      }
    } finally {
      _isProcessingQueue = false;
      if (_loadingQueue.isNotEmpty) {
        _processLoadingQueue();
      }
    }
  }

  Future<void> preloadImage(String imageUrl) async {
    if (_preloadedUrls.contains(imageUrl)) return;
    _addToLoadingQueue(imageUrl);
  }

  Future<void> preloadImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      _addToLoadingQueue(url);
    }
  }

  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
      _preloadedUrls.clear();
      _loadingQueue.clear();
      _isProcessingQueue = false;
      MemoryOptimizer.instance.clearCache();
    } catch (e) {
      LoggingService.instance.log(
        'Fehler beim Leeren des Bild-Caches: $e',
        level: LogLevel.error,
        error: e,
      );
    }
  }

  Future<void> removeFromCache(String imageUrl) async {
    try {
      await _cacheManager.removeFile(imageUrl);
      _preloadedUrls.remove(imageUrl);
      _loadingQueue.remove(imageUrl);
      MemoryOptimizer.instance.removeCacheEntry(imageUrl);
    } catch (e) {
      LoggingService.instance.log(
        'Fehler beim Entfernen des Bildes aus dem Cache: $e',
        level: LogLevel.error,
        error: e,
      );
    }
  }
}
