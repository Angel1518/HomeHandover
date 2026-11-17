import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_handover/core/theme/app_theme.dart';
import 'package:home_handover/features/handover/controllers/handover_controller.dart';
import 'package:home_handover/features/handover/data/handover_repository.dart';
import 'package:home_handover/features/handover/models/handover_models.dart';
import 'package:home_handover/features/handover/services/handover_exporter.dart';
import 'package:home_handover/features/handover/ui/homes_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  test('HandoverExporter escapes HTML and builds ZIP + PDF', () async {
    final home = Vivienda(
      id: 'h1',
      name: 'Casa <Norte>',
      emergencyContact: '112 / Fontanero 600000000',
      createdAt: DateTime(2026, 11, 17),
    );
    const room = Estancia(id: 'r1', homeId: 'h1', name: 'Cocina');
    const card = Ficha(
      id: 'c1',
      roomId: 'r1',
      title: 'Llave de paso',
      summary: 'Girar 90 grados',
      isEmergency: true,
    );
    const step = Paso(
      id: 's1',
      cardId: 'c1',
      stepOrder: 1,
      instruction: 'Abrir armario bajo fregadero',
    );

    final html = HandoverExporter.buildHtmlManual(
      home: home,
      rooms: [room],
      cards: [card],
      steps: [step],
      tasks: const [],
    );
    expect(html, contains('Casa &lt;Norte&gt;'));
    expect(html, contains('[URGENCIA]'));

    final zip = HandoverExporter.buildZipBundle(
      home: home,
      rooms: [room],
      cards: [card],
      steps: [step],
      tasks: const [],
    );
    final decoded = ZipDecoder().decodeBytes(zip);
    expect(
      decoded.files.map((f) => f.name),
      containsAll(['manual.html', 'manual.json', 'manifest.sha256']),
    );

    final pdf = await HandoverExporter.buildPdf(
      home: home,
      rooms: [room],
      cards: [card],
      steps: [step],
    );
    expect(pdf.length, greaterThan(400));
  });

  testWidgets('HomesScreen renders without overflow at 320px and 200% TextScaler', (tester) async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: HandoverRepository.createSchema,
    );
    final repo = HandoverRepository(testDb: db);
    await repo.upsertHome(
      Vivienda(
        id: 'h_long',
        name: 'Vivienda_${'M' * 100}',
        createdAt: DateTime(2026, 11, 17),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [handoverRepositoryProvider.overrideWithValue(repo)],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            theme: AppTheme.light(accent: const Color(0xFFB45309)),
            home: const HomesScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
    await db.close();
  });
}

