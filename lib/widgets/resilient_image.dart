import 'dart:io';

import 'package:flutter/material.dart';

/// Images that don't take the app down when the network wobbles: a source
/// that may be an https URL, a local file path, or an asset — rendered with a
/// muted placeholder and a_cross-fade, plus optional caching behaviour.
class ResilientImage extends StatelessWidget {
  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ResilientImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) return _placeholder();
    final provider = _providerFor(source);
    return Image(
      image: provider,
      fit: fit,
      width: width,
      height: height,
      frameBuilder: (context, child, frame, _) {
        if (frame == null) return _placeholder();
        return AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 160),
          child: child,
        );
      },
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  static ImageProvider<Object> _providerFor(String source) {
    if (source.startsWith('http')) {
      return NetworkImage(source);
    }
    if (source.startsWith('assets/')) {
      return AssetImage(source);
    }
    return FileImage(File(source));
  }

  static Widget _placeholder() => const ColoredBox(
        color: Color(0x1A16141C),
        child: Center(
          child: Icon(Icons.image_outlined, size: 22, color: Color(0x5516141C)),
        ),
      );
}

/// The circle variant — avatars that survive a missing URL with a painted
/// initial instead of a broken image.
class ResilientAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const ResilientAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage:
          imageUrl.isEmpty ? null : ResilientImage._providerFor(imageUrl),
      backgroundColor: const Color(0xFFD9D2EA),
      onBackgroundImageError: imageUrl.isEmpty ? null : (_, _) {},
      child: imageUrl.isEmpty
          ? Icon(Icons.person_rounded,
              size: radius * 0.9, color: const Color(0xFF9B98A3))
          : null,
    );
  }
}

/// A lighter avatar for dense rows (menus, attendee strips) — same torn-free
/// behaviour, no cross-fade or error glyphs.
class ResilientAvatarLite extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const ResilientAvatarLite({
    super.key,
    required this.imageUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage:
          imageUrl.isEmpty ? null : ResilientImage._providerFor(imageUrl),
      backgroundColor: const Color(0xFFD9D2EA),
    );
  }
}

/// A lighter image (thumbnails inside cards) — same resilient source
/// handling, cheaper decoration.
class ResilientImageLite extends StatelessWidget {
  final String source;
  final BoxFit fit;

  const ResilientImageLite({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) {
      return const ColoredBox(color: Color(0xFF2A2830));
    }
    return Image(
      image: ResilientImage._providerFor(source),
      fit: fit,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFF2A2830),
        child: Center(
          child: Icon(Icons.image_outlined, size: 20, color: Color(0x55FFFFFF)),
        ),
      ),
    );
  }
}
