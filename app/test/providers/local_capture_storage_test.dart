import 'dart:async';
import 'dart:typed_data';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:omi/database/app_database.dart';
import 'package:omi/providers/local_capture_provider.dart';

import 'local_capture_provider_test.mocks.dart';

void main() {
  late MockSpeechService mockSpeech;
  late AppDatabase db;

  setUp(() {
    mockSpeech = MockSpeechService();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => await db.close());

  test('stopRecording saves conversation to database', () async {
    final controller = StreamController<String>();
    when(mockSpeech.initialize()).thenAnswer((_) async {});
    when(mockSpeech.transcribe(any)).thenAnswer((_) => controller.stream);
    when(mockSpeech.stop()).thenAnswer((_) async {});

    final provider = LocalCaptureProvider(speechService: mockSpeech, database: db);
    await provider.startRecording(audioStream: const Stream<Uint8List>.empty());

    controller.add('Test transkript');
    await Future.delayed(Duration.zero);

    await provider.stopRecording();

    final rows = await db.select(db.conversations).get();
    expect(rows.length, 1);
    expect(rows.first.transcript, 'Test transkript');
    expect(rows.first.locale, 'tr_TR');
    expect(rows.first.durationSeconds, greaterThanOrEqualTo(0));
    await controller.close();
  });

  test('stopRecording without transcript still saves empty conversation', () async {
    final controller = StreamController<String>();
    when(mockSpeech.initialize()).thenAnswer((_) async {});
    when(mockSpeech.transcribe(any)).thenAnswer((_) => controller.stream);
    when(mockSpeech.stop()).thenAnswer((_) async {});

    final provider = LocalCaptureProvider(speechService: mockSpeech, database: db);
    await provider.startRecording(audioStream: const Stream<Uint8List>.empty());
    await provider.stopRecording();

    final rows = await db.select(db.conversations).get();
    expect(rows.length, 1);
    expect(rows.first.transcript, '');
    await controller.close();
  });
}
