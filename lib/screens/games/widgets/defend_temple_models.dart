/// Data models for the Defend the Temple game.
class DemonWord {
  final String word;
  double x; // 0.0 – 1.0 fraction of width
  double y; // 0.0 – 1.0 fraction of height (0 = top)
  final double speed; // fraction of height per second
  final int colorIndex;

  DemonWord({
    required this.word,
    required this.x,
    required this.y,
    required this.speed,
    required this.colorIndex,
  });
}

class TempleGhost {
  final String word;
  final double x;
  final double y;
  final bool success;
  final int colorIndex;

  TempleGhost({
    required this.word,
    required this.x,
    required this.y,
    required this.success,
    required this.colorIndex,
  });
}

/// A trishul projectile flying from the temple up to a demon.
class Trishul {
  final double targetX; // fraction 0..1
  final double targetY; // fraction 0..1
  final DateTime spawnTime;
  static const duration = Duration(milliseconds: 650);

  Trishul({required this.targetX, required this.targetY})
      : spawnTime = DateTime.now();

  /// 0.0 = just spawned at temple, 1.0 = reached target.
  double get progress =>
      (DateTime.now().difference(spawnTime).inMilliseconds /
          duration.inMilliseconds)
          .clamp(0.0, 1.0);

  bool get done => progress >= 1.0;
}
