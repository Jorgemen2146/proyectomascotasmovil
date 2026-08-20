import 'package:flutter/material.dart';

import '../network/gateway_url_resolver.dart';
import '../theme/app_colors.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolved = GatewayUrlResolver.resolve(url);
    final image = resolved.isEmpty
        ? _placeholder()
        : Image.network(
            resolved,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, _, _) => _placeholder(),
          );
    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: AppColors.primary.withValues(alpha: 0.08),
    alignment: Alignment.center,
    child: const Icon(Icons.pets, color: AppColors.primary, size: 36),
  );
}
