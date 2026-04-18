class TimedCache<K, V> {
  final Map<K, (V?, DateTime)> _cache = {};
  final Duration duration;

  TimedCache({required this.duration});

  V? get(K key) {
    if (!_cache.containsKey(key)) return null;

    final (value, timestamp) = _cache[key]!;
    if (DateTime.now().difference(timestamp) > duration) {
      _cache.remove(key);
      return null;
    }

    return value;
  }

  void set(K key, V? value) {
    _cache[key] = (value, DateTime.now());
  }

  void clear() => _cache.clear();
  void remove(K key) => _cache.remove(key);
}
