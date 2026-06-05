import 'package:drift/drift.dart';

part 'database.g.dart';

/// Tabela de armazenamento em cache dos exercícios gerados pelo pipeline RAG.
@DataClassName('ExerciseEntity')
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get moduleId => text()();
  TextColumn get topic => text()();
  RealColumn get difficultyMultiplier => real()();
  TextColumn get contentJson => text()(); // Armazena a estrutura da pergunta/opções
  TextColumn get aiTutorMetadataJson => text()(); // Referências RAG para a LLM
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Fila transacional para Eventual Consistency (Offline Sync).
@DataClassName('TelemetryRecord')
class TelemetryQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get exerciseId => text()();
  BoolColumn get isCorrect => boolean()();
  IntColumn get timeSpentSeconds => integer()();
  IntColumn get aiTutorInvocations => integer()();
  IntColumn get earnedXp => integer()();
  DateTimeColumn get solvedAt => dateTime()();
  
  // Estados possíveis: PENDING, PROCESSING, SYNCED, FAILED
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))(); 
}

@DriftDatabase(tables: [Exercises, TelemetryQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  // DAO: Operações de Leitura de Exercícios
  Future<List<ExerciseEntity>> getExercisesByTopic(String topicId) =>
      (select(exercises)..where((t) => t.topic.equals(topicId))).get();

  // DAO: Operações de Fila de Telemetria
  Future<int> insertTelemetry(TelemetryQueueCompanion entry) =>
      into(telemetryQueue).insert(entry);

  Future<List<TelemetryRecord>> getPendingTelemetry() =>
      (select(telemetryQueue)..where((t) => t.syncStatus.equals('PENDING'))).get();
      
  Future<void> markTelemetryAsSynced(List<int> ids) =>
      (update(telemetryQueue)..where((t) => t.id.isIn(ids)))
          .write(const TelemetryQueueCompanion(syncStatus: Value('SYNCED')));
}