import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Animated star rating display (1-5 stars)
class StarRating extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double size;
  final bool animate;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 32,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final isFilled = index < rating;
        final star = Icon(
          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: isFilled ? AppColors.starFilled : AppColors.starEmpty,
          size: size,
        );

        if (animate && isFilled) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 200)),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: star,
          );
        }

        return star;
      }),
    );
  }
}
