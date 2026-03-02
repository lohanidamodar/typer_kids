import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/progress_provider.dart';

/// Simple settings screen for resetting progress and toggling options
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Stats overview
          _buildSectionHeader('Your Progress'),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            children: [
              _buildInfoRow(
                'Lessons Completed',
                '${progress.completedLessons}/${progress.totalLessons}',
              ),
              _buildInfoRow('Total Stars', '${progress.totalStars}'),
              _buildInfoRow(
                'Average Accuracy',
                progress.averageAccuracy > 0
                    ? '${progress.averageAccuracy.toStringAsFixed(1)}%'
                    : 'N/A',
              ),
              _buildInfoRow(
                'Average Speed',
                progress.averageWpm > 0
                    ? '${progress.averageWpm.toStringAsFixed(0)} WPM'
                    : 'N/A',
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Danger zone
          _buildSectionHeader('Danger Zone'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showResetDialog(context),
              icon: const Icon(Icons.delete_forever_rounded),
              label: Text(
                'Reset All Progress',
                style: GoogleFonts.fredoka(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.incorrect,
                side: const BorderSide(color: AppColors.incorrect),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // About
          _buildSectionHeader('About'),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            children: [
              _buildInfoRow('App', 'Typer Kids'),
              _buildInfoRow('Version', '1.0.0'),
              _buildInfoRow('Made with', '❤️ and Flutter'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.fredoka(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Text('Reset Progress?', style: GoogleFonts.fredoka(fontSize: 22)),
          ],
        ),
        content: Text(
          'This will erase all your stars, scores, and lesson progress. This cannot be undone!',
          style: GoogleFonts.nunito(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.fredoka(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<ProgressProvider>().resetAll();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Progress reset! Ready for a fresh start! 🌱',
                    style: GoogleFonts.nunito(),
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Text(
              'Reset',
              style: GoogleFonts.fredoka(color: AppColors.incorrect),
            ),
          ),
        ],
      ),
    );
  }
}
