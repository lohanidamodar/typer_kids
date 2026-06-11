import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/profile.dart';
import '../../providers/profile_provider.dart';

/// Dialog for creating a new profile (name + avatar picker).
/// Pops with the created [Profile], which is also set as active.
class CreateProfileDialog extends StatefulWidget {
  const CreateProfileDialog({super.key});

  @override
  State<CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<CreateProfileDialog> {
  final _nameController = TextEditingController();
  String _selectedEmoji = Profile.avatarOptions.first;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isCreating) return;
    setState(() => _isCreating = true);

    final profileProv = context.read<ProfileProvider>();
    final profile = await profileProv.createProfile(
      name: name,
      emoji: _selectedEmoji,
    );
    if (mounted) Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'New Profile',
        style: GoogleFonts.fredoka(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name input
            Text(
              'Your name',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.fredoka(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'e.g. Alex',
                hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 20),
            // Avatar picker
            Text(
              'Choose your avatar',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: Profile.avatarOptions.map((emoji) {
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 36)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.fredoka(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _create,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _isCreating ? 'Creating...' : 'Create',
            style: GoogleFonts.fredoka(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
