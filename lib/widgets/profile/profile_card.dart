import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/profile.dart';

/// Selectable profile row on the profile picker screen, with the number-key
/// shortcut badge and an optional delete button.
class ProfileCard extends StatelessWidget {
  final Profile profile;
  final int index;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.index,
    required this.isActive,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? AppColors.primary : Colors.grey.shade300,
                width: isActive ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: isActive ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      profile.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Name + info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isActive)
                        Text(
                          'Currently active',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                // Delete
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                    tooltip: 'Delete profile',
                  ),
                // Shortcut badge
                if (index <= 9)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '$index',
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isActive ? AppColors.primary : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
