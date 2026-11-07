import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.icon = Icons.image_outlined,
    this.iconSize = 34,
  });

  final String? source;
  final BoxFit fit;
  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final path = source;
    if (path == null || path.isEmpty) return _placeholder();

    if (path.startsWith('data:image/')) {
      final separator = path.indexOf(',');
      if (separator < 0 || !path.substring(0, separator).endsWith(';base64')) {
        return _placeholder();
      }
      try {
        return Image.memory(
          base64Decode(path.substring(separator + 1)),
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        );
      } on FormatException {
        return _placeholder();
      }
    }

    final uri = Uri.tryParse(path);
    final isNetworkImage =
        uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    final imageProvider =
        isNetworkImage ? NetworkImage(path) as ImageProvider : AssetImage(path);

    return Image(
      image: imageProvider,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.primaryLight,
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: AppColors.primaryDark),
      );
}
