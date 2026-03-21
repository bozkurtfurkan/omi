import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class Conversations extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get durationSeconds => integer()();
  TextColumn get title => text().nullable()();
  TextColumn get transcript => text()();
  TextColumn get audioPath => text().nullable()();
  TextColumn get locale => text().withDefault(const Constant('tr_TR'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Conversations])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'omi_local.db'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
