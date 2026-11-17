import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_controller.dart';
import '../data/handover_repository.dart';
import '../models/handover_models.dart';

final handoverRepositoryProvider = Provider<HandoverRepository>(
  (ref) => HandoverRepository(),
);

class HandoverState {
  const HandoverState({
    this.homes = const [],
    this.rooms = const [],
    this.cards = const [],
    this.steps = const [],
    this.tasks = const [],
  });

  final List<Vivienda> homes;
  final List<Estancia> rooms;
  final List<Ficha> cards;
  final List<Paso> steps;
  final List<Tarea> tasks;
}

class HandoverController extends AsyncNotifier<HandoverState> {
  @override
  Future<HandoverState> build() async => _loadAll();

  HandoverRepository get _repo => ref.read(handoverRepositoryProvider);

  Future<HandoverState> _loadAll() async {
    return HandoverState(
      homes: await _repo.listHomes(),
      rooms: await _repo.listRooms(),
      cards: await _repo.listCards(),
      steps: await _repo.listSteps(),
      tasks: await _repo.listTasks(),
    );
  }

  Future<Vivienda> addHome({
    required String name,
    String address = '',
    String emergencyContact = '',
  }) async {
    final now = DateTime.now();
    final home = Vivienda(
      id: 'home_${now.microsecondsSinceEpoch}',
      name: name.trim(),
      address: address.trim(),
      emergencyContact: emergencyContact.trim(),
      createdAt: now,
    );
    await _repo.upsertHome(home);
    // Create default starter rooms.
    for (final roomName in ['General y Suministros', 'Cocina', 'Caldera / Clima']) {
      await _repo.upsertRoom(
        Estancia(
          id: 'room_${DateTime.now().microsecondsSinceEpoch}_${roomName.hashCode}',
          homeId: home.id,
          name: roomName,
        ),
      );
    }
    state = AsyncData(await _loadAll());
    return home;
  }

  Future<void> addRoom({required String homeId, required String name}) async {
    await _repo.upsertRoom(
      Estancia(
        id: 'room_${DateTime.now().microsecondsSinceEpoch}',
        homeId: homeId,
        name: name.trim(),
      ),
    );
    state = AsyncData(await _loadAll());
  }

  Future<void> addCard({
    required String roomId,
    required String title,
    required String summary,
    bool isEmergency = false,
    String locationHint = '',
    List<String> stepLines = const [],
  }) async {
    final cardId = 'card_${DateTime.now().microsecondsSinceEpoch}';
    final card = Ficha(
      id: cardId,
      roomId: roomId,
      title: title.trim(),
      summary: summary.trim(),
      isEmergency: isEmergency,
      locationHint: locationHint.trim(),
    );
    final steps = [
      for (var i = 0; i < stepLines.length; i++)
        if (stepLines[i].trim().isNotEmpty)
          Paso(
            id: '${cardId}_s_$i',
            cardId: cardId,
            stepOrder: i + 1,
            instruction: stepLines[i].trim(),
          ),
    ];
    await _repo.saveCardWithSteps(card: card, steps: steps);
    state = AsyncData(await _loadAll());
  }

  Future<void> addTask({
    required String homeId,
    required String title,
    String frequency = 'Mensual',
  }) async {
    await _repo.upsertTask(
      Tarea(
        id: 'task_${DateTime.now().microsecondsSinceEpoch}',
        homeId: homeId,
        title: title.trim(),
        frequency: frequency,
      ),
    );
    state = AsyncData(await _loadAll());
  }

  Future<void> toggleTask(Tarea task) async {
    await _repo.upsertTask(task.copyWith(isDone: !task.isDone));
    state = AsyncData(await _loadAll());
  }

  Future<void> draftCardWithAi({
    required String roomId,
    required String reviewedNotes,
  }) async {
    final ai = ref.read(aiSettingsProvider.notifier);
    final resp = await ai.runStructured(
      taskInstruction:
          'Convierte estas notas sobre un aparato, llave de paso o cuadro de la casa en una ficha clara con pasos numerados.',
      reviewedText: reviewedNotes,
      jsonSchemaHint: '''
{
  "title": "título breve",
  "summary": "resumen directo",
  "is_emergency": false,
  "steps": ["paso 1", "paso 2"]
}''',
    );
    final json = resp.parsedJson;
    if (json == null) return;
    final title = json['title']?.toString().trim() ?? '';
    if (title.isEmpty) return;
    final steps = (json['steps'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();

    await addCard(
      roomId: roomId,
      title: title,
      summary: json['summary']?.toString() ?? '',
      isEmergency: json['is_emergency'] == true,
      stepLines: steps,
    );
  }
}

final handoverControllerProvider =
    AsyncNotifierProvider<HandoverController, HandoverState>(
  HandoverController.new,
);

