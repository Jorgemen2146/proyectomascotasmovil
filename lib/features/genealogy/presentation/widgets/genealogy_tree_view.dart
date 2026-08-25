import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/network/gateway_url_resolver.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/genealogy.dart';

class GenealogyNodeSelection {
  const GenealogyNodeSelection({
    required this.pet,
    required this.generation,
    this.relationshipId,
    this.role,
    this.parents = const [],
  });
  final GenealogyPetNode pet;
  final int generation;
  final String? relationshipId;
  final GenealogyParentRole? role;
  final List<GenealogyParentNode> parents;
}

class GenealogyTreeView extends StatefulWidget {
  const GenealogyTreeView({
    super.key,
    required this.tree,
    required this.generations,
    required this.onNodeTap,
    required this.onAddParent,
  });
  final GenealogyTree tree;
  final int generations;
  final ValueChanged<GenealogyNodeSelection> onNodeTap;
  final ValueChanged<GenealogyParentRole> onAddParent;
  @override
  State<GenealogyTreeView> createState() => _State();
}

class _State extends State<GenealogyTreeView> {
  final controller = ScrollController();
  double? lastWidth;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levels = _levels(widget.tree, widget.generations);
    return LayoutBuilder(
      builder: (context, c) {
        final width = math.max(c.maxWidth, levels.last.length * 136.0);
        final height = levels.length * 158.0 - 24;
        _center(width, c.maxWidth);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .025),
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.primary.withValues(alpha: .1)),
          ),
          child: SingleChildScrollView(
            key: const Key('genealogyTreeHorizontalScroll'),
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _Lines(levels, width)),
                  ),
                  for (final (li, level) in levels.indexed)
                    for (final (si, node) in level.indexed)
                      if (node != null)
                        Positioned(
                          left: _left(width, level.length, si),
                          top: li * 158 + 12,
                          child: _Card(
                            selection: node,
                            onTap: () => widget.onNodeTap(node),
                          ),
                        )
                      else if (li == 1)
                        Positioned(
                          left: _left(width, level.length, si),
                          top: li * 158 + 12,
                          child: _Add(
                            role: si == 0
                                ? GenealogyParentRole.father
                                : GenealogyParentRole.mother,
                            onTap: widget.onAddParent,
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _center(double width, double viewport) {
    if (lastWidth == width) return;
    lastWidth = width;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      controller.jumpTo(
        ((width - viewport) / 2)
            .clamp(0, controller.position.maxScrollExtent)
            .toDouble(),
      );
    });
  }

  static double _left(double width, int slots, int index) =>
      (width / slots) * (index + .5) - 56;
}

class _Card extends StatelessWidget {
  const _Card({required this.selection, required this.onTap});
  final GenealogyNodeSelection selection;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = selection.pet;
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        key: Key('genealogyNode-${p.petId}'),
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          width: 112,
          height: 118,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: selection.generation == 0
                  ? AppColors.primary
                  : AppColors.border,
              width: selection.generation == 0 ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              ClipOval(
                child: AppNetworkImage(
                  url: GatewayUrlResolver.resolve(p.mainPhotoUrl),
                  width: 42,
                  height: 42,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _sex(p.sex),
                style: AppTypography.caption.copyWith(fontSize: 10),
              ),
              Text(
                p.breedName ?? 'Raza no disponible',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Add extends StatelessWidget {
  const _Add({required this.role, required this.onTap});
  final GenealogyParentRole role;
  final ValueChanged<GenealogyParentRole> onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: AppRadius.mdAll,
    child: InkWell(
      key: Key('add-${role.name}'),
      onTap: () => onTap(role),
      child: Container(
        width: 112,
        height: 118,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.primary.withValues(alpha: .45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_circle_outline, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              'Agregar ${role == GenealogyParentRole.father ? 'padre' : 'madre'}',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Lines extends CustomPainter {
  const _Lines(this.levels, this.width);
  final List<List<GenealogyNodeSelection?>> levels;
  final double width;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: .38)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var l = 0; l < levels.length - 1; l++) {
      for (var i = 0; i < levels[l].length; i++) {
        if (levels[l][i] == null) continue;
        final px = (width / levels[l].length) * (i + .5), py = l * 158 + 130.0;
        for (final ci in [i * 2, i * 2 + 1]) {
          if (levels[l + 1][ci] == null && l != 0) continue;
          final cx = (width / levels[l + 1].length) * (ci + .5),
              cy = (l + 1) * 158 + 12.0,
              m = (py + cy) / 2;
          canvas.drawPath(
            Path()
              ..moveTo(px, py)
              ..lineTo(px, m)
              ..lineTo(cx, m)
              ..lineTo(cx, cy),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Lines old) =>
      old.levels != levels || old.width != width;
}

List<List<GenealogyNodeSelection?>> _levels(
  GenealogyTree tree,
  int generations,
) {
  final root = GenealogyNodeSelection(
    pet: tree.pet,
    generation: 0,
    parents: tree.parents,
  );
  final levels = <List<GenealogyNodeSelection?>>[
    [root],
  ];
  for (var g = 1; g <= generations; g++) {
    final next = <GenealogyNodeSelection?>[];
    for (final node in levels.last) {
      for (final role in GenealogyParentRole.values) {
        GenealogyParentNode? found;
        if (node != null) {
          for (final p in node.parents) {
            if (p.parentRole == role) {
              found = p;
              break;
            }
          }
        }
        next.add(
          found == null
              ? null
              : GenealogyNodeSelection(
                  pet: found.pet,
                  generation: g,
                  relationshipId: found.relationshipId,
                  role: found.parentRole,
                  parents: found.parents,
                ),
        );
      }
    }
    levels.add(next);
  }
  return levels;
}

String _sex(String s) => switch (s.toUpperCase()) {
  'M' || 'MALE' => 'Macho',
  'F' || 'FEMALE' => 'Hembra',
  _ => s,
};
