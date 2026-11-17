import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/handover_models.dart';

class HandoverExporter {
  static String buildHtmlManual({
    required Vivienda home,
    required List<Estancia> rooms,
    required List<Ficha> cards,
    required List<Paso> steps,
    required List<Tarea> tasks,
  }) {
    final buf = StringBuffer()
      ..writeln('<!DOCTYPE html><html lang="es"><head><meta charset="utf-8">')
      ..writeln('<title>${_esc(home.name)} — Manual de vivienda</title>')
      ..writeln(
          '<style>body{font-family:sans-serif;max-width:780px;margin:24px auto;padding:0 16px;color:#182637}h1,h2{color:#B45309}.card{border:1px solid #d5dce6;border-radius:10px;padding:12px;margin:10px 0}</style>')
      ..writeln('</head><body>')
      ..writeln('<h1>${_esc(home.name)}</h1>');
    if (home.address.isNotEmpty) {
      buf.writeln('<p><strong>Dirección:</strong> ${_esc(home.address)}</p>');
    }
    if (home.emergencyContact.isNotEmpty) {
      buf.writeln(
          '<p><strong>Contacto de urgencia:</strong> ${_esc(home.emergencyContact)}</p>');
    }

    for (final room in rooms) {
      buf.writeln('<h2>${_esc(room.name)}</h2>');
      final roomCards = cards.where((c) => c.roomId == room.id);
      for (final card in roomCards) {
        buf.writeln('<div class="card">');
        buf.writeln(
            '<h3>${card.isEmergency ? "[URGENCIA] " : ""}${_esc(card.title)}</h3>');
        if (card.locationHint.isNotEmpty) {
          buf.writeln(
              '<p><em>Ubicación: ${_esc(card.locationHint)}</em></p>');
        }
        buf.writeln('<p>${_esc(card.summary)}</p>');
        final cardSteps = steps.where((s) => s.cardId == card.id).toList();
        if (cardSteps.isNotEmpty) {
          buf.writeln('<ol>');
          for (final s in cardSteps) {
            buf.writeln('<li>${_esc(s.instruction)}</li>');
          }
          buf.writeln('</ol>');
        }
        buf.writeln('</div>');
      }
    }

    if (tasks.isNotEmpty) {
      buf.writeln('<h2>Mantenimiento periódico</h2><ul>');
      for (final t in tasks) {
        buf.writeln(
            '<li>[${t.isDone ? "Hecho" : "Pendiente"}] ${_esc(t.title)} (${_esc(t.frequency)})</li>');
      }
      buf.writeln('</ul>');
    }

    buf.writeln('</body></html>');
    return buf.toString();
  }

  static Uint8List buildZipBundle({
    required Vivienda home,
    required List<Estancia> rooms,
    required List<Ficha> cards,
    required List<Paso> steps,
    required List<Tarea> tasks,
  }) {
    final html = utf8.encode(buildHtmlManual(
      home: home,
      rooms: rooms,
      cards: cards,
      steps: steps,
      tasks: tasks,
    ));
    final json = utf8.encode(const JsonEncoder.withIndent('  ').convert({
      'home': home.toMap(),
      'rooms': rooms.map((r) => r.toMap()).toList(),
      'cards': cards.map((c) => c.toMap()).toList(),
      'steps': steps.map((s) => s.toMap()).toList(),
      'tasks': tasks.map((t) => t.toMap()).toList(),
    }));
    final manifest = utf8.encode(
      'manual.html  sha256:${sha256.convert(html)}\n'
      'manual.json  sha256:${sha256.convert(json)}\n',
    );

    final archive = Archive()
      ..addFile(ArchiveFile('manual.html', html.length, html))
      ..addFile(ArchiveFile('manual.json', json.length, json))
      ..addFile(ArchiveFile('manifest.sha256', manifest.length, manifest));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static Future<Uint8List> buildPdf({
    required Vivienda home,
    required List<Estancia> rooms,
    required List<Ficha> cards,
    required List<Paso> steps,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Manual de vivienda: ${home.name}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          if (home.emergencyContact.isNotEmpty)
            pw.Paragraph(text: 'Urgencias: ${home.emergencyContact}'),
          ...rooms.expand((room) {
            final roomCards = cards.where((c) => c.roomId == room.id).toList();
            return [
              pw.Header(level: 1, child: pw.Text(room.name)),
              ...roomCards.map((c) {
                final cSteps =
                    steps.where((s) => s.cardId == c.id).toList();
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${c.isEmergency ? "[URGENCIA] " : ""}${c.title}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      if (c.summary.isNotEmpty) pw.Text(c.summary),
                      ...cSteps.map(
                        (s) => pw.Text('${s.stepOrder}. ${s.instruction}'),
                      ),
                    ],
                  ),
                );
              }),
            ];
          }),
        ],
      ),
    );
    return doc.save();
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

