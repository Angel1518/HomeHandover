import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/ai/ai_controller.dart';
import '../../../core/ai/privacy_preview_dialog.dart';
import '../controllers/handover_controller.dart';
import '../models/handover_models.dart';
import '../services/handover_exporter.dart';

class HomeDetailScreen extends ConsumerWidget {
  const HomeDetailScreen({super.key, required this.homeId});
  final String homeId;

  Future<void> _addCardDialog(
    BuildContext context,
    WidgetRef ref,
    List<Estancia> rooms,
  ) async {
    if (rooms.isEmpty) return;
    String selectedRoomId = rooms.first.id;
    final titleCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final stepsCtrl = TextEditingController();
    bool isEmergency = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nueva ficha de la casa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedRoomId,
                  items: rooms
                      .map((r) =>
                          DropdownMenuItem(value: r.id, child: Text(r.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setLocal(() => selectedRoomId = v);
                  },
                  decoration: const InputDecoration(labelText: 'Estancia'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ej. Llave de paso general',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locationCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Dónde está'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: summaryCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Resumen'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stepsCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Pasos (uno por línea)',
                  ),
                ),
                SwitchListTile(
                  value: isEmergency,
                  onChanged: (v) => setLocal(() => isEmergency = v),
                  title: const Text('Marcar como urgencia'),
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
              child: const Text('Guardar ficha'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && titleCtrl.text.trim().isNotEmpty) {
      await ref.read(handoverControllerProvider.notifier).addCard(
            roomId: selectedRoomId,
            title: titleCtrl.text,
            summary: summaryCtrl.text,
            isEmergency: isEmergency,
            locationHint: locationCtrl.text,
            stepLines: stepsCtrl.text.split('\n'),
          );
    }
  }

  Future<void> _exportManual({
    required BuildContext context,
    required Vivienda home,
    required List<Estancia> rooms,
    required List<Ficha> cards,
    required List<Paso> steps,
    required List<Tarea> tasks,
    required bool asPdf,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(p.join(
        dir.path,
        asPdf ? 'manual_${home.id}.pdf' : 'manual_${home.id}.zip',
      ));
      final bytes = asPdf
          ? await HandoverExporter.buildPdf(
              home: home,
              rooms: rooms,
              cards: cards,
              steps: steps,
            )
          : HandoverExporter.buildZipBundle(
              home: home,
              rooms: rooms,
              cards: cards,
              steps: steps,
              tasks: tasks,
            );
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Manual ${home.name}');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
    }
  }

  Future<void> _draftWithAi(
    BuildContext context,
    WidgetRef ref,
    List<Estancia> rooms,
  ) async {
    if (rooms.isEmpty) return;
    final aiSettings = ref.read(aiSettingsProvider);
    if (!aiSettings.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activa la IA BYOK en Ajustes si deseas usarla.'),
        ),
      );
      return;
    }
    final reviewed = await showPrivacyPreviewDialog(
      context: context,
      settings: aiSettings,
      initialText: 'Cómo reiniciar la caldera o cortar el agua: ',
      title: 'Redactar ficha clara con IA',
    );
    if (reviewed == null || reviewed.isEmpty) return;
    await ref
        .read(handoverControllerProvider.notifier)
        .draftCardWithAi(roomId: rooms.first.id, reviewedNotes: reviewed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(handoverControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manual de la casa')),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) {
          final home = data.homes.where((h) => h.id == homeId).firstOrNull;
          if (home == null) {
            return const Center(child: Text('Vivienda no encontrada.'));
          }
          final rooms =
              data.rooms.where((r) => r.homeId == home.id).toList();
          final roomIds = rooms.map((r) => r.id).toSet();
          final cards =
              data.cards.where((c) => roomIds.contains(c.roomId)).toList();
          final cardIds = cards.map((c) => c.id).toSet();
          final steps =
              data.steps.where((s) => cardIds.contains(s.cardId)).toList();
          final tasks =
              data.tasks.where((t) => t.homeId == home.id).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(home.name, style: theme.textTheme.headlineMedium),
              if (home.emergencyContact.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Urgencias: ${home.emergencyContact}',
                    style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _addCardDialog(context, ref, rooms),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva ficha'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _exportManual(
                      context: context,
                      home: home,
                      rooms: rooms,
                      cards: cards,
                      steps: steps,
                      tasks: tasks,
                      asPdf: true,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _exportManual(
                      context: context,
                      home: home,
                      rooms: rooms,
                      cards: cards,
                      steps: steps,
                      tasks: tasks,
                      asPdf: false,
                    ),
                    icon: const Icon(Icons.folder_zip_outlined),
                    label: const Text('Paquete ZIP'),
                  ),
                  TextButton.icon(
                    onPressed: () => _draftWithAi(context, ref, rooms),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Borrador IA'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...rooms.map((room) {
                final rCards =
                    cards.where((c) => c.roomId == room.id).toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (rCards.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: Text('Sin fichas en esta estancia.'),
                          ),
                        )
                      else
                        ...rCards.map((c) {
                          final cSteps = steps
                              .where((s) => s.cardId == c.id)
                              .toList();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (c.isEmergency)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 6),
                                            child: Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.red,
                                                size: 20),
                                          ),
                                        Expanded(
                                          child: Text(c.title,
                                              style:
                                                  theme.textTheme.titleMedium),
                                        ),
                                      ],
                                    ),
                                    if (c.locationHint.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Ubicación: ${c.locationHint}',
                                          style: theme.textTheme.bodySmall),
                                    ],
                                    if (c.summary.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(c.summary),
                                    ],
                                    if (cSteps.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      ...cSteps.map(
                                        (s) => Text(
                                            '${s.stepOrder}. ${s.instruction}'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

