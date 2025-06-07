import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jugend_app/core/logging_service.dart';

class FirebaseOptimizer {
  static final FirebaseOptimizer _instance = FirebaseOptimizer._internal();
  static FirebaseOptimizer get instance => _instance;

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _batchSize = 500;
  final _cache = <String, dynamic>{};
  final _cacheTimeout = const Duration(minutes: 5);
  final _lastCacheUpdate = <String, DateTime>{};

  FirebaseOptimizer._internal();

  /// Optimierte Firestore-Abfrage mit Caching und Pagination
  Stream<QuerySnapshot<T>> optimizedQuery<T>({
    required String collection,
    Query<T> Function(Query<T> query)? queryBuilder,
    int pageSize = 20,
    bool enableCache = true,
  }) {
    Query<T> query = _firestore.collection(collection) as Query<T>;
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    query = query.limit(pageSize);

    if (enableCache) {
      final cacheKey = '${collection}_${queryBuilder?.toString() ?? ""}';
      if (_isCacheValid(cacheKey)) {
        return Stream.value(_cache[cacheKey] as QuerySnapshot<T>);
      }
    }

    return query.snapshots().map((snapshot) {
      if (enableCache) {
        final cacheKey = '${collection}_${queryBuilder?.toString() ?? ""}';
        _updateCache(cacheKey, snapshot);
      }
      return snapshot;
    });
  }

  /// Optimierte Batch-Operation für Firestore
  Future<void> batchWrite({
    required List<Map<String, dynamic>> operations,
    required String collection,
  }) async {
    if (operations.isEmpty) return;

    final batches = <WriteBatch>[];
    var currentBatch = _firestore.batch();
    var operationCount = 0;

    for (final operation in operations) {
      final docRef = _firestore.collection(collection).doc();
      currentBatch.set(docRef, operation);
      operationCount++;

      if (operationCount >= _batchSize) {
        batches.add(currentBatch);
        currentBatch = _firestore.batch();
        operationCount = 0;
      }
    }

    if (operationCount > 0) {
      batches.add(currentBatch);
    }

    try {
      await Future.wait(batches.map((batch) => batch.commit()));
    } catch (e) {
      LoggingService.instance.log(
        'Fehler bei Batch-Operation: $e',
        level: LogLevel.error,
        error: e,
      );
      rethrow;
    }
  }

  /// Optimierte Datei-Upload-Operation
  Future<String> optimizedUpload({
    required String path,
    required List<int> data,
    String? contentType,
    Map<String, String>? customMetadata,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: customMetadata,
      );

      final uploadTask = ref.putData(Uint8List.fromList(data), metadata);

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      LoggingService.instance.log(
        'Fehler beim Datei-Upload: $e',
        level: LogLevel.error,
        error: e,
      );
      rethrow;
    }
  }

  /// Optimierte Datei-Download-Operation
  Future<Uint8List> optimizedDownload(String path) async {
    try {
      final ref = _storage.ref().child(path);
      const maxSize = 10 * 1024 * 1024; // 10MB
      final data = await ref.getData(maxSize);
      if (data == null) {
        throw Exception('Keine Daten gefunden');
      }
      return data;
    } catch (e) {
      LoggingService.instance.log(
        'Fehler beim Datei-Download: $e',
        level: LogLevel.error,
        error: e,
      );
      rethrow;
    }
  }

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final lastUpdate = _lastCacheUpdate[key];
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate) < _cacheTimeout;
  }

  void _updateCache(String key, dynamic value) {
    _cache[key] = value;
    _lastCacheUpdate[key] = DateTime.now();
  }

  void clearCache() {
    _cache.clear();
    _lastCacheUpdate.clear();
  }
}
