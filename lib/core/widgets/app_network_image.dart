import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/gateway_url_resolver.dart';
import '../network/network_providers.dart';
import '../theme/app_colors.dart';

class AppNetworkImage extends ConsumerStatefulWidget {
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
  ConsumerState<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends ConsumerState<AppNetworkImage> {
  Future<Map<String, String>>? _gatewayHeaders;

  @override
  void initState() {
    super.initState();
    _prepareHeaders();
  }

  @override
  void didUpdateWidget(covariant AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _prepareHeaders();
  }

  void _prepareHeaders() {
    _gatewayHeaders = GatewayUrlResolver.isGatewayUrl(widget.url)
        ? _readGatewayHeaders()
        : null;
  }

  Future<Map<String, String>> _readGatewayHeaders() async {
    final token = await ref.read(secureTokenStorageProvider).readAccessToken();
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  @override
  Widget build(BuildContext context) {
    final resolved = GatewayUrlResolver.resolve(widget.url);
    if (resolved.isEmpty) return _decorate(_placeholder());

    final headers = _gatewayHeaders;
    if (headers == null) return _decorate(_image(resolved));
    return FutureBuilder<Map<String, String>>(
      future: headers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _decorate(_placeholder());
        return _decorate(_image(resolved, headers: snapshot.data));
      },
    );
  }

  Widget _image(String resolved, {Map<String, String>? headers}) =>
      Image.network(
        resolved,
        headers: headers,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (_, _, _) => _placeholder(),
      );

  Widget _decorate(Widget child) => widget.borderRadius == null
      ? child
      : ClipRRect(borderRadius: widget.borderRadius!, child: child);

  Widget _placeholder() => Container(
    width: widget.width,
    height: widget.height,
    color: AppColors.primary.withValues(alpha: 0.08),
    alignment: Alignment.center,
    child: const Icon(Icons.pets, color: AppColors.primary, size: 36),
  );
}
