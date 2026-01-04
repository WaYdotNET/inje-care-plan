import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/core/utils/performance_utils.dart';

void main() {
  group('PerformanceUtils.shouldDebounce', () {
    test('returns false on first call', () {
      final result = PerformanceUtils.shouldDebounce(
        'test_key_1',
        const Duration(seconds: 1),
      );
      expect(result, false);
    });

    test('returns true on rapid subsequent calls', () {
      // First call
      PerformanceUtils.shouldDebounce(
        'test_key_2',
        const Duration(seconds: 1),
      );

      // Immediate second call
      final result = PerformanceUtils.shouldDebounce(
        'test_key_2',
        const Duration(seconds: 1),
      );
      expect(result, true);
    });

    test('returns false after duration has passed', () async {
      // First call
      PerformanceUtils.shouldDebounce(
        'test_key_3',
        const Duration(milliseconds: 50),
      );

      // Wait for duration to pass
      await Future<void>.delayed(const Duration(milliseconds: 60));

      // Second call after duration
      final result = PerformanceUtils.shouldDebounce(
        'test_key_3',
        const Duration(milliseconds: 50),
      );
      expect(result, false);
    });
  });

  group('PerformanceUtils.shouldThrottle', () {
    test('returns false on first call', () {
      final result = PerformanceUtils.shouldThrottle(
        'throttle_key_1',
        const Duration(seconds: 1),
      );
      expect(result, false);
    });

    test('returns true on rapid subsequent calls', () {
      // First call
      PerformanceUtils.shouldThrottle(
        'throttle_key_2',
        const Duration(seconds: 1),
      );

      // Immediate second call
      final result = PerformanceUtils.shouldThrottle(
        'throttle_key_2',
        const Duration(seconds: 1),
      );
      expect(result, true);
    });
  });

  group('PerformanceUtils.lazyInit', () {
    test('creates value on first call', () {
      var callCount = 0;
      final result = PerformanceUtils.lazyInit('lazy_1', () {
        callCount++;
        return 'value';
      });

      expect(result, 'value');
      expect(callCount, 1);
    });

    test('returns cached value on subsequent calls', () {
      var callCount = 0;
      // First call
      PerformanceUtils.lazyInit('lazy_2', () {
        callCount++;
        return 'value';
      });

      // Second call
      final result = PerformanceUtils.lazyInit('lazy_2', () {
        callCount++;
        return 'new_value';
      });

      expect(result, 'value');
      expect(callCount, 1);
    });

    test('clearLazyCache removes specific key', () {
      PerformanceUtils.lazyInit('lazy_3', () => 'original');
      PerformanceUtils.clearLazyCache('lazy_3');

      final result = PerformanceUtils.lazyInit('lazy_3', () => 'new');
      expect(result, 'new');
    });

    test('clearLazyCache without key clears all', () {
      PerformanceUtils.lazyInit('lazy_4', () => 'a');
      PerformanceUtils.lazyInit('lazy_5', () => 'b');

      PerformanceUtils.clearLazyCache();

      final result1 = PerformanceUtils.lazyInit('lazy_4', () => 'new_a');
      final result2 = PerformanceUtils.lazyInit('lazy_5', () => 'new_b');

      expect(result1, 'new_a');
      expect(result2, 'new_b');
    });
  });

  group('PerformanceUtils.memoize', () {
    test('caches computed result', () {
      var computeCount = 0;
      final result = PerformanceUtils.memoize('memo_1', () {
        computeCount++;
        return 42;
      });

      expect(result, 42);
      expect(computeCount, 1);

      // Second call should use cache
      final result2 = PerformanceUtils.memoize('memo_1', () {
        computeCount++;
        return 100;
      });

      expect(result2, 42);
      expect(computeCount, 1);
    });

    test('invalidateMemo removes cached value', () {
      PerformanceUtils.memoize('memo_2', () => 'original');
      PerformanceUtils.invalidateMemo('memo_2');

      final result = PerformanceUtils.memoize('memo_2', () => 'new');
      expect(result, 'new');
    });
  });

  group('PerformanceUtils.batchAsync', () {
    test('processes all operations', () async {
      final operations = [
        () async => 1,
        () async => 2,
        () async => 3,
        () async => 4,
        () async => 5,
      ];

      final results = await PerformanceUtils.batchAsync(operations);

      expect(results, [1, 2, 3, 4, 5]);
    });

    test('respects concurrency limit', () async {
      var maxConcurrent = 0;
      var currentConcurrent = 0;

      final operations = List.generate(6, (i) {
        return () async {
          currentConcurrent++;
          if (currentConcurrent > maxConcurrent) {
            maxConcurrent = currentConcurrent;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
          currentConcurrent--;
          return i;
        };
      });

      await PerformanceUtils.batchAsync(operations, concurrency: 2);

      expect(maxConcurrent, 2);
    });
  });

  group('LazyLoader', () {
    test('isLoaded returns false initially', () {
      final loader = LazyLoader(() async => 'value');
      expect(loader.isLoaded, false);
    });

    test('valueOrNull returns null initially', () {
      final loader = LazyLoader(() async => 'value');
      expect(loader.valueOrNull, null);
    });

    test('load returns value and sets isLoaded', () async {
      final loader = LazyLoader(() async => 'value');

      final result = await loader.load();

      expect(result, 'value');
      expect(loader.isLoaded, true);
      expect(loader.valueOrNull, 'value');
    });

    test('load returns cached value on subsequent calls', () async {
      var loadCount = 0;
      final loader = LazyLoader(() async {
        loadCount++;
        return 'value';
      });

      await loader.load();
      await loader.load();

      expect(loadCount, 1);
    });

    test('invalidate clears cached value', () async {
      var loadCount = 0;
      final loader = LazyLoader(() async {
        loadCount++;
        return 'value$loadCount';
      });

      await loader.load();
      loader.invalidate();

      expect(loader.isLoaded, false);

      final result = await loader.load();
      expect(result, 'value2');
    });
  });

  group('PaginatedList extension', () {
    test('paginate returns correct page', () {
      final list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

      expect(list.paginate(page: 0, pageSize: 3), [1, 2, 3]);
      expect(list.paginate(page: 1, pageSize: 3), [4, 5, 6]);
      expect(list.paginate(page: 2, pageSize: 3), [7, 8, 9]);
      expect(list.paginate(page: 3, pageSize: 3), [10]);
    });

    test('paginate returns empty for out of range page', () {
      final list = [1, 2, 3];

      expect(list.paginate(page: 5, pageSize: 3), isEmpty);
    });

    test('chunk divides list correctly', () {
      final list = [1, 2, 3, 4, 5, 6, 7];

      final chunks = list.chunk(3);

      expect(chunks.length, 3);
      expect(chunks[0], [1, 2, 3]);
      expect(chunks[1], [4, 5, 6]);
      expect(chunks[2], [7]);
    });

    test('chunk with empty list returns empty', () {
      final list = <int>[];
      expect(list.chunk(3), isEmpty);
    });
  });

  group('MemoryCache', () {
    test('get returns null for non-existent key', () {
      final cache = MemoryCache<String>();
      expect(cache.get('unknown'), null);
    });

    test('set and get returns cached value', () {
      final cache = MemoryCache<String>();
      cache.set('key', 'value');
      expect(cache.get('key'), 'value');
    });

    test('get returns null after TTL expires', () async {
      final cache = MemoryCache<String>(ttl: const Duration(milliseconds: 50));
      cache.set('key', 'value');

      // Before expiry
      expect(cache.get('key'), 'value');

      // Wait for TTL
      await Future<void>.delayed(const Duration(milliseconds: 60));

      // After expiry
      expect(cache.get('key'), null);
    });

    test('remove clears specific key', () {
      final cache = MemoryCache<String>();
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');

      cache.remove('key1');

      expect(cache.get('key1'), null);
      expect(cache.get('key2'), 'value2');
    });

    test('clear removes all entries', () {
      final cache = MemoryCache<String>();
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');

      cache.clear();

      expect(cache.get('key1'), null);
      expect(cache.get('key2'), null);
    });

    test('cleanup removes expired entries', () async {
      final cache = MemoryCache<String>(ttl: const Duration(milliseconds: 50));
      cache.set('short', 'value', const Duration(milliseconds: 50));
      cache.set('long', 'value', const Duration(seconds: 10));

      await Future<void>.delayed(const Duration(milliseconds: 60));

      cache.cleanup();

      expect(cache.get('short'), null);
      expect(cache.get('long'), 'value');
    });
  });
}
