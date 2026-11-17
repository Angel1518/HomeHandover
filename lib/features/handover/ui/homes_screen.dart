import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/handover_controller.dart';

class HomesScreen extends ConsumerStatefulWidget {
  const HomesScreen({super.key});

  @override
  ConsumerState<HomesScreen> createState() => _HomesScreenState();
}

class _HomesScreenState extends ConsumerState<HomesScreen> {
  bool _onlyEmergency = false;

  Future<void> _showCreateHomeDialog() async {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva vivienda'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Piso calle Mayor o Casa pueblo',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contacto de urgencias',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Crear manual'),
          ),
        ],
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      final home = await ref.read(handoverControllerProvider.notifier).addHome(
            name: nameCtrl.text,
            address: addrCtrl.text,
            emergencyContact: phoneCtrl.text,
          );
      if (mounted) context.push('/homes/${home.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(handoverControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('HomeHandover')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateHomeDialog,
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Vivienda'),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) {
          final emergencyCards =
              data.cards.where((c) => c.isEmergency).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Todo lo que necesitas saber de esta casa',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      FilterChip(
                        avatar: const Icon(Icons.warning_amber_outlined,
                            size: 18),
                        label: Text(
                            'Solo urgencias (${emergencyCards.length})'),
                        selected: _onlyEmergency,
                        onSelected: (v) => setState(() => _onlyEmergency = v),
                      ),
                    ],
                  ),
                ),
              ),
              if (_onlyEmergency)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  sliver: emergencyCards.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No hay fichas marcadas como urgencia todavía.',
                              ),
                            ),
                          ),
                        )
                      : SliverList.separated(
                          itemCount: emergencyCards.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final card = emergencyCards[i];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.emergency_outlined,
                                    color: Colors.red),
                                title: Text(card.title),
                                subtitle: Text(card.summary),
                              ),
                            );
                          },
                        ),
                )
              else if (data.homes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home_work_outlined,
                              size: 52, color: theme.colorScheme.primary),
                          const SizedBox(height: 12),
                          Text('Sin viviendas configuradas',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Crea el manual de tu casa por estancias con llaves de paso, cuadro eléctrico, caldera y paquete exportable.',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  sliver: SliverList.separated(
                    itemCount: data.homes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final home = data.homes[index];
                      final homeRooms = data.rooms
                          .where((r) => r.homeId == home.id)
                          .length;
                      return TweenAnimationBuilder<double>(
                        duration: AppMotion.duration(
                          context,
                          Duration(milliseconds: 180 + (index.clamp(0, 6) * 35)),
                        ),
                        curve: AppMotion.curve(context),
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - t)),
                            child: child,
                          ),
                        ),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              child: Icon(Icons.home_outlined,
                                  color: theme.colorScheme.primary),
                            ),
                            title: Text(home.name,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text('$homeRooms estancias'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/homes/${home.id}'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

