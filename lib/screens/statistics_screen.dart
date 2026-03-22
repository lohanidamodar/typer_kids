import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/progress_provider.dart';

/// Detailed statistics dashboard showing typing progress over time,
/// per-letter accuracy, and error-prone keys.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final maxW = isWide ? 900.0 : constraints.maxWidth;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 20,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        TextButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text(
                            'Back (Esc)',
                            style: GoogleFonts.fredoka(fontSize: 16),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Header
                        Center(
                          child: Column(
                            children: [
                              const Text('📊',
                                  style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 8),
                              Text(
                                'Your Statistics',
                                style: GoogleFonts.fredoka(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Overview Cards ──
                        _buildOverviewCards(progress, isWide),
                        const SizedBox(height: 24),

                        // ── WPM Progress Chart ──
                        _buildSectionTitle('Speed Progress (WPM)'),
                        const SizedBox(height: 12),
                        _buildWpmChart(progress),
                        const SizedBox(height: 24),

                        // ── Accuracy Progress Chart ──
                        _buildSectionTitle('Accuracy Progress'),
                        const SizedBox(height: 12),
                        _buildAccuracyChart(progress),
                        const SizedBox(height: 24),

                        // ── Error-Prone Letters ──
                        _buildSectionTitle('Letters That Need Practice'),
                        const SizedBox(height: 12),
                        _buildErrorProneLetters(progress),
                        const SizedBox(height: 24),

                        // ── Letter Accuracy Heatmap ──
                        _buildSectionTitle('Letter Accuracy'),
                        const SizedBox(height: 12),
                        _buildLetterHeatmap(progress),
                        const SizedBox(height: 24),

                        // ── Game High Scores ──
                        _buildSectionTitle('Game High Scores'),
                        const SizedBox(height: 12),
                        _buildHighScores(progress),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.fredoka(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  // ── Overview Cards ──

  Widget _buildOverviewCards(ProgressProvider progress, bool isWide) {
    final totalTime = progress.totalTypingTime;
    final timeStr = totalTime.inHours > 0
        ? '${totalTime.inHours}h ${totalTime.inMinutes % 60}m'
        : totalTime.inMinutes > 0
            ? '${totalTime.inMinutes}m ${totalTime.inSeconds % 60}s'
            : '${totalTime.inSeconds}s';

    final cards = [
      _OverviewData(
        'Lessons Done',
        '${progress.completedLessons}/${progress.totalLessons}',
        Icons.school_rounded,
        AppColors.primary,
      ),
      _OverviewData(
        'Total Stars',
        '${progress.totalStars}',
        Icons.star_rounded,
        const Color(0xFFFFB300),
      ),
      _OverviewData(
        'Avg Speed',
        progress.averageWpm > 0
            ? '${progress.averageWpm.toStringAsFixed(0)} WPM'
            : 'N/A',
        Icons.speed_rounded,
        AppColors.accent,
      ),
      _OverviewData(
        'Avg Accuracy',
        progress.averageAccuracy > 0
            ? '${progress.averageAccuracy.toStringAsFixed(1)}%'
            : 'N/A',
        Icons.gps_fixed_rounded,
        const Color(0xFF5C6BC0),
      ),
      _OverviewData(
        'Sessions',
        '${progress.totalSessions}',
        Icons.repeat_rounded,
        AppColors.secondary,
      ),
      _OverviewData(
        'Time Spent',
        timeStr,
        Icons.timer_rounded,
        const Color(0xFF26A69A),
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(child: _buildOverviewCard(cards[i])),
            if (i < cards.length - 1) const SizedBox(width: 10),
          ],
        ],
      );
    }

    // 2-column grid for narrow
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cards.map((d) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 60) / 2,
          child: _buildOverviewCard(d),
        );
      }).toList(),
    );
  }

  Widget _buildOverviewCard(_OverviewData data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(data.icon, color: data.color, size: 24),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: data.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── WPM Chart ──

  Widget _buildWpmChart(ProgressProvider progress) {
    final data = progress.wpmHistory;
    if (data.length < 2) {
      return _buildEmptyCard('Complete more lessons to see your speed progress.');
    }
    // Show last 30 data points
    final recent = data.length > 30 ? data.sublist(data.length - 30) : data;
    final maxVal = recent.reduce(max);
    final minVal = recent.reduce(min);

    return _buildChartCard(
      child: CustomPaint(
        size: const Size(double.infinity, 140),
        painter: _LineChartPainter(
          data: recent,
          maxVal: maxVal + 5,
          minVal: (minVal - 5).clamp(0, double.infinity),
          lineColor: AppColors.accent,
          fillColor: AppColors.accent.withValues(alpha: 0.1),
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Low: ${minVal.toStringAsFixed(0)} WPM',
            style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            'High: ${maxVal.toStringAsFixed(0)} WPM',
            style: GoogleFonts.nunito(fontSize: 12, color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  // ── Accuracy Chart ──

  Widget _buildAccuracyChart(ProgressProvider progress) {
    final data = progress.accuracyHistory;
    if (data.length < 2) {
      return _buildEmptyCard('Complete more lessons to see your accuracy progress.');
    }
    final recent = data.length > 30 ? data.sublist(data.length - 30) : data;

    return _buildChartCard(
      child: CustomPaint(
        size: const Size(double.infinity, 140),
        painter: _LineChartPainter(
          data: recent,
          maxVal: 100,
          minVal: recent.reduce(min).clamp(0, 100) - 5,
          lineColor: const Color(0xFF5C6BC0),
          fillColor: const Color(0xFF5C6BC0).withValues(alpha: 0.08),
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Low: ${recent.reduce(min).toStringAsFixed(1)}%',
            style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            'Avg: ${(recent.reduce((a, b) => a + b) / recent.length).toStringAsFixed(1)}%',
            style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF5C6BC0)),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({required Widget child, required Widget footer}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          child,
          const SizedBox(height: 8),
          footer,
        ],
      ),
    );
  }

  // ── Error-Prone Letters ──

  Widget _buildErrorProneLetters(ProgressProvider progress) {
    final errorLetters = progress.errorProneLetters;
    if (errorLetters.isEmpty) {
      return _buildEmptyCard('Keep typing to discover which letters need more practice.');
    }

    // Show top 10 most error-prone
    final top = errorLetters.take(10).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++) ...[
            _buildErrorRow(top[i].key, top[i].value, i),
            if (i < top.length - 1)
              const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorRow(String letter, double errorRate, int index) {
    final barColor = errorRate > 30
        ? AppColors.incorrect
        : errorRate > 15
            ? AppColors.secondary
            : AppColors.correct;
    final displayChar = letter == ' ' ? 'Space' : letter.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Letter badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: barColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                displayChar,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayChar,
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${errorRate.toStringAsFixed(1)}% errors',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: barColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: errorRate / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: barColor,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Letter Heatmap ──

  Widget _buildLetterHeatmap(ProgressProvider progress) {
    final stats = progress.letterStats;
    if (stats.isEmpty) {
      return _buildEmptyCard('Type more to see accuracy for each letter.');
    }

    const rows = [
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
      ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (final row in rows) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((ch) {
                final s = stats[ch];
                final correct = s?['correct'] ?? 0;
                final errors = s?['errors'] ?? 0;
                final total = correct + errors;
                final accuracy = total > 0 ? correct / total : -1.0;

                Color bgColor;
                if (accuracy < 0) {
                  bgColor = Colors.grey.shade200;
                } else if (accuracy >= 0.95) {
                  bgColor = AppColors.correct.withValues(alpha: 0.3);
                } else if (accuracy >= 0.85) {
                  bgColor = AppColors.correct.withValues(alpha: 0.15);
                } else if (accuracy >= 0.70) {
                  bgColor = AppColors.secondary.withValues(alpha: 0.2);
                } else {
                  bgColor = AppColors.incorrect.withValues(alpha: 0.25);
                }

                return Padding(
                  padding: const EdgeInsets.all(3),
                  child: Tooltip(
                    message: total > 0
                        ? '$ch: ${(accuracy * 100).toStringAsFixed(0)}% accuracy ($total typed)'
                        : '$ch: not typed yet',
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accuracy < 0
                              ? Colors.grey.shade300
                              : accuracy >= 0.85
                                  ? AppColors.correct.withValues(alpha: 0.4)
                                  : accuracy >= 0.70
                                      ? AppColors.secondary.withValues(alpha: 0.4)
                                      : AppColors.incorrect.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          ch.toUpperCase(),
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accuracy < 0
                                ? Colors.grey.shade400
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.grey.shade200, 'Not typed'),
              const SizedBox(width: 12),
              _legendDot(AppColors.incorrect.withValues(alpha: 0.25), '<70%'),
              const SizedBox(width: 12),
              _legendDot(AppColors.secondary.withValues(alpha: 0.2), '70-85%'),
              const SizedBox(width: 12),
              _legendDot(AppColors.correct.withValues(alpha: 0.15), '85-95%'),
              const SizedBox(width: 12),
              _legendDot(AppColors.correct.withValues(alpha: 0.3), '>95%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ── High Scores ──

  Widget _buildHighScores(ProgressProvider progress) {
    final scores = progress.allHighScores;
    if (scores.isEmpty) {
      return _buildEmptyCard('Play some games to see your high scores here.');
    }

    final gameNames = {
      'defend-temple-easy': 'Defend Temple (Easy)',
      'defend-temple-medium': 'Defend Temple (Medium)',
      'defend-temple-hard': 'Defend Temple (Hard)',
      'falling-words-easy': 'Falling Words (Easy)',
      'falling-words-medium': 'Falling Words (Medium)',
      'falling-words-hard': 'Falling Words (Hard)',
      'word-bubbles-easy': 'Word Bubbles (Easy)',
      'word-bubbles-medium': 'Word Bubbles (Medium)',
      'word-bubbles-hard': 'Word Bubbles (Hard)',
      'speed-chase-easy': 'Speed Chase (Easy)',
      'speed-chase-medium': 'Speed Chase (Medium)',
      'speed-chase-hard': 'Speed Chase (Hard)',
      'word-builder-easy': 'Word Builder (Easy)',
      'word-builder-medium': 'Word Builder (Medium)',
      'word-builder-hard': 'Word Builder (Hard)',
    };

    final sorted = scores.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return _buildEmptyCard('Play some games to see your high scores here.');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    i < 3
                        ? ['🥇', '🥈', '🥉'][i]
                        : '${i + 1}.',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      gameNames[sorted[i].key] ?? sorted[i].key,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${sorted[i].value}',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (i < sorted.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  // ── Empty state ──

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('📝', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data class
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewData(this.label, this.value, this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// Line chart painter
// ─────────────────────────────────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final double maxVal;
  final double minVal;
  final Color lineColor;
  final Color fillColor;

  _LineChartPainter({
    required this.data,
    required this.maxVal,
    required this.minVal,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final range = maxVal - minVal;
    if (range <= 0) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = lineColor;

    final path = Path();
    final fillPath = Path();

    final step = size.width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - ((data[i] - minVal) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Fill
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // Line
    canvas.drawPath(path, linePaint);

    // Dots for last 5 points
    final dotStart = max(0, data.length - 5);
    for (var i = dotStart; i < data.length; i++) {
      final x = i * step;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      data != old.data || lineColor != old.lineColor;
}
