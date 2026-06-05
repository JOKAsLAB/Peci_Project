// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, ExerciseEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _moduleIdMeta =
      const VerificationMeta('moduleId');
  @override
  late final GeneratedColumn<String> moduleId = GeneratedColumn<String>(
      'module_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
      'topic', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _difficultyMultiplierMeta =
      const VerificationMeta('difficultyMultiplier');
  @override
  late final GeneratedColumn<double> difficultyMultiplier =
      GeneratedColumn<double>('difficulty_multiplier', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _contentJsonMeta =
      const VerificationMeta('contentJson');
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
      'content_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _aiTutorMetadataJsonMeta =
      const VerificationMeta('aiTutorMetadataJson');
  @override
  late final GeneratedColumn<String> aiTutorMetadataJson =
      GeneratedColumn<String>('ai_tutor_metadata_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        moduleId,
        topic,
        difficultyMultiplier,
        contentJson,
        aiTutorMetadataJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(Insertable<ExerciseEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('module_id')) {
      context.handle(_moduleIdMeta,
          moduleId.isAcceptableOrUnknown(data['module_id']!, _moduleIdMeta));
    } else if (isInserting) {
      context.missing(_moduleIdMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
          _topicMeta, topic.isAcceptableOrUnknown(data['topic']!, _topicMeta));
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('difficulty_multiplier')) {
      context.handle(
          _difficultyMultiplierMeta,
          difficultyMultiplier.isAcceptableOrUnknown(
              data['difficulty_multiplier']!, _difficultyMultiplierMeta));
    } else if (isInserting) {
      context.missing(_difficultyMultiplierMeta);
    }
    if (data.containsKey('content_json')) {
      context.handle(
          _contentJsonMeta,
          contentJson.isAcceptableOrUnknown(
              data['content_json']!, _contentJsonMeta));
    } else if (isInserting) {
      context.missing(_contentJsonMeta);
    }
    if (data.containsKey('ai_tutor_metadata_json')) {
      context.handle(
          _aiTutorMetadataJsonMeta,
          aiTutorMetadataJson.isAcceptableOrUnknown(
              data['ai_tutor_metadata_json']!, _aiTutorMetadataJsonMeta));
    } else if (isInserting) {
      context.missing(_aiTutorMetadataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      moduleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}module_id'])!,
      topic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}topic'])!,
      difficultyMultiplier: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}difficulty_multiplier'])!,
      contentJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_json'])!,
      aiTutorMetadataJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ai_tutor_metadata_json'])!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class ExerciseEntity extends DataClass implements Insertable<ExerciseEntity> {
  final String id;
  final String moduleId;
  final String topic;
  final double difficultyMultiplier;
  final String contentJson;
  final String aiTutorMetadataJson;
  const ExerciseEntity(
      {required this.id,
      required this.moduleId,
      required this.topic,
      required this.difficultyMultiplier,
      required this.contentJson,
      required this.aiTutorMetadataJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['module_id'] = Variable<String>(moduleId);
    map['topic'] = Variable<String>(topic);
    map['difficulty_multiplier'] = Variable<double>(difficultyMultiplier);
    map['content_json'] = Variable<String>(contentJson);
    map['ai_tutor_metadata_json'] = Variable<String>(aiTutorMetadataJson);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      moduleId: Value(moduleId),
      topic: Value(topic),
      difficultyMultiplier: Value(difficultyMultiplier),
      contentJson: Value(contentJson),
      aiTutorMetadataJson: Value(aiTutorMetadataJson),
    );
  }

  factory ExerciseEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseEntity(
      id: serializer.fromJson<String>(json['id']),
      moduleId: serializer.fromJson<String>(json['moduleId']),
      topic: serializer.fromJson<String>(json['topic']),
      difficultyMultiplier:
          serializer.fromJson<double>(json['difficultyMultiplier']),
      contentJson: serializer.fromJson<String>(json['contentJson']),
      aiTutorMetadataJson:
          serializer.fromJson<String>(json['aiTutorMetadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'moduleId': serializer.toJson<String>(moduleId),
      'topic': serializer.toJson<String>(topic),
      'difficultyMultiplier': serializer.toJson<double>(difficultyMultiplier),
      'contentJson': serializer.toJson<String>(contentJson),
      'aiTutorMetadataJson': serializer.toJson<String>(aiTutorMetadataJson),
    };
  }

  ExerciseEntity copyWith(
          {String? id,
          String? moduleId,
          String? topic,
          double? difficultyMultiplier,
          String? contentJson,
          String? aiTutorMetadataJson}) =>
      ExerciseEntity(
        id: id ?? this.id,
        moduleId: moduleId ?? this.moduleId,
        topic: topic ?? this.topic,
        difficultyMultiplier: difficultyMultiplier ?? this.difficultyMultiplier,
        contentJson: contentJson ?? this.contentJson,
        aiTutorMetadataJson: aiTutorMetadataJson ?? this.aiTutorMetadataJson,
      );
  ExerciseEntity copyWithCompanion(ExercisesCompanion data) {
    return ExerciseEntity(
      id: data.id.present ? data.id.value : this.id,
      moduleId: data.moduleId.present ? data.moduleId.value : this.moduleId,
      topic: data.topic.present ? data.topic.value : this.topic,
      difficultyMultiplier: data.difficultyMultiplier.present
          ? data.difficultyMultiplier.value
          : this.difficultyMultiplier,
      contentJson:
          data.contentJson.present ? data.contentJson.value : this.contentJson,
      aiTutorMetadataJson: data.aiTutorMetadataJson.present
          ? data.aiTutorMetadataJson.value
          : this.aiTutorMetadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseEntity(')
          ..write('id: $id, ')
          ..write('moduleId: $moduleId, ')
          ..write('topic: $topic, ')
          ..write('difficultyMultiplier: $difficultyMultiplier, ')
          ..write('contentJson: $contentJson, ')
          ..write('aiTutorMetadataJson: $aiTutorMetadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, moduleId, topic, difficultyMultiplier,
      contentJson, aiTutorMetadataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseEntity &&
          other.id == this.id &&
          other.moduleId == this.moduleId &&
          other.topic == this.topic &&
          other.difficultyMultiplier == this.difficultyMultiplier &&
          other.contentJson == this.contentJson &&
          other.aiTutorMetadataJson == this.aiTutorMetadataJson);
}

class ExercisesCompanion extends UpdateCompanion<ExerciseEntity> {
  final Value<String> id;
  final Value<String> moduleId;
  final Value<String> topic;
  final Value<double> difficultyMultiplier;
  final Value<String> contentJson;
  final Value<String> aiTutorMetadataJson;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.moduleId = const Value.absent(),
    this.topic = const Value.absent(),
    this.difficultyMultiplier = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.aiTutorMetadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String moduleId,
    required String topic,
    required double difficultyMultiplier,
    required String contentJson,
    required String aiTutorMetadataJson,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        moduleId = Value(moduleId),
        topic = Value(topic),
        difficultyMultiplier = Value(difficultyMultiplier),
        contentJson = Value(contentJson),
        aiTutorMetadataJson = Value(aiTutorMetadataJson);
  static Insertable<ExerciseEntity> custom({
    Expression<String>? id,
    Expression<String>? moduleId,
    Expression<String>? topic,
    Expression<double>? difficultyMultiplier,
    Expression<String>? contentJson,
    Expression<String>? aiTutorMetadataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (moduleId != null) 'module_id': moduleId,
      if (topic != null) 'topic': topic,
      if (difficultyMultiplier != null)
        'difficulty_multiplier': difficultyMultiplier,
      if (contentJson != null) 'content_json': contentJson,
      if (aiTutorMetadataJson != null)
        'ai_tutor_metadata_json': aiTutorMetadataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith(
      {Value<String>? id,
      Value<String>? moduleId,
      Value<String>? topic,
      Value<double>? difficultyMultiplier,
      Value<String>? contentJson,
      Value<String>? aiTutorMetadataJson,
      Value<int>? rowid}) {
    return ExercisesCompanion(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      topic: topic ?? this.topic,
      difficultyMultiplier: difficultyMultiplier ?? this.difficultyMultiplier,
      contentJson: contentJson ?? this.contentJson,
      aiTutorMetadataJson: aiTutorMetadataJson ?? this.aiTutorMetadataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (moduleId.present) {
      map['module_id'] = Variable<String>(moduleId.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (difficultyMultiplier.present) {
      map['difficulty_multiplier'] =
          Variable<double>(difficultyMultiplier.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (aiTutorMetadataJson.present) {
      map['ai_tutor_metadata_json'] =
          Variable<String>(aiTutorMetadataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('moduleId: $moduleId, ')
          ..write('topic: $topic, ')
          ..write('difficultyMultiplier: $difficultyMultiplier, ')
          ..write('contentJson: $contentJson, ')
          ..write('aiTutorMetadataJson: $aiTutorMetadataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TelemetryQueueTable extends TelemetryQueue
    with TableInfo<$TelemetryQueueTable, TelemetryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TelemetryQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isCorrectMeta =
      const VerificationMeta('isCorrect');
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
      'is_correct', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_correct" IN (0, 1))'));
  static const VerificationMeta _timeSpentSecondsMeta =
      const VerificationMeta('timeSpentSeconds');
  @override
  late final GeneratedColumn<int> timeSpentSeconds = GeneratedColumn<int>(
      'time_spent_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _aiTutorInvocationsMeta =
      const VerificationMeta('aiTutorInvocations');
  @override
  late final GeneratedColumn<int> aiTutorInvocations = GeneratedColumn<int>(
      'ai_tutor_invocations', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _earnedXpMeta =
      const VerificationMeta('earnedXp');
  @override
  late final GeneratedColumn<int> earnedXp = GeneratedColumn<int>(
      'earned_xp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _solvedAtMeta =
      const VerificationMeta('solvedAt');
  @override
  late final GeneratedColumn<DateTime> solvedAt = GeneratedColumn<DateTime>(
      'solved_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PENDING'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        exerciseId,
        isCorrect,
        timeSpentSeconds,
        aiTutorInvocations,
        earnedXp,
        solvedAt,
        syncStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'telemetry_queue';
  @override
  VerificationContext validateIntegrity(Insertable<TelemetryRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('is_correct')) {
      context.handle(_isCorrectMeta,
          isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta));
    } else if (isInserting) {
      context.missing(_isCorrectMeta);
    }
    if (data.containsKey('time_spent_seconds')) {
      context.handle(
          _timeSpentSecondsMeta,
          timeSpentSeconds.isAcceptableOrUnknown(
              data['time_spent_seconds']!, _timeSpentSecondsMeta));
    } else if (isInserting) {
      context.missing(_timeSpentSecondsMeta);
    }
    if (data.containsKey('ai_tutor_invocations')) {
      context.handle(
          _aiTutorInvocationsMeta,
          aiTutorInvocations.isAcceptableOrUnknown(
              data['ai_tutor_invocations']!, _aiTutorInvocationsMeta));
    } else if (isInserting) {
      context.missing(_aiTutorInvocationsMeta);
    }
    if (data.containsKey('earned_xp')) {
      context.handle(_earnedXpMeta,
          earnedXp.isAcceptableOrUnknown(data['earned_xp']!, _earnedXpMeta));
    } else if (isInserting) {
      context.missing(_earnedXpMeta);
    }
    if (data.containsKey('solved_at')) {
      context.handle(_solvedAtMeta,
          solvedAt.isAcceptableOrUnknown(data['solved_at']!, _solvedAtMeta));
    } else if (isInserting) {
      context.missing(_solvedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TelemetryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TelemetryRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      isCorrect: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_correct'])!,
      timeSpentSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}time_spent_seconds'])!,
      aiTutorInvocations: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}ai_tutor_invocations'])!,
      earnedXp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}earned_xp'])!,
      solvedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}solved_at'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $TelemetryQueueTable createAlias(String alias) {
    return $TelemetryQueueTable(attachedDatabase, alias);
  }
}

class TelemetryRecord extends DataClass implements Insertable<TelemetryRecord> {
  final int id;
  final String userId;
  final String exerciseId;
  final bool isCorrect;
  final int timeSpentSeconds;
  final int aiTutorInvocations;
  final int earnedXp;
  final DateTime solvedAt;
  final String syncStatus;
  const TelemetryRecord(
      {required this.id,
      required this.userId,
      required this.exerciseId,
      required this.isCorrect,
      required this.timeSpentSeconds,
      required this.aiTutorInvocations,
      required this.earnedXp,
      required this.solvedAt,
      required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['is_correct'] = Variable<bool>(isCorrect);
    map['time_spent_seconds'] = Variable<int>(timeSpentSeconds);
    map['ai_tutor_invocations'] = Variable<int>(aiTutorInvocations);
    map['earned_xp'] = Variable<int>(earnedXp);
    map['solved_at'] = Variable<DateTime>(solvedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  TelemetryQueueCompanion toCompanion(bool nullToAbsent) {
    return TelemetryQueueCompanion(
      id: Value(id),
      userId: Value(userId),
      exerciseId: Value(exerciseId),
      isCorrect: Value(isCorrect),
      timeSpentSeconds: Value(timeSpentSeconds),
      aiTutorInvocations: Value(aiTutorInvocations),
      earnedXp: Value(earnedXp),
      solvedAt: Value(solvedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory TelemetryRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TelemetryRecord(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      isCorrect: serializer.fromJson<bool>(json['isCorrect']),
      timeSpentSeconds: serializer.fromJson<int>(json['timeSpentSeconds']),
      aiTutorInvocations: serializer.fromJson<int>(json['aiTutorInvocations']),
      earnedXp: serializer.fromJson<int>(json['earnedXp']),
      solvedAt: serializer.fromJson<DateTime>(json['solvedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'isCorrect': serializer.toJson<bool>(isCorrect),
      'timeSpentSeconds': serializer.toJson<int>(timeSpentSeconds),
      'aiTutorInvocations': serializer.toJson<int>(aiTutorInvocations),
      'earnedXp': serializer.toJson<int>(earnedXp),
      'solvedAt': serializer.toJson<DateTime>(solvedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  TelemetryRecord copyWith(
          {int? id,
          String? userId,
          String? exerciseId,
          bool? isCorrect,
          int? timeSpentSeconds,
          int? aiTutorInvocations,
          int? earnedXp,
          DateTime? solvedAt,
          String? syncStatus}) =>
      TelemetryRecord(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        exerciseId: exerciseId ?? this.exerciseId,
        isCorrect: isCorrect ?? this.isCorrect,
        timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
        aiTutorInvocations: aiTutorInvocations ?? this.aiTutorInvocations,
        earnedXp: earnedXp ?? this.earnedXp,
        solvedAt: solvedAt ?? this.solvedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
  TelemetryRecord copyWithCompanion(TelemetryQueueCompanion data) {
    return TelemetryRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      timeSpentSeconds: data.timeSpentSeconds.present
          ? data.timeSpentSeconds.value
          : this.timeSpentSeconds,
      aiTutorInvocations: data.aiTutorInvocations.present
          ? data.aiTutorInvocations.value
          : this.aiTutorInvocations,
      earnedXp: data.earnedXp.present ? data.earnedXp.value : this.earnedXp,
      solvedAt: data.solvedAt.present ? data.solvedAt.value : this.solvedAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TelemetryRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('timeSpentSeconds: $timeSpentSeconds, ')
          ..write('aiTutorInvocations: $aiTutorInvocations, ')
          ..write('earnedXp: $earnedXp, ')
          ..write('solvedAt: $solvedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, exerciseId, isCorrect,
      timeSpentSeconds, aiTutorInvocations, earnedXp, solvedAt, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TelemetryRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.exerciseId == this.exerciseId &&
          other.isCorrect == this.isCorrect &&
          other.timeSpentSeconds == this.timeSpentSeconds &&
          other.aiTutorInvocations == this.aiTutorInvocations &&
          other.earnedXp == this.earnedXp &&
          other.solvedAt == this.solvedAt &&
          other.syncStatus == this.syncStatus);
}

class TelemetryQueueCompanion extends UpdateCompanion<TelemetryRecord> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> exerciseId;
  final Value<bool> isCorrect;
  final Value<int> timeSpentSeconds;
  final Value<int> aiTutorInvocations;
  final Value<int> earnedXp;
  final Value<DateTime> solvedAt;
  final Value<String> syncStatus;
  const TelemetryQueueCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.timeSpentSeconds = const Value.absent(),
    this.aiTutorInvocations = const Value.absent(),
    this.earnedXp = const Value.absent(),
    this.solvedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
  });
  TelemetryQueueCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String exerciseId,
    required bool isCorrect,
    required int timeSpentSeconds,
    required int aiTutorInvocations,
    required int earnedXp,
    required DateTime solvedAt,
    this.syncStatus = const Value.absent(),
  })  : userId = Value(userId),
        exerciseId = Value(exerciseId),
        isCorrect = Value(isCorrect),
        timeSpentSeconds = Value(timeSpentSeconds),
        aiTutorInvocations = Value(aiTutorInvocations),
        earnedXp = Value(earnedXp),
        solvedAt = Value(solvedAt);
  static Insertable<TelemetryRecord> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? exerciseId,
    Expression<bool>? isCorrect,
    Expression<int>? timeSpentSeconds,
    Expression<int>? aiTutorInvocations,
    Expression<int>? earnedXp,
    Expression<DateTime>? solvedAt,
    Expression<String>? syncStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
      if (aiTutorInvocations != null)
        'ai_tutor_invocations': aiTutorInvocations,
      if (earnedXp != null) 'earned_xp': earnedXp,
      if (solvedAt != null) 'solved_at': solvedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
    });
  }

  TelemetryQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? userId,
      Value<String>? exerciseId,
      Value<bool>? isCorrect,
      Value<int>? timeSpentSeconds,
      Value<int>? aiTutorInvocations,
      Value<int>? earnedXp,
      Value<DateTime>? solvedAt,
      Value<String>? syncStatus}) {
    return TelemetryQueueCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      isCorrect: isCorrect ?? this.isCorrect,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      aiTutorInvocations: aiTutorInvocations ?? this.aiTutorInvocations,
      earnedXp: earnedXp ?? this.earnedXp,
      solvedAt: solvedAt ?? this.solvedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (timeSpentSeconds.present) {
      map['time_spent_seconds'] = Variable<int>(timeSpentSeconds.value);
    }
    if (aiTutorInvocations.present) {
      map['ai_tutor_invocations'] = Variable<int>(aiTutorInvocations.value);
    }
    if (earnedXp.present) {
      map['earned_xp'] = Variable<int>(earnedXp.value);
    }
    if (solvedAt.present) {
      map['solved_at'] = Variable<DateTime>(solvedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TelemetryQueueCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('timeSpentSeconds: $timeSpentSeconds, ')
          ..write('aiTutorInvocations: $aiTutorInvocations, ')
          ..write('earnedXp: $earnedXp, ')
          ..write('solvedAt: $solvedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $TelemetryQueueTable telemetryQueue = $TelemetryQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [exercises, telemetryQueue];
}

typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  required String id,
  required String moduleId,
  required String topic,
  required double difficultyMultiplier,
  required String contentJson,
  required String aiTutorMetadataJson,
  Value<int> rowid,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<String> id,
  Value<String> moduleId,
  Value<String> topic,
  Value<double> difficultyMultiplier,
  Value<String> contentJson,
  Value<String> aiTutorMetadataJson,
  Value<int> rowid,
});

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get moduleId => $composableBuilder(
      column: $table.moduleId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get topic => $composableBuilder(
      column: $table.topic, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get difficultyMultiplier => $composableBuilder(
      column: $table.difficultyMultiplier,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiTutorMetadataJson => $composableBuilder(
      column: $table.aiTutorMetadataJson,
      builder: (column) => ColumnFilters(column));
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get moduleId => $composableBuilder(
      column: $table.moduleId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get topic => $composableBuilder(
      column: $table.topic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get difficultyMultiplier => $composableBuilder(
      column: $table.difficultyMultiplier,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiTutorMetadataJson => $composableBuilder(
      column: $table.aiTutorMetadataJson,
      builder: (column) => ColumnOrderings(column));
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get moduleId =>
      $composableBuilder(column: $table.moduleId, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<double> get difficultyMultiplier => $composableBuilder(
      column: $table.difficultyMultiplier, builder: (column) => column);

  GeneratedColumn<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => column);

  GeneratedColumn<String> get aiTutorMetadataJson => $composableBuilder(
      column: $table.aiTutorMetadataJson, builder: (column) => column);
}

class $$ExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExercisesTable,
    ExerciseEntity,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (
      ExerciseEntity,
      BaseReferences<_$AppDatabase, $ExercisesTable, ExerciseEntity>
    ),
    ExerciseEntity,
    PrefetchHooks Function()> {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> moduleId = const Value.absent(),
            Value<String> topic = const Value.absent(),
            Value<double> difficultyMultiplier = const Value.absent(),
            Value<String> contentJson = const Value.absent(),
            Value<String> aiTutorMetadataJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExercisesCompanion(
            id: id,
            moduleId: moduleId,
            topic: topic,
            difficultyMultiplier: difficultyMultiplier,
            contentJson: contentJson,
            aiTutorMetadataJson: aiTutorMetadataJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String moduleId,
            required String topic,
            required double difficultyMultiplier,
            required String contentJson,
            required String aiTutorMetadataJson,
            Value<int> rowid = const Value.absent(),
          }) =>
              ExercisesCompanion.insert(
            id: id,
            moduleId: moduleId,
            topic: topic,
            difficultyMultiplier: difficultyMultiplier,
            contentJson: contentJson,
            aiTutorMetadataJson: aiTutorMetadataJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExercisesTable,
    ExerciseEntity,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (
      ExerciseEntity,
      BaseReferences<_$AppDatabase, $ExercisesTable, ExerciseEntity>
    ),
    ExerciseEntity,
    PrefetchHooks Function()>;
typedef $$TelemetryQueueTableCreateCompanionBuilder = TelemetryQueueCompanion
    Function({
  Value<int> id,
  required String userId,
  required String exerciseId,
  required bool isCorrect,
  required int timeSpentSeconds,
  required int aiTutorInvocations,
  required int earnedXp,
  required DateTime solvedAt,
  Value<String> syncStatus,
});
typedef $$TelemetryQueueTableUpdateCompanionBuilder = TelemetryQueueCompanion
    Function({
  Value<int> id,
  Value<String> userId,
  Value<String> exerciseId,
  Value<bool> isCorrect,
  Value<int> timeSpentSeconds,
  Value<int> aiTutorInvocations,
  Value<int> earnedXp,
  Value<DateTime> solvedAt,
  Value<String> syncStatus,
});

class $$TelemetryQueueTableFilterComposer
    extends Composer<_$AppDatabase, $TelemetryQueueTable> {
  $$TelemetryQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCorrect => $composableBuilder(
      column: $table.isCorrect, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeSpentSeconds => $composableBuilder(
      column: $table.timeSpentSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get aiTutorInvocations => $composableBuilder(
      column: $table.aiTutorInvocations,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get earnedXp => $composableBuilder(
      column: $table.earnedXp, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get solvedAt => $composableBuilder(
      column: $table.solvedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$TelemetryQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $TelemetryQueueTable> {
  $$TelemetryQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
      column: $table.isCorrect, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeSpentSeconds => $composableBuilder(
      column: $table.timeSpentSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get aiTutorInvocations => $composableBuilder(
      column: $table.aiTutorInvocations,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get earnedXp => $composableBuilder(
      column: $table.earnedXp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get solvedAt => $composableBuilder(
      column: $table.solvedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$TelemetryQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $TelemetryQueueTable> {
  $$TelemetryQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => column);

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<int> get timeSpentSeconds => $composableBuilder(
      column: $table.timeSpentSeconds, builder: (column) => column);

  GeneratedColumn<int> get aiTutorInvocations => $composableBuilder(
      column: $table.aiTutorInvocations, builder: (column) => column);

  GeneratedColumn<int> get earnedXp =>
      $composableBuilder(column: $table.earnedXp, builder: (column) => column);

  GeneratedColumn<DateTime> get solvedAt =>
      $composableBuilder(column: $table.solvedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);
}

class $$TelemetryQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TelemetryQueueTable,
    TelemetryRecord,
    $$TelemetryQueueTableFilterComposer,
    $$TelemetryQueueTableOrderingComposer,
    $$TelemetryQueueTableAnnotationComposer,
    $$TelemetryQueueTableCreateCompanionBuilder,
    $$TelemetryQueueTableUpdateCompanionBuilder,
    (
      TelemetryRecord,
      BaseReferences<_$AppDatabase, $TelemetryQueueTable, TelemetryRecord>
    ),
    TelemetryRecord,
    PrefetchHooks Function()> {
  $$TelemetryQueueTableTableManager(
      _$AppDatabase db, $TelemetryQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TelemetryQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TelemetryQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TelemetryQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> exerciseId = const Value.absent(),
            Value<bool> isCorrect = const Value.absent(),
            Value<int> timeSpentSeconds = const Value.absent(),
            Value<int> aiTutorInvocations = const Value.absent(),
            Value<int> earnedXp = const Value.absent(),
            Value<DateTime> solvedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
          }) =>
              TelemetryQueueCompanion(
            id: id,
            userId: userId,
            exerciseId: exerciseId,
            isCorrect: isCorrect,
            timeSpentSeconds: timeSpentSeconds,
            aiTutorInvocations: aiTutorInvocations,
            earnedXp: earnedXp,
            solvedAt: solvedAt,
            syncStatus: syncStatus,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String userId,
            required String exerciseId,
            required bool isCorrect,
            required int timeSpentSeconds,
            required int aiTutorInvocations,
            required int earnedXp,
            required DateTime solvedAt,
            Value<String> syncStatus = const Value.absent(),
          }) =>
              TelemetryQueueCompanion.insert(
            id: id,
            userId: userId,
            exerciseId: exerciseId,
            isCorrect: isCorrect,
            timeSpentSeconds: timeSpentSeconds,
            aiTutorInvocations: aiTutorInvocations,
            earnedXp: earnedXp,
            solvedAt: solvedAt,
            syncStatus: syncStatus,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TelemetryQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TelemetryQueueTable,
    TelemetryRecord,
    $$TelemetryQueueTableFilterComposer,
    $$TelemetryQueueTableOrderingComposer,
    $$TelemetryQueueTableAnnotationComposer,
    $$TelemetryQueueTableCreateCompanionBuilder,
    $$TelemetryQueueTableUpdateCompanionBuilder,
    (
      TelemetryRecord,
      BaseReferences<_$AppDatabase, $TelemetryQueueTable, TelemetryRecord>
    ),
    TelemetryRecord,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$TelemetryQueueTableTableManager get telemetryQueue =>
      $$TelemetryQueueTableTableManager(_db, _db.telemetryQueue);
}
