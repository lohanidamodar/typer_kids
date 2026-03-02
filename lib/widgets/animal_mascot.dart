import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// An animated mascot widget that reacts to typing events
/// Shows different expressions based on typing accuracy
class AnimalMascot extends StatefulWidget {
  /// 'happy', 'thinking', 'wow', 'sad', 'celebrating'
  final String mood;
  final double size;

  const AnimalMascot({super.key, this.mood = 'happy', this.size = 80});

  @override
  State<AnimalMascot> createState() => _AnimalMascotState();
}

class _AnimalMascotState extends State<AnimalMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: _buildMascot(),
        );
      },
    );
  }

  Widget _buildMascot() {
    final (emoji, color) = switch (widget.mood) {
      'happy' => ('🐵', AppColors.primaryLight),
      'thinking' => ('🤔', AppColors.secondaryLight),
      'wow' => ('🙊', AppColors.starFilled),
      'sad' => ('🙈', AppColors.incorrect),
      'celebrating' => ('🎉', AppColors.starFilled),
      _ => ('🐵', AppColors.primaryLight),
    };

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: widget.size * 0.5)),
      ),
    );
  }
}
