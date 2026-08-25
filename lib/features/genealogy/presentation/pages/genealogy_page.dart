import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/gateway_url_resolver.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../pets/application/providers.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../application/providers.dart';
import '../../domain/entities/genealogy.dart';
import '../widgets/genealogy_tree_view.dart';

class GenealogyPage extends ConsumerStatefulWidget {
  const GenealogyPage({super.key, this.initialPetId});
  final String? initialPetId;
  @override
  ConsumerState<GenealogyPage> createState() => _State();
}

class _State extends ConsumerState<GenealogyPage> {
  String? selected;
  int generations = 3;
  @override
  void initState() {
    super.initState();
    selected = widget.initialPetId;
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(myPetsProvider);
    final mutating = ref.watch(genealogyControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Árbol genealógico'),
        actions: [
          IconButton(
            key: const Key('genealogyInvitationsButton'),
            tooltip: 'Solicitudes',
            icon: const Icon(Icons.mail_outline),
            onPressed: () => context.push(AppRoutes.genealogyInvitations),
          ),
        ],
      ),
      body: SafeArea(
        child: petsAsync.when(
          loading: () => const AppLoadingIndicator(),
          error: (_, _) => ErrorState(
            title: 'No pudimos cargar tus mascotas',
            message: 'Revisa tu conexión.',
            onRetry: () => ref.invalidate(myPetsProvider),
          ),
          data: (pets) {
            if (pets.isEmpty) {
              return const EmptyState(
                icon: Icons.account_tree_outlined,
                title: 'Aún no tienes mascotas',
                message: 'Agrega una mascota para empezar.',
              );
            }
            final id = pets.any((p) => p.id == selected)
                ? selected!
                : pets.first.id;
            final q = (petId: id, generations: generations);
            final async = ref.watch(genealogyTreeProvider(q));
            return RefreshIndicator(
              onRefresh: () => ref.refresh(genealogyTreeProvider(q).future),
              child: ListView(
                key: const Key('genealogyPageList'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  DropdownButtonFormField<String>(
                    key: const Key('genealogyPetSelector'),
                    initialValue: id,
                    decoration: const InputDecoration(labelText: 'Mascota'),
                    items: [
                      for (final p in pets)
                        DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => selected = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Generaciones',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SegmentedButton<int>(
                        key: const Key('genealogyGenerationSelector'),
                        segments: const [
                          ButtonSegment(value: 1, label: Text('1')),
                          ButtonSegment(value: 2, label: Text('2')),
                          ButtonSegment(value: 3, label: Text('3')),
                        ],
                        selected: {generations},
                        showSelectedIcon: false,
                        onSelectionChanged: (v) =>
                            setState(() => generations = v.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...async.when(
                    loading: () => const [
                      SizedBox(height: 320, child: AppLoadingIndicator()),
                    ],
                    error: (e, _) => [
                      ErrorState(
                        title: 'No pudimos cargar el árbol',
                        message: e is AppFailure
                            ? e.message
                            : 'Revisa tu conexión.',
                        onRetry: () => ref.invalidate(genealogyTreeProvider(q)),
                      ),
                    ],
                    data: (tree) => [
                      GenealogyTreeView(
                        tree: tree,
                        generations: generations,
                        onNodeTap: (n) => _nodeActions(tree, n),
                        onAddParent: (r) => _addParent(tree, r, pets),
                      ),
                      if (!tree.hasRelationships) ...[
                        const SizedBox(height: 16),
                        const _Empty(),
                      ],
                      if (tree.children.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Hijos', style: AppTypography.h3),
                        const SizedBox(height: 8),
                        _Children(
                          children: tree.children,
                          onTap: (p) => _relatedActions(p),
                        ),
                      ],
                    ],
                  ),
                  if (mutating) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addParent(
    GenealogyTree tree,
    GenealogyParentRole role,
    List<PetSummary> pets,
  ) async {
    final source = await showModalBottomSheet<_Source>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Agregar ${role == GenealogyParentRole.father ? 'padre' : 'madre'}',
                style: AppTypography.h3,
              ),
            ),
            ListTile(
              key: const Key('parentSourceOwnPet'),
              leading: const Icon(Icons.pets_outlined),
              title: const Text('Una de mis mascotas'),
              onTap: () => Navigator.pop(c, _Source.own),
            ),
            ListTile(
              key: const Key('parentSourceExternal'),
              leading: const Icon(Icons.mail_outline),
              title: const Text('Mascota de otra persona'),
              onTap: () => Navigator.pop(c, _Source.external),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    if (source == _Source.external) {
      await _externalInvitation(tree, role);
      return;
    }
    final candidates = pets
        .where((pet) => pet.id != tree.rootPetId)
        .where((pet) => _isCompatibleParent(pet.sex, role))
        .toList();
    final pet = await showModalBottomSheet<PetSummary>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Selecciona tu mascota', style: AppTypography.h3),
            ),
            for (final p in candidates)
              ListTile(
                key: Key('parentCandidate-${p.id}'),
                leading: ClipOval(
                  child: AppNetworkImage(
                    url: GatewayUrlResolver.resolve(p.mainPhotoUrl),
                    width: 44,
                    height: 44,
                  ),
                ),
                title: Text(p.name),
                subtitle: Text('${_sex(p.sex)} · ${p.breedName}'),
                onTap: () => Navigator.pop(c, p),
              ),
          ],
        ),
      ),
    );
    if (!mounted || pet == null) return;
    final result = await ref
        .read(genealogyControllerProvider.notifier)
        .addParent(
          childPetId: tree.rootPetId,
          generations: generations,
          role: role,
          parentPetId: pet.id,
        );
    _feedback(
      result.isSuccess,
      result.failureOrNull?.message,
      'Relación guardada correctamente.',
    );
  }

  Future<void> _externalInvitation(
    GenealogyTree tree,
    GenealogyParentRole role,
  ) async {
    var email = '';
    final sent = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Correo del propietario'),
        content: TextField(
          key: const Key('invitationEmail'),
          onChanged: (value) => email = value,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'correo@ejemplo.com'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('sendGenealogyInvitation'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Enviar invitación'),
          ),
        ],
      ),
    );
    if (!mounted || sent != true) return;
    final result = await ref
        .read(genealogyControllerProvider.notifier)
        .createInvitation(
          childPetId: tree.rootPetId,
          role: role,
          ownerEmail: email.trim(),
        );
    _feedback(
      result.isSuccess,
      result.failureOrNull?.message,
      'Invitación enviada',
    );
  }

  Future<void> _nodeActions(
    GenealogyTree tree,
    GenealogyNodeSelection node,
  ) async {
    final action = await showModalBottomSheet<_Action>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(node.pet.name, style: AppTypography.h3)),
            ListTile(
              title: const Text('Ver perfil'),
              leading: const Icon(Icons.pets_outlined),
              onTap: () => Navigator.pop(c, _Action.profile),
            ),
            ListTile(
              title: const Text('Ver su árbol'),
              leading: const Icon(Icons.account_tree_outlined),
              onTap: () => Navigator.pop(c, _Action.tree),
            ),
            if (node.relationshipId != null)
              ListTile(
                key: const Key('deleteGenealogyRelationship'),
                title: const Text(
                  'Eliminar relación',
                  style: TextStyle(color: AppColors.error),
                ),
                leading: const Icon(Icons.link_off, color: AppColors.error),
                onTap: () => Navigator.pop(c, _Action.delete),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == _Action.profile) {
      context.push(AppRoutes.petDetails(node.pet.petId));
      return;
    }
    if (action == _Action.tree) {
      context.push(AppRoutes.genealogyForPet(node.pet.petId));
      return;
    }
    final ok = await AppDialog.confirm(
      context,
      title: '¿Eliminar esta relación?',
      message:
          '${node.pet.name} dejará de aparecer como '
          '${node.role == GenealogyParentRole.father ? 'padre' : 'madre'} de '
          '${tree.pet.name}. No se eliminarán las mascotas ni sus demás datos.',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
      isDestructive: true,
    );
    if (!mounted || !ok) return;
    final result = await ref
        .read(genealogyControllerProvider.notifier)
        .deleteRelationship(
          relationshipId: node.relationshipId!,
          petId: tree.rootPetId,
          generations: generations,
        );
    _feedback(
      result.isSuccess,
      result.failureOrNull?.message,
      'Relación eliminada.',
    );
  }

  Future<void> _relatedActions(GenealogyPetNode pet) async {
    final action = await showModalBottomSheet<_Action>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(pet.name)),
            ListTile(
              title: const Text('Ver perfil'),
              onTap: () => Navigator.pop(c, _Action.profile),
            ),
            ListTile(
              title: const Text('Ver su árbol'),
              onTap: () => Navigator.pop(c, _Action.tree),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    context.push(
      action == _Action.profile
          ? AppRoutes.petDetails(pet.petId)
          : AppRoutes.genealogyForPet(pet.petId),
    );
  }

  void _feedback(bool success, String? error, String ok) {
    if (!mounted) return;
    success
        ? AppSnackBar.showSuccess(context, ok)
        : AppSnackBar.showError(
            context,
            error ?? 'No pudimos completar la operación.',
          );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Text('No hay relaciones registradas todavía', style: AppTypography.h3),
        const SizedBox(height: 4),
        Text(
          'Empieza agregando el padre o la madre de tu mascota.',
          style: AppTypography.bodySecondary,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _Children extends StatelessWidget {
  const _Children({required this.children, required this.onTap});
  final List<GenealogyChildNode> children;
  final ValueChanged<GenealogyPetNode> onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 112,
    child: ListView.separated(
      key: const Key('genealogyChildrenList'),
      scrollDirection: Axis.horizontal,
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (c, i) {
        final p = children[i].pet;
        return InkWell(
          key: Key('genealogyChild-${p.petId}'),
          onTap: () => onTap(p),
          child: Container(
            width: 190,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: AppNetworkImage(
                    url: GatewayUrlResolver.resolve(p.mainPhotoUrl),
                    width: 48,
                    height: 48,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

enum _Source { own, external }

enum _Action { profile, tree, delete }

String _sex(String s) => switch (s.toUpperCase()) {
  'M' || 'MALE' => 'Macho',
  'F' || 'FEMALE' => 'Hembra',
  _ => s,
};

bool _isCompatibleParent(String sex, GenealogyParentRole role) {
  final normalized = sex.toUpperCase();
  if (role == GenealogyParentRole.father) {
    return normalized == 'M' || normalized == 'MALE';
  }
  return normalized == 'F' || normalized == 'FEMALE';
}
