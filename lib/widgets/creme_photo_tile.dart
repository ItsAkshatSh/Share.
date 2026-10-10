import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'resilient_image.dart';

/// A photo tile in the "More from …" strip and album grids — the image is
/// shown at [aspect] (width/height, <1 = portrait like the reference), with a
/// press-scale and an optional tap-through.
class PhotoTile extends StatelessWidget {
  final String imageUrl;
  final double aspect;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const PhotoTile({
    super.key,
    required this.imageUrl,
    this.aspect = 0.82,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: aspect,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: AppColors.surfaceRaised,
            boxShadow: AppColors.shadow(blur: 14, y: 5, alpha: 0.10),
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: ResilientImage(source: imageUrl, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
