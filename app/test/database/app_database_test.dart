import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:omi/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => await db.close());

  test('inserts and retrieves a conversation', () async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    await db.into(db.conversations).insert(ConversationsCompanion.insert(
          id: id,
          startedAt: now,
          endedAt: now.add(const Duration(minutes: 5)),
          durationSeconds: 300,
          transcript: 'Merhaba dünya',
          locale: const Value('tr_TR'),
        ));

    final results = await db.select(db.conversations).get();
    expect(results.length, 1);
    expect(results.first.transcript, 'Merhaba dünya');
    expect(results.first.durationSeconds, 300);
  });

  test('title and audioPath default to null', () async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    await db.into(db.conversations).insert(ConversationsCompanion.insert(
          id: id,
          startedAt: now,
          endedAt: now,
          durationSeconds: 0,
          transcript: '',
          locale: const Value('tr_TR'),
        ));

    final result = (await db.select(db.conversations).get()).first;
    expect(result.title, isNull);
    expect(result.audioPath, isNull);
  });
}
