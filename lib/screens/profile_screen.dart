import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/profile.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/profile/create_profile_dialog.dart';
import '../widgets/profile/profile_card.dart';

/// Screen for choosing or creating a profile
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.keyN) {
      _showCreateDialog();
    } else if (key == LogicalKeyboardKey.escape) {
      // Only allow going back if there's an active profile
      final profileProv = context.read<ProfileProvider>();
      if (profileProv.hasActiveProfile) {
        context.pop();
      }
    } else {
      // Number keys 1-9 to quickly select profiles
      final profiles = context.read<ProfileProvider>().profiles;
      final numberKeys = [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.digit6,
        LogicalKeyboardKey.digit7,
        LogicalKeyboardKey.digit8,
        LogicalKeyboardKey.digit9,
      ];
      final idx = numberKeys.indexOf(key);
      if (idx >= 0 && idx < profiles.length) {
        _selectProfile(profiles[idx]);
      }
    }
  }

  void _selectProfile(Profile profile) async {
    final profileProv = context.read<ProfileProvider>();
    final progressProv = context.read<ProgressProvider>();
    await profileProv.setActiveProfile(profile.id);
    await progressProv.switchProfile(profile.id);
    if (mounted) context.go('/');
  }

  void _deleteProfile(Profile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete ${profile.name}?',
                style: GoogleFonts.fredoka(fontSize: 22),
              ),
            ),
          ],
        ),
        content: Text(
          'All stars, scores, and lesson progress for this profile will be permanently deleted!',
          style: GoogleFonts.nunito(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.fredoka(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.fredoka(color: AppColors.incorrect),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final profileProv = context.read<ProfileProvider>();
      final progressProv = context.read<ProgressProvider>();
      await profileProv.deleteProfile(profile.id);
      // If there's still an active profile, load its data
      if (profileProv.hasActiveProfile) {
        await progressProv.switchProfile(profileProv.activeProfileId!);
      }
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const CreateProfileDialog(),
    ).then((result) async {
      if (result != null && result is Profile && mounted) {
        // Profile was created and set as active inside the dialog
        final progressProv = context.read<ProgressProvider>();
        await progressProv.switchProfile(result.id);
        if (mounted) context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProv = context.watch<ProfileProvider>();
    final profiles = profileProv.profiles;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Text('🐵', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(
                      'Who\'s Typing?',
                      style: GoogleFonts.fredoka(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose your profile or create a new one',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Existing profiles (number keys 1-9 to select)
                    if (profiles.isNotEmpty) ...[
                      ...profiles.asMap().entries.map(
                        (entry) => ProfileCard(
                          profile: entry.value,
                          index: entry.key + 1,
                          isActive:
                              entry.value.id == profileProv.activeProfileId,
                          onTap: () => _selectProfile(entry.value),
                          onDelete: profiles.length > 1
                              ? () => _deleteProfile(entry.value)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Create new profile button
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: OutlinedButton.icon(
                        onPressed: _showCreateDialog,
                        icon: const Icon(Icons.add_rounded, size: 28),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'New Profile',
                              style: GoogleFonts.fredoka(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                'N',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Back button (only if there's an active profile)
                    if (profileProv.hasActiveProfile) ...[
                      TextButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Back',
                              style: GoogleFonts.fredoka(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Esc',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
