/// Simple (in-session) resume store for the VOD playback position.
/// Next phase: always persisted via drift instead of memory.
class ResumeStore {
  ResumeStore._();
  static final instance = ResumeStore._();

  final Map<String, Duration> _positions = {};

  Duration? get(String id) => _positions[id];

  void save(String id, Duration position, Duration total) {
    // Don't save trivial starts or the end (treated as completed).
    if (total > Duration.zero &&
        position > const Duration(seconds: 10) &&
        position < total - const Duration(seconds: 15)) {
      _positions[id] = position;
    } else {
      _positions.remove(id);
    }
  }

  void clear(String id) => _positions.remove(id);
}
