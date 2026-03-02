// ignore_for_file: avoid_print
/// Generates CC0 game sound effects as WAV files for Typer Kids.
/// Run: dart run tool/generate_sfx.dart
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 44100;
const int bitsPerSample = 16;

void main() {
  final dir = Directory('assets/sounds');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // 1. Correct / success - bright rising two-tone chime
  _writeWav('assets/sounds/correct.wav', _generateCorrect());
  print('✓ correct.wav');

  // 2. Wrong / error - low buzzer
  _writeWav('assets/sounds/wrong.wav', _generateWrong());
  print('✓ wrong.wav');

  // 3. Pop - quick bubble pop
  _writeWav('assets/sounds/pop.wav', _generatePop());
  print('✓ pop.wav');

  // 4. Miss - descending whoosh
  _writeWav('assets/sounds/miss.wav', _generateMiss());
  print('✓ miss.wav');

  // 5. Game start - ascending fanfare
  _writeWav('assets/sounds/game_start.wav', _generateGameStart());
  print('✓ game_start.wav');

  // 6. Game over - ending tone
  _writeWav('assets/sounds/game_over.wav', _generateGameOver());
  print('✓ game_over.wav');

  // 7. Streak - bonus sparkle
  _writeWav('assets/sounds/streak.wav', _generateStreak());
  print('✓ streak.wav');

  // 8. Keystroke - soft click
  _writeWav('assets/sounds/keystroke.wav', _generateKeystroke());
  print('✓ keystroke.wav');

  print('\nAll sound effects generated in assets/sounds/');
}

/// Write 16-bit mono PCM WAV
void _writeWav(String path, List<double> samples) {
  final numSamples = samples.length;
  final dataSize = numSamples * 2; // 16-bit = 2 bytes per sample
  final fileSize = 36 + dataSize;

  final bytes = ByteData(44 + dataSize);
  int offset = 0;

  // RIFF header
  void writeStr(String s) {
    for (int i = 0; i < s.length; i++) {
      bytes.setUint8(offset++, s.codeUnitAt(i));
    }
  }

  writeStr('RIFF');
  bytes.setUint32(offset, fileSize, Endian.little);
  offset += 4;
  writeStr('WAVE');

  // fmt chunk
  writeStr('fmt ');
  bytes.setUint32(offset, 16, Endian.little);
  offset += 4; // chunk size
  bytes.setUint16(offset, 1, Endian.little);
  offset += 2; // PCM
  bytes.setUint16(offset, 1, Endian.little);
  offset += 2; // mono
  bytes.setUint32(offset, sampleRate, Endian.little);
  offset += 4;
  bytes.setUint32(offset, sampleRate * 2, Endian.little);
  offset += 4; // byte rate
  bytes.setUint16(offset, 2, Endian.little);
  offset += 2; // block align
  bytes.setUint16(offset, bitsPerSample, Endian.little);
  offset += 2;

  // data chunk
  writeStr('data');
  bytes.setUint32(offset, dataSize, Endian.little);
  offset += 4;

  // Write samples
  for (final s in samples) {
    final clamped = s.clamp(-1.0, 1.0);
    final intVal = (clamped * 32767).round().clamp(-32768, 32767);
    bytes.setInt16(offset, intVal, Endian.little);
    offset += 2;
  }

  File(path).writeAsBytesSync(bytes.buffer.asUint8List());
}

// ── Sound generators ──

/// Bright rising two-tone (C6 → E6), 200ms
List<double> _generateCorrect() {
  final dur = 0.2;
  final n = (sampleRate * dur).round();
  final samples = List<double>.filled(n, 0);
  // Two overlapping notes
  for (int i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = _envelope(t, dur, 0.01, 0.05);
    // C6 = 1047 Hz, then E6 = 1319 Hz (transition midway)
    final progress = i / n;
    final freq = 1047 + (1319 - 1047) * progress;
    samples[i] = env * 0.5 * sin(2 * pi * freq * t);
    // Add a harmonic
    samples[i] += env * 0.2 * sin(2 * pi * freq * 2 * t);
  }
  return samples;
}

/// Low buzzer, 250ms
List<double> _generateWrong() {
  final dur = 0.25;
  final n = (sampleRate * dur).round();
  final samples = List<double>.filled(n, 0);
  for (int i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = _envelope(t, dur, 0.005, 0.1);
    // 150 Hz sawtooth-ish buzz
    final phase = (150 * t) % 1.0;
    samples[i] = env * 0.4 * (2 * phase - 1);
    // Add lower rumble
    samples[i] += env * 0.2 * sin(2 * pi * 100 * t);
  }
  return samples;
}

/// Quick pop, 80ms
List<double> _generatePop() {
  final dur = 0.08;
  final n = (sampleRate * dur).round();
  final samples = List<double>.filled(n, 0);
  final rng = Random(42);
  for (int i = 0; i < n; i++) {
    final t = i / sampleRate;
    // Fast exponential decay
    final env = exp(-t * 60);
    // Pitched click at ~800 Hz + noise burst
    samples[i] = env * 0.6 * sin(2 * pi * 800 * t);
    samples[i] += env * 0.3 * (rng.nextDouble() * 2 - 1);
  }
  return samples;
}

/// Descending whoosh, 300ms
List<double> _generateMiss() {
  final dur = 0.3;
  final n = (sampleRate * dur).round();
  final samples = List<double>.filled(n, 0);
  for (int i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = _envelope(t, dur, 0.01, 0.15);
    // Descending from 600 Hz → 200 Hz
    final progress = i / n;
    final freq = 600 - 400 * progress;
    samples[i] = env * 0.4 * sin(2 * pi * freq * t);
  }
  return samples;
}

/// Ascending fanfare, 500ms (C5→E5→G5)
List<double> _generateGameStart() {
  final dur = 0.5;
  final n = (sampleRate * dur).round();
  final samples = List<double>.filled(n, 0);
  final notes = [523.25, 659.25, 783.99]; // C5, E5, G5
  final noteDur = dur / notes.length;
  for (int noteIdx = 0; noteIdx < notes.length; noteIdx++) {
    final startSample = (noteIdx * noteDur * sampleRate).round();
    final endSample = ((noteIdx + 1) * noteDur * sampleRate).round().clamp(
      0,
      n,
    );
    for (int i = startSample; i < endSample; i++) {
      final localT = (i - startSample) / sampleRate;
      final env = _envelope(localT, noteDur, 0.005, 0.05);
      samples[i] = env * 0.4 * sin(2 * pi * notes[noteIdx] * localT);
      samples[i] += env * 0.15 * sin(2 * pi * notes[noteIdx] * 2 * localT);
    }
  }
  return samples;
}

/// Ending tone - descending arpeggio, 600ms
List<double> _generateGameOver() {
  final dur = 0.6;
  final n = (sampleRate * dur).round();
  final samples = List<double>.filled(n, 0);
  final notes = [783.99, 659.25, 523.25, 392.0]; // G5, E5, C5, G4
  final noteDur = dur / notes.length;
  for (int noteIdx = 0; noteIdx < notes.length; noteIdx++) {
    final startSample = (noteIdx * noteDur * sampleRate).round();
    final endSample = ((noteIdx + 1) * noteDur * sampleRate).round().clamp(
      0,
      n,
    );
    for (int i = startSample; i < endSample; i++) {
      final localT = (i - startSample) / sampleRate;
      final env = _envelope(localT, noteDur, 0.005, 0.06);
      samples[i] = env * 0.35 * sin(2 * pi * notes[noteIdx] * localT);
      samples[i] += env * 0.12 * sin(2 * pi * notes[noteIdx] * 2 * localT);
    }
  }
  return samples;
}

/// Bonus sparkle, 150ms (high pitched shimmer)
List<double> _generateStreak() {
  final dur = 0.15;
  final n = (sampleRate * dur).round();
  final samples = List<double>.filled(n, 0);
  for (int i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = _envelope(t, dur, 0.003, 0.05);
    // Two high tones creating a shimmery sound
    samples[i] = env * 0.35 * sin(2 * pi * 2093 * t); // C7
    samples[i] += env * 0.25 * sin(2 * pi * 2637 * t); // E7
    samples[i] += env * 0.15 * sin(2 * pi * 3136 * t); // G7
  }
  return samples;
}

/// Soft key click, 30ms
List<double> _generateKeystroke() {
  final dur = 0.03;
  final n = (sampleRate * dur).round();
  final samples = List<double>.filled(n, 0);
  final rng = Random(7);
  for (int i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = exp(-t * 150);
    // Soft click: filtered noise + tiny ping
    samples[i] = env * 0.25 * (rng.nextDouble() * 2 - 1);
    samples[i] += env * 0.2 * sin(2 * pi * 1200 * t);
  }
  return samples;
}

/// ADSR-like envelope
double _envelope(double t, double dur, double attack, double release) {
  if (t < attack) return t / attack;
  if (t > dur - release) return ((dur - t) / release).clamp(0.0, 1.0);
  return 1.0;
}
