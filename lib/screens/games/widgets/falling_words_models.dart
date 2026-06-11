/// A word falling down the screen in the Falling Words game.
class FallingWord {
  final String word;
  double x; // 0.0 – 1.0 (fraction of available width)
  double y; // 0.0 – 1.0 (fraction of available height, 0 = top)
  final double speed; // fraction of height per second
  final int colorIndex;

  FallingWord({
    required this.word,
    required this.x,
    required this.y,
    required this.speed,
    required this.colorIndex,
  });
}

/// Brief ghost left behind when a word is destroyed or missed.
class FallingWordsGhost {
  final String word;
  final double x;
  final double y;
  final bool success; // true = correct, false = wrong/miss
  final int colorIndex;

  FallingWordsGhost({
    required this.word,
    required this.x,
    required this.y,
    required this.success,
    required this.colorIndex,
  });
}
