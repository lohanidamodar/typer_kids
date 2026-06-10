// ─────────────────────────────────────────────────────────────────────────────
// Data models for the Word Bubbles game
// ─────────────────────────────────────────────────────────────────────────────

class Bubble {
  final String word;
  double x; // fraction 0..1
  double y; // fraction 0..1
  final int colorIndex;
  double life; // seconds remaining before it fades
  final double maxLife;

  Bubble({
    required this.word,
    required this.x,
    required this.y,
    required this.colorIndex,
    required this.life,
  }) : maxLife = life;

  double get opacity => (life / maxLife).clamp(0.4, 1.0);
}

class WordBubblesGhost {
  final String word;
  final double x;
  final double y;
  final bool success;
  final int colorIndex;
  WordBubblesGhost(this.word, this.x, this.y, this.success, this.colorIndex);
}
