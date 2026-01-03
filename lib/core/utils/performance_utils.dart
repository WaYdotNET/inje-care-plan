/// Utilities per ottimizzazione performance
class PerformanceUtils {
  PerformanceUtils._();

  /// Debounce per evitare chiamate ripetute
  static final Map<String, DateTime> _debounceTimers = {};

  static bool shouldDebounce(String key, Duration duration) {
    final lastCall = _debounceTimers[key];
    final now = DateTime.now();

    if (lastCall == null || now.difference(lastCall) > duration) {
      _debounceTimers[key] = now;
      return false;
    }

    return true;
  }

  /// Throttle per limitare la frequenza delle chiamate
  static final Map<String, DateTime> _throttleTimers = {};

  static bool shouldThrottle(String key, Duration interval) {
    final lastCall = _throttleTimers[key];
    final now = DateTime.now();

    if (lastCall == null || now.difference(lastCall) >= interval) {
      _throttleTimers[key] = now;
      return false;
    }

    return true;
  }

  /// Lazy initializer per oggetti pesanti
  static final Map<String, dynamic> _lazyCache = {};

  static T lazyInit<T>(String key, T Function() factory) {
    if (!_lazyCache.containsKey(key)) {
      _lazyCache[key] = factory();
    }
    return _lazyCache[key] as T;
  }

  static void clearLazyCache([String? key]) {
    if (key != null) {
      _lazyCache.remove(key);
    } else {
      _lazyCache.clear();
    }
  }

  /// Memoization per funzioni pure
  static final Map<String, dynamic> _memoCache = {};

  static T memoize<T>(String key, T Function() compute) {
    if (!_memoCache.containsKey(key)) {
      _memoCache[key] = compute();
    }
    return _memoCache[key] as T;
  }

  static void invalidateMemo([String? key]) {
    if (key != null) {
      _memoCache.remove(key);
    } else {
      _memoCache.clear();
    }
  }

  /// Batch updates per evitare rebuild multipli
  static Future<List<T>> batchAsync<T>(
    List<Future<T> Function()> operations, {
    int concurrency = 3,
  }) async {
    final results = <T>[];

    for (var i = 0; i < operations.length; i += concurrency) {
      final batch = operations.skip(i).take(concurrency);
      final batchResults = await Future.wait(batch.map((op) => op()));
      results.addAll(batchResults);
    }

    return results;
  }
}

/// Lazy loading provider per Riverpod
class LazyLoader<T> {
  T? _value;
  final Future<T> Function() _loader;
  bool _isLoading = false;

  LazyLoader(this._loader);

  bool get isLoaded => _value != null;
  bool get isLoading => _isLoading;
  T? get valueOrNull => _value;

  Future<T> load() async {
    if (_value != null) return _value!;
    if (_isLoading) {
      // Wait for existing load to complete
      while (_isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return _value!;
    }

    _isLoading = true;
    try {
      _value = await _loader();
      return _value!;
    } finally {
      _isLoading = false;
    }
  }

  void invalidate() {
    _value = null;
  }
}

/// Extension per liste con caricamento paginato
extension PaginatedList<T> on List<T> {
  List<T> paginate({required int page, required int pageSize}) {
    final start = page * pageSize;
    if (start >= length) return [];

    final end = (start + pageSize).clamp(0, length);
    return sublist(start, end);
  }

  /// Chunk la lista in gruppi di n elementi
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size).clamp(0, length)));
    }
    return chunks;
  }
}

/// Simple in-memory cache with TTL
class MemoryCache<T> {
  final Duration ttl;
  final Map<String, _CacheEntry<T>> _cache = {};

  MemoryCache({this.ttl = const Duration(minutes: 5)});

  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  void set(String key, T value, [Duration? customTtl]) {
    _cache[key] = _CacheEntry(
      value: value,
      expiry: DateTime.now().add(customTtl ?? ttl),
    );
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  /// Rimuove entries scadute
  void cleanup() {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => now.isAfter(entry.expiry));
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiry;

  _CacheEntry({required this.value, required this.expiry});
}
