import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';

/// "Your data is yours" (privacy promise): everything in the vault as one
/// JSON document. Feeds the share sheet today and the Phase-3 import later.
class ExportService {
  ExportService(this._db);

  final AppDatabase _db;

  Future<String> buildExportJson() async {
    Future<List<Map<String, Object?>>> dump(
        TableInfo<Table, Object?> table) async {
      final rows = await _db.select(table).get();
      return [
        for (final row in rows)
          if (row is DataClass) row.toJson(),
      ];
    }

    final export = {
      'app': 'HomeVault',
      'formatVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'homes': await dump(_db.homes),
      'members': await dump(_db.members),
      'assets': await dump(_db.assets),
      'bills': await dump(_db.bills),
      'events': await dump(_db.events),
      'documents': await dump(_db.documents),
      'reminders': await dump(_db.reminders),
    };
    return const JsonEncoder.withIndent('  ').convert(export);
  }
}

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref.watch(databaseProvider));
});
