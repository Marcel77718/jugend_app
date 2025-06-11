import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jugend_app/core/logging_service.dart';
import 'package:jugend_app/core/network_optimizer.dart';

class FirebaseOptimizer {
  static FirebaseOptimizer? _instance; // Mache es nullable

  // Getter für die bereits initialisierte Instanz
  static FirebaseOptimizer get instance {
    if (_instance == null) {
      LoggingService.instance.log(
        'FirebaseOptimizer.instance wurde vor der Initialisierung aufgerufen!',
        level: LogLevel.error,
      );
      throw StateError('FirebaseOptimizer muss zuerst initialisiert werden!');
    }
    return _instance!;
  }

  // Privater Konstruktor, um direkte Instanziierung zu verhindern
  FirebaseOptimizer._internal();

  /// Initialisiert den FirebaseOptimizer und gibt die Singleton-Instanz zurück.
  static Future<FirebaseOptimizer> initializeAndGetInstance() async {
    if (_instance == null) {
      _instance = FirebaseOptimizer._internal();
      await _instance!._initializeFirebase();
      await _instance!._initializeOfflinePersistence();
      LoggingService.instance.log(
        'FirebaseOptimizer initialisiert',
        level: LogLevel.info,
      );
    }
    return _instance!;
  }

  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;
  final _batchSize = 500;
  final _cache = <String, dynamic>{};
  final _cacheTimeout = const Duration(minutes: 5);
  final _lastCacheUpdate = <String, DateTime>{};
  final _offlineCache = <String, dynamic>{};
  bool _isOfflineMode = false;

  Future<void> _initializeFirebase() async {
    // Firebase-App initialisieren, falls noch nicht geschehen
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    // Initialisiere _firestore und _storage hier
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
  }

  Future<void> _initializeOfflinePersistence() async {
    try {
      // Aktiviere Offline-Persistence
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        sslEnabled: true,
      );

      // Überwache Netzwerk-Status
      _firestore
          .waitForPendingWrites()
          .then((_) {
            _isOfflineMode = false;
            _syncOfflineChanges();
          })
          .catchError((_) {
            _isOfflineMode = true;
          });
    } catch (e) {
      LoggingService.instance.log(
        'Fehler bei der Initialisierung der Offline-Persistence: $e',
        level: LogLevel.error,
        error: e,
      );
    }
  }

  Future<void> _syncOfflineChanges() async {
    if (_offlineCache.isEmpty) return;

    try {
      final batch = _firestore.batch();
      var operationCount = 0;

      for (final entry in _offlineCache.entries) {
        final path = entry.key;
        final data = entry.value;

        if (data['operation'] == 'set') {
          batch.set(_firestore.doc(path), data['data']);
        } else if (data['operation'] == 'update') {
          batch.update(_firestore.doc(path), data['data']);
        } else if (data['operation'] == 'delete') {
          batch.delete(_firestore.doc(path));
        }

        operationCount++;
        if (operationCount >= _batchSize) {
          await batch.commit();
          operationCount = 0;
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }

      _offlineCache.clear();
    } catch (e) {
      LoggingService.instance.log(
        'Fehler beim Synchronisieren der Offline-Änderungen: $e',
        level: LogLevel.error,
        error: e,
      );
    }
  }

  /// Optimierte Firestore-Abfrage mit Caching, Pagination und Offline-Support
  Stream<QuerySnapshot<T>> optimizedQuery<T>({
    required String collection,
    Query<T> Function(Query<T> query)? queryBuilder,
    int pageSize = 20,
    bool enableCache = true,
    bool enableOfflineCache = true,
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

  /// Optimierte Batch-Operation für Firestore mit Offline-Support
  Future<void> batchWrite({
    required List<Map<String, dynamic>> operations,
    required String collection,
  }) async {
    if (operations.isEmpty) return;

    if (_isOfflineMode) {
      // Speichere Operationen im Offline-Cache
      for (final operation in operations) {
        final docRef = '$collection/${DateTime.now().millisecondsSinceEpoch}';
        _offlineCache[docRef] = {
          'operation': 'set',
          'data': operation,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      return;
    }

    return NetworkOptimizer.instance.optimizedRequest(
      requestId: 'batch_${collection}_${DateTime.now().millisecondsSinceEpoch}',
      request: () async {
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

        await Future.wait(batches.map((batch) => batch.commit()));
      },
    );
  }

  /// Optimierte Datei-Upload-Operation
  Future<String> optimizedUpload({
    required String path,
    required List<int> data,
    String? contentType,
    Map<String, String>? customMetadata,
  }) async {
    return NetworkOptimizer.instance.optimizedRequest(
      requestId: 'upload_$path',
      request: () async {
        final ref = _storage.ref().child(path);
        final metadata = SettableMetadata(
          contentType: contentType,
          customMetadata: customMetadata,
        );

        final uploadTask = ref.putData(Uint8List.fromList(data), metadata);
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      },
    );
  }

  /// Optimierte Datei-Download-Operation
  Future<Uint8List> optimizedDownload(String path) async {
    return NetworkOptimizer.instance.optimizedRequest(
      requestId: 'download_$path',
      request: () async {
        final ref = _storage.ref().child(path);
        const maxSize = 10 * 1024 * 1024; // 10MB
        final data = await ref.getData(maxSize);
        if (data == null) {
          throw Exception('Keine Daten gefunden');
        }
        return data;
      },
    );
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
    _offlineCache.clear();
  }

  bool get isOfflineMode => _isOfflineMode;
}
