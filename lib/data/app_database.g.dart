// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _gpsThresholdMMeta =
      const VerificationMeta('gpsThresholdM');
  @override
  late final GeneratedColumn<double> gpsThresholdM = GeneratedColumn<double>(
      'gps_threshold_m', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _externalIdMeta =
      const VerificationMeta('externalId');
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
      'external_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _projectVersionMeta =
      const VerificationMeta('projectVersion');
  @override
  late final GeneratedColumn<int> projectVersion = GeneratedColumn<int>(
      'project_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        archived,
        gpsThresholdM,
        createdAt,
        isActive,
        externalId,
        projectVersion
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<Project> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('gps_threshold_m')) {
      context.handle(
          _gpsThresholdMMeta,
          gpsThresholdM.isAcceptableOrUnknown(
              data['gps_threshold_m']!, _gpsThresholdMMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('external_id')) {
      context.handle(
          _externalIdMeta,
          externalId.isAcceptableOrUnknown(
              data['external_id']!, _externalIdMeta));
    }
    if (data.containsKey('project_version')) {
      context.handle(
          _projectVersionMeta,
          projectVersion.isAcceptableOrUnknown(
              data['project_version']!, _projectVersionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      gpsThresholdM: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}gps_threshold_m'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      externalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}external_id']),
      projectVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_version'])!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final int id;
  final String name;
  final String description;
  final bool archived;
  final double gpsThresholdM;
  final DateTime createdAt;
  final bool isActive;

  /// Stable cross-device project identity used by the .mbproj package
  /// format. Null on databases migrated to schema 8 before any project was
  /// created; created/imported projects always get a value.
  final String? externalId;

  /// Project definition version; preserved across export/import.
  final int projectVersion;
  const Project(
      {required this.id,
      required this.name,
      required this.description,
      required this.archived,
      required this.gpsThresholdM,
      required this.createdAt,
      required this.isActive,
      this.externalId,
      required this.projectVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['archived'] = Variable<bool>(archived);
    map['gps_threshold_m'] = Variable<double>(gpsThresholdM);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    map['project_version'] = Variable<int>(projectVersion);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      archived: Value(archived),
      gpsThresholdM: Value(gpsThresholdM),
      createdAt: Value(createdAt),
      isActive: Value(isActive),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      projectVersion: Value(projectVersion),
    );
  }

  factory Project.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      archived: serializer.fromJson<bool>(json['archived']),
      gpsThresholdM: serializer.fromJson<double>(json['gpsThresholdM']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      projectVersion: serializer.fromJson<int>(json['projectVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'archived': serializer.toJson<bool>(archived),
      'gpsThresholdM': serializer.toJson<double>(gpsThresholdM),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isActive': serializer.toJson<bool>(isActive),
      'externalId': serializer.toJson<String?>(externalId),
      'projectVersion': serializer.toJson<int>(projectVersion),
    };
  }

  Project copyWith(
          {int? id,
          String? name,
          String? description,
          bool? archived,
          double? gpsThresholdM,
          DateTime? createdAt,
          bool? isActive,
          Value<String?> externalId = const Value.absent(),
          int? projectVersion}) =>
      Project(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        archived: archived ?? this.archived,
        gpsThresholdM: gpsThresholdM ?? this.gpsThresholdM,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
        externalId: externalId.present ? externalId.value : this.externalId,
        projectVersion: projectVersion ?? this.projectVersion,
      );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      archived: data.archived.present ? data.archived.value : this.archived,
      gpsThresholdM: data.gpsThresholdM.present
          ? data.gpsThresholdM.value
          : this.gpsThresholdM,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      externalId:
          data.externalId.present ? data.externalId.value : this.externalId,
      projectVersion: data.projectVersion.present
          ? data.projectVersion.value
          : this.projectVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('archived: $archived, ')
          ..write('gpsThresholdM: $gpsThresholdM, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive, ')
          ..write('externalId: $externalId, ')
          ..write('projectVersion: $projectVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, archived,
      gpsThresholdM, createdAt, isActive, externalId, projectVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.archived == this.archived &&
          other.gpsThresholdM == this.gpsThresholdM &&
          other.createdAt == this.createdAt &&
          other.isActive == this.isActive &&
          other.externalId == this.externalId &&
          other.projectVersion == this.projectVersion);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> description;
  final Value<bool> archived;
  final Value<double> gpsThresholdM;
  final Value<DateTime> createdAt;
  final Value<bool> isActive;
  final Value<String?> externalId;
  final Value<int> projectVersion;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.archived = const Value.absent(),
    this.gpsThresholdM = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.externalId = const Value.absent(),
    this.projectVersion = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.archived = const Value.absent(),
    this.gpsThresholdM = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.externalId = const Value.absent(),
    this.projectVersion = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Project> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? archived,
    Expression<double>? gpsThresholdM,
    Expression<DateTime>? createdAt,
    Expression<bool>? isActive,
    Expression<String>? externalId,
    Expression<int>? projectVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (archived != null) 'archived': archived,
      if (gpsThresholdM != null) 'gps_threshold_m': gpsThresholdM,
      if (createdAt != null) 'created_at': createdAt,
      if (isActive != null) 'is_active': isActive,
      if (externalId != null) 'external_id': externalId,
      if (projectVersion != null) 'project_version': projectVersion,
    });
  }

  ProjectsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? description,
      Value<bool>? archived,
      Value<double>? gpsThresholdM,
      Value<DateTime>? createdAt,
      Value<bool>? isActive,
      Value<String?>? externalId,
      Value<int>? projectVersion}) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      archived: archived ?? this.archived,
      gpsThresholdM: gpsThresholdM ?? this.gpsThresholdM,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      externalId: externalId ?? this.externalId,
      projectVersion: projectVersion ?? this.projectVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (gpsThresholdM.present) {
      map['gps_threshold_m'] = Variable<double>(gpsThresholdM.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (projectVersion.present) {
      map['project_version'] = Variable<int>(projectVersion.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('archived: $archived, ')
          ..write('gpsThresholdM: $gpsThresholdM, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive, ')
          ..write('externalId: $externalId, ')
          ..write('projectVersion: $projectVersion')
          ..write(')'))
        .toString();
  }
}

class $SurveySessionsTable extends SurveySessions
    with TableInfo<$SurveySessionsTable, SurveySession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveySessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES projects (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _responsesMeta =
      const VerificationMeta('responses');
  @override
  late final GeneratedColumn<String> responses = GeneratedColumn<String>(
      'responses', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _photoSyncedAtMeta =
      const VerificationMeta('photoSyncedAt');
  @override
  late final GeneratedColumn<DateTime> photoSyncedAt =
      GeneratedColumn<DateTime>('photo_synced_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _externalIdMeta =
      const VerificationMeta('externalId');
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
      'external_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        title,
        status,
        responses,
        createdAt,
        syncedAt,
        photoSyncedAt,
        externalId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'survey_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<SurveySession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('responses')) {
      context.handle(_responsesMeta,
          responses.isAcceptableOrUnknown(data['responses']!, _responsesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('photo_synced_at')) {
      context.handle(
          _photoSyncedAtMeta,
          photoSyncedAt.isAcceptableOrUnknown(
              data['photo_synced_at']!, _photoSyncedAtMeta));
    }
    if (data.containsKey('external_id')) {
      context.handle(
          _externalIdMeta,
          externalId.isAcceptableOrUnknown(
              data['external_id']!, _externalIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurveySession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurveySession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      responses: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}responses'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      photoSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}photo_synced_at']),
      externalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}external_id']),
    );
  }

  @override
  $SurveySessionsTable createAlias(String alias) {
    return $SurveySessionsTable(attachedDatabase, alias);
  }
}

class SurveySession extends DataClass implements Insertable<SurveySession> {
  final int id;
  final int projectId;
  final String title;
  final String status;
  final String responses;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final DateTime? photoSyncedAt;

  /// Stable cross-device identity for sync deduplication. Generated once at
  /// creation time (UUID v4), not at sync time, and preserved via .mbproj
  /// if sessions were ever exported.
  final String? externalId;
  const SurveySession(
      {required this.id,
      required this.projectId,
      required this.title,
      required this.status,
      required this.responses,
      required this.createdAt,
      this.syncedAt,
      this.photoSyncedAt,
      this.externalId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['title'] = Variable<String>(title);
    map['status'] = Variable<String>(status);
    map['responses'] = Variable<String>(responses);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || photoSyncedAt != null) {
      map['photo_synced_at'] = Variable<DateTime>(photoSyncedAt);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    return map;
  }

  SurveySessionsCompanion toCompanion(bool nullToAbsent) {
    return SurveySessionsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      title: Value(title),
      status: Value(status),
      responses: Value(responses),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      photoSyncedAt: photoSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(photoSyncedAt),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
    );
  }

  factory SurveySession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurveySession(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      title: serializer.fromJson<String>(json['title']),
      status: serializer.fromJson<String>(json['status']),
      responses: serializer.fromJson<String>(json['responses']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      photoSyncedAt: serializer.fromJson<DateTime?>(json['photoSyncedAt']),
      externalId: serializer.fromJson<String?>(json['externalId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<String>(status),
      'responses': serializer.toJson<String>(responses),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'photoSyncedAt': serializer.toJson<DateTime?>(photoSyncedAt),
      'externalId': serializer.toJson<String?>(externalId),
    };
  }

  SurveySession copyWith(
          {int? id,
          int? projectId,
          String? title,
          String? status,
          String? responses,
          DateTime? createdAt,
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<DateTime?> photoSyncedAt = const Value.absent(),
          Value<String?> externalId = const Value.absent()}) =>
      SurveySession(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        title: title ?? this.title,
        status: status ?? this.status,
        responses: responses ?? this.responses,
        createdAt: createdAt ?? this.createdAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        photoSyncedAt:
            photoSyncedAt.present ? photoSyncedAt.value : this.photoSyncedAt,
        externalId: externalId.present ? externalId.value : this.externalId,
      );
  SurveySession copyWithCompanion(SurveySessionsCompanion data) {
    return SurveySession(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      responses: data.responses.present ? data.responses.value : this.responses,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      photoSyncedAt: data.photoSyncedAt.present
          ? data.photoSyncedAt.value
          : this.photoSyncedAt,
      externalId:
          data.externalId.present ? data.externalId.value : this.externalId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurveySession(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('responses: $responses, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('photoSyncedAt: $photoSyncedAt, ')
          ..write('externalId: $externalId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, title, status, responses,
      createdAt, syncedAt, photoSyncedAt, externalId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurveySession &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.title == this.title &&
          other.status == this.status &&
          other.responses == this.responses &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt &&
          other.photoSyncedAt == this.photoSyncedAt &&
          other.externalId == this.externalId);
}

class SurveySessionsCompanion extends UpdateCompanion<SurveySession> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String> title;
  final Value<String> status;
  final Value<String> responses;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> photoSyncedAt;
  final Value<String?> externalId;
  const SurveySessionsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.responses = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.photoSyncedAt = const Value.absent(),
    this.externalId = const Value.absent(),
  });
  SurveySessionsCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required String title,
    this.status = const Value.absent(),
    this.responses = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.photoSyncedAt = const Value.absent(),
    this.externalId = const Value.absent(),
  })  : projectId = Value(projectId),
        title = Value(title);
  static Insertable<SurveySession> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? title,
    Expression<String>? status,
    Expression<String>? responses,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? photoSyncedAt,
    Expression<String>? externalId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (responses != null) 'responses': responses,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (photoSyncedAt != null) 'photo_synced_at': photoSyncedAt,
      if (externalId != null) 'external_id': externalId,
    });
  }

  SurveySessionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<String>? title,
      Value<String>? status,
      Value<String>? responses,
      Value<DateTime>? createdAt,
      Value<DateTime?>? syncedAt,
      Value<DateTime?>? photoSyncedAt,
      Value<String?>? externalId}) {
    return SurveySessionsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      status: status ?? this.status,
      responses: responses ?? this.responses,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      photoSyncedAt: photoSyncedAt ?? this.photoSyncedAt,
      externalId: externalId ?? this.externalId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (responses.present) {
      map['responses'] = Variable<String>(responses.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (photoSyncedAt.present) {
      map['photo_synced_at'] = Variable<DateTime>(photoSyncedAt.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveySessionsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('responses: $responses, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('photoSyncedAt: $photoSyncedAt, ')
          ..write('externalId: $externalId')
          ..write(')'))
        .toString();
  }
}

class $StoredFormsTable extends StoredForms
    with TableInfo<$StoredFormsTable, StoredForm> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredFormsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES projects (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, projectId, name, description, json, version, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_forms';
  @override
  VerificationContext validateIntegrity(Insertable<StoredForm> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredForm map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredForm(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $StoredFormsTable createAlias(String alias) {
    return $StoredFormsTable(attachedDatabase, alias);
  }
}

class StoredForm extends DataClass implements Insertable<StoredForm> {
  final int id;
  final int? projectId;
  final String name;
  final String description;
  final String json;
  final int version;
  final DateTime createdAt;
  const StoredForm(
      {required this.id,
      this.projectId,
      required this.name,
      required this.description,
      required this.json,
      required this.version,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<int>(projectId);
    }
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['json'] = Variable<String>(json);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StoredFormsCompanion toCompanion(bool nullToAbsent) {
    return StoredFormsCompanion(
      id: Value(id),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      name: Value(name),
      description: Value(description),
      json: Value(json),
      version: Value(version),
      createdAt: Value(createdAt),
    );
  }

  factory StoredForm.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredForm(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int?>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      json: serializer.fromJson<String>(json['json']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int?>(projectId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'json': serializer.toJson<String>(json),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StoredForm copyWith(
          {int? id,
          Value<int?> projectId = const Value.absent(),
          String? name,
          String? description,
          String? json,
          int? version,
          DateTime? createdAt}) =>
      StoredForm(
        id: id ?? this.id,
        projectId: projectId.present ? projectId.value : this.projectId,
        name: name ?? this.name,
        description: description ?? this.description,
        json: json ?? this.json,
        version: version ?? this.version,
        createdAt: createdAt ?? this.createdAt,
      );
  StoredForm copyWithCompanion(StoredFormsCompanion data) {
    return StoredForm(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      json: data.json.present ? data.json.value : this.json,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredForm(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('json: $json, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, projectId, name, description, json, version, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredForm &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.description == this.description &&
          other.json == this.json &&
          other.version == this.version &&
          other.createdAt == this.createdAt);
}

class StoredFormsCompanion extends UpdateCompanion<StoredForm> {
  final Value<int> id;
  final Value<int?> projectId;
  final Value<String> name;
  final Value<String> description;
  final Value<String> json;
  final Value<int> version;
  final Value<DateTime> createdAt;
  const StoredFormsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.json = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StoredFormsCompanion.insert({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required String json,
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        json = Value(json);
  static Insertable<StoredForm> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? json,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (json != null) 'json': json,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StoredFormsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? projectId,
      Value<String>? name,
      Value<String>? description,
      Value<String>? json,
      Value<int>? version,
      Value<DateTime>? createdAt}) {
    return StoredFormsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      json: json ?? this.json,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredFormsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('json: $json, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) => AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GpsLogsTable extends GpsLogs with TableInfo<$GpsLogsTable, GpsLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GpsLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surveyorMeta =
      const VerificationMeta('surveyor');
  @override
  late final GeneratedColumn<String> surveyor = GeneratedColumn<String>(
      'surveyor', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, name, surveyor, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gps_logs';
  @override
  VerificationContext validateIntegrity(Insertable<GpsLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('surveyor')) {
      context.handle(_surveyorMeta,
          surveyor.isAcceptableOrUnknown(data['surveyor']!, _surveyorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GpsLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GpsLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      surveyor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}surveyor'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $GpsLogsTable createAlias(String alias) {
    return $GpsLogsTable(attachedDatabase, alias);
  }
}

class GpsLog extends DataClass implements Insertable<GpsLog> {
  final int id;
  final String name;
  final String surveyor;
  final DateTime createdAt;
  const GpsLog(
      {required this.id,
      required this.name,
      required this.surveyor,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['surveyor'] = Variable<String>(surveyor);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GpsLogsCompanion toCompanion(bool nullToAbsent) {
    return GpsLogsCompanion(
      id: Value(id),
      name: Value(name),
      surveyor: Value(surveyor),
      createdAt: Value(createdAt),
    );
  }

  factory GpsLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GpsLog(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      surveyor: serializer.fromJson<String>(json['surveyor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'surveyor': serializer.toJson<String>(surveyor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GpsLog copyWith(
          {int? id, String? name, String? surveyor, DateTime? createdAt}) =>
      GpsLog(
        id: id ?? this.id,
        name: name ?? this.name,
        surveyor: surveyor ?? this.surveyor,
        createdAt: createdAt ?? this.createdAt,
      );
  GpsLog copyWithCompanion(GpsLogsCompanion data) {
    return GpsLog(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      surveyor: data.surveyor.present ? data.surveyor.value : this.surveyor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GpsLog(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('surveyor: $surveyor, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, surveyor, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GpsLog &&
          other.id == this.id &&
          other.name == this.name &&
          other.surveyor == this.surveyor &&
          other.createdAt == this.createdAt);
}

class GpsLogsCompanion extends UpdateCompanion<GpsLog> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> surveyor;
  final Value<DateTime> createdAt;
  const GpsLogsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.surveyor = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GpsLogsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.surveyor = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<GpsLog> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? surveyor,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (surveyor != null) 'surveyor': surveyor,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GpsLogsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? surveyor,
      Value<DateTime>? createdAt}) {
    return GpsLogsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      surveyor: surveyor ?? this.surveyor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (surveyor.present) {
      map['surveyor'] = Variable<String>(surveyor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GpsLogsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('surveyor: $surveyor, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ProjectFieldsTable extends ProjectFields
    with TableInfo<$ProjectFieldsTable, ProjectField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES projects (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, projectId, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_fields';
  @override
  VerificationContext validateIntegrity(Insertable<ProjectField> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectField(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ProjectFieldsTable createAlias(String alias) {
    return $ProjectFieldsTable(attachedDatabase, alias);
  }
}

class ProjectField extends DataClass implements Insertable<ProjectField> {
  final int id;
  final int projectId;
  final String name;
  final DateTime createdAt;
  const ProjectField(
      {required this.id,
      required this.projectId,
      required this.name,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProjectFieldsCompanion toCompanion(bool nullToAbsent) {
    return ProjectFieldsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory ProjectField.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectField(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProjectField copyWith(
          {int? id, int? projectId, String? name, DateTime? createdAt}) =>
      ProjectField(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  ProjectField copyWithCompanion(ProjectFieldsCompanion data) {
    return ProjectField(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectField(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectField &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class ProjectFieldsCompanion extends UpdateCompanion<ProjectField> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const ProjectFieldsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProjectFieldsCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required String name,
    this.createdAt = const Value.absent(),
  })  : projectId = Value(projectId),
        name = Value(name);
  static Insertable<ProjectField> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProjectFieldsCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<String>? name,
      Value<DateTime>? createdAt}) {
    return ProjectFieldsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectFieldsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SyncConfigsTable extends SyncConfigs
    with TableInfo<$SyncConfigsTable, SyncConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES projects (id) ON DELETE CASCADE'));
  static const VerificationMeta _syncEndpointUrlMeta =
      const VerificationMeta('syncEndpointUrl');
  @override
  late final GeneratedColumn<String> syncEndpointUrl = GeneratedColumn<String>(
      'sync_endpoint_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncApiKeyMeta =
      const VerificationMeta('syncApiKey');
  @override
  late final GeneratedColumn<String> syncApiKey = GeneratedColumn<String>(
      'sync_api_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
      'last_sync_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [projectId, syncEndpointUrl, syncApiKey, lastSyncAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_configs';
  @override
  VerificationContext validateIntegrity(Insertable<SyncConfig> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    }
    if (data.containsKey('sync_endpoint_url')) {
      context.handle(
          _syncEndpointUrlMeta,
          syncEndpointUrl.isAcceptableOrUnknown(
              data['sync_endpoint_url']!, _syncEndpointUrlMeta));
    }
    if (data.containsKey('sync_api_key')) {
      context.handle(
          _syncApiKeyMeta,
          syncApiKey.isAcceptableOrUnknown(
              data['sync_api_key']!, _syncApiKeyMeta));
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {projectId};
  @override
  SyncConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConfig(
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      syncEndpointUrl: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sync_endpoint_url']),
      syncApiKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_api_key']),
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync_at']),
    );
  }

  @override
  $SyncConfigsTable createAlias(String alias) {
    return $SyncConfigsTable(attachedDatabase, alias);
  }
}

class SyncConfig extends DataClass implements Insertable<SyncConfig> {
  final int projectId;
  final String? syncEndpointUrl;
  final String? syncApiKey;
  final DateTime? lastSyncAt;
  const SyncConfig(
      {required this.projectId,
      this.syncEndpointUrl,
      this.syncApiKey,
      this.lastSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['project_id'] = Variable<int>(projectId);
    if (!nullToAbsent || syncEndpointUrl != null) {
      map['sync_endpoint_url'] = Variable<String>(syncEndpointUrl);
    }
    if (!nullToAbsent || syncApiKey != null) {
      map['sync_api_key'] = Variable<String>(syncApiKey);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  SyncConfigsCompanion toCompanion(bool nullToAbsent) {
    return SyncConfigsCompanion(
      projectId: Value(projectId),
      syncEndpointUrl: syncEndpointUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(syncEndpointUrl),
      syncApiKey: syncApiKey == null && nullToAbsent
          ? const Value.absent()
          : Value(syncApiKey),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory SyncConfig.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConfig(
      projectId: serializer.fromJson<int>(json['projectId']),
      syncEndpointUrl: serializer.fromJson<String?>(json['syncEndpointUrl']),
      syncApiKey: serializer.fromJson<String?>(json['syncApiKey']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'projectId': serializer.toJson<int>(projectId),
      'syncEndpointUrl': serializer.toJson<String?>(syncEndpointUrl),
      'syncApiKey': serializer.toJson<String?>(syncApiKey),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  SyncConfig copyWith(
          {int? projectId,
          Value<String?> syncEndpointUrl = const Value.absent(),
          Value<String?> syncApiKey = const Value.absent(),
          Value<DateTime?> lastSyncAt = const Value.absent()}) =>
      SyncConfig(
        projectId: projectId ?? this.projectId,
        syncEndpointUrl: syncEndpointUrl.present
            ? syncEndpointUrl.value
            : this.syncEndpointUrl,
        syncApiKey: syncApiKey.present ? syncApiKey.value : this.syncApiKey,
        lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
      );
  SyncConfig copyWithCompanion(SyncConfigsCompanion data) {
    return SyncConfig(
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      syncEndpointUrl: data.syncEndpointUrl.present
          ? data.syncEndpointUrl.value
          : this.syncEndpointUrl,
      syncApiKey:
          data.syncApiKey.present ? data.syncApiKey.value : this.syncApiKey,
      lastSyncAt:
          data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConfig(')
          ..write('projectId: $projectId, ')
          ..write('syncEndpointUrl: $syncEndpointUrl, ')
          ..write('syncApiKey: $syncApiKey, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(projectId, syncEndpointUrl, syncApiKey, lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConfig &&
          other.projectId == this.projectId &&
          other.syncEndpointUrl == this.syncEndpointUrl &&
          other.syncApiKey == this.syncApiKey &&
          other.lastSyncAt == this.lastSyncAt);
}

class SyncConfigsCompanion extends UpdateCompanion<SyncConfig> {
  final Value<int> projectId;
  final Value<String?> syncEndpointUrl;
  final Value<String?> syncApiKey;
  final Value<DateTime?> lastSyncAt;
  const SyncConfigsCompanion({
    this.projectId = const Value.absent(),
    this.syncEndpointUrl = const Value.absent(),
    this.syncApiKey = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
  });
  SyncConfigsCompanion.insert({
    this.projectId = const Value.absent(),
    this.syncEndpointUrl = const Value.absent(),
    this.syncApiKey = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
  });
  static Insertable<SyncConfig> custom({
    Expression<int>? projectId,
    Expression<String>? syncEndpointUrl,
    Expression<String>? syncApiKey,
    Expression<DateTime>? lastSyncAt,
  }) {
    return RawValuesInsertable({
      if (projectId != null) 'project_id': projectId,
      if (syncEndpointUrl != null) 'sync_endpoint_url': syncEndpointUrl,
      if (syncApiKey != null) 'sync_api_key': syncApiKey,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
    });
  }

  SyncConfigsCompanion copyWith(
      {Value<int>? projectId,
      Value<String?>? syncEndpointUrl,
      Value<String?>? syncApiKey,
      Value<DateTime?>? lastSyncAt}) {
    return SyncConfigsCompanion(
      projectId: projectId ?? this.projectId,
      syncEndpointUrl: syncEndpointUrl ?? this.syncEndpointUrl,
      syncApiKey: syncApiKey ?? this.syncApiKey,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (syncEndpointUrl.present) {
      map['sync_endpoint_url'] = Variable<String>(syncEndpointUrl.value);
    }
    if (syncApiKey.present) {
      map['sync_api_key'] = Variable<String>(syncApiKey.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConfigsCompanion(')
          ..write('projectId: $projectId, ')
          ..write('syncEndpointUrl: $syncEndpointUrl, ')
          ..write('syncApiKey: $syncApiKey, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $SurveySessionsTable surveySessions = $SurveySessionsTable(this);
  late final $StoredFormsTable storedForms = $StoredFormsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $GpsLogsTable gpsLogs = $GpsLogsTable(this);
  late final $ProjectFieldsTable projectFields = $ProjectFieldsTable(this);
  late final $SyncConfigsTable syncConfigs = $SyncConfigsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        projects,
        surveySessions,
        storedForms,
        appSettings,
        gpsLogs,
        projectFields,
        syncConfigs
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('projects',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('sync_configs', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  required String name,
  Value<String> description,
  Value<bool> archived,
  Value<double> gpsThresholdM,
  Value<DateTime> createdAt,
  Value<bool> isActive,
  Value<String?> externalId,
  Value<int> projectVersion,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> description,
  Value<bool> archived,
  Value<double> gpsThresholdM,
  Value<DateTime> createdAt,
  Value<bool> isActive,
  Value<String?> externalId,
  Value<int> projectVersion,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SurveySessionsTable, List<SurveySession>>
      _surveySessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.surveySessions,
              aliasName: $_aliasNameGenerator(
                  db.projects.id, db.surveySessions.projectId));

  $$SurveySessionsTableProcessedTableManager get surveySessionsRefs {
    final manager = $$SurveySessionsTableTableManager($_db, $_db.surveySessions)
        .filter((f) => f.projectId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_surveySessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StoredFormsTable, List<StoredForm>>
      _storedFormsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.storedForms,
          aliasName:
              $_aliasNameGenerator(db.projects.id, db.storedForms.projectId));

  $$StoredFormsTableProcessedTableManager get storedFormsRefs {
    final manager = $$StoredFormsTableTableManager($_db, $_db.storedForms)
        .filter((f) => f.projectId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_storedFormsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ProjectFieldsTable, List<ProjectField>>
      _projectFieldsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.projectFields,
              aliasName: $_aliasNameGenerator(
                  db.projects.id, db.projectFields.projectId));

  $$ProjectFieldsTableProcessedTableManager get projectFieldsRefs {
    final manager = $$ProjectFieldsTableTableManager($_db, $_db.projectFields)
        .filter((f) => f.projectId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_projectFieldsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SyncConfigsTable, List<SyncConfig>>
      _syncConfigsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.syncConfigs,
          aliasName:
              $_aliasNameGenerator(db.projects.id, db.syncConfigs.projectId));

  $$SyncConfigsTableProcessedTableManager get syncConfigsRefs {
    final manager = $$SyncConfigsTableTableManager($_db, $_db.syncConfigs)
        .filter((f) => f.projectId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_syncConfigsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get gpsThresholdM => $composableBuilder(
      column: $table.gpsThresholdM, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectVersion => $composableBuilder(
      column: $table.projectVersion,
      builder: (column) => ColumnFilters(column));

  Expression<bool> surveySessionsRefs(
      Expression<bool> Function($$SurveySessionsTableFilterComposer f) f) {
    final $$SurveySessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.surveySessions,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SurveySessionsTableFilterComposer(
              $db: $db,
              $table: $db.surveySessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> storedFormsRefs(
      Expression<bool> Function($$StoredFormsTableFilterComposer f) f) {
    final $$StoredFormsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.storedForms,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoredFormsTableFilterComposer(
              $db: $db,
              $table: $db.storedForms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> projectFieldsRefs(
      Expression<bool> Function($$ProjectFieldsTableFilterComposer f) f) {
    final $$ProjectFieldsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.projectFields,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectFieldsTableFilterComposer(
              $db: $db,
              $table: $db.projectFields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> syncConfigsRefs(
      Expression<bool> Function($$SyncConfigsTableFilterComposer f) f) {
    final $$SyncConfigsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.syncConfigs,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SyncConfigsTableFilterComposer(
              $db: $db,
              $table: $db.syncConfigs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get gpsThresholdM => $composableBuilder(
      column: $table.gpsThresholdM,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectVersion => $composableBuilder(
      column: $table.projectVersion,
      builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<double> get gpsThresholdM => $composableBuilder(
      column: $table.gpsThresholdM, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => column);

  GeneratedColumn<int> get projectVersion => $composableBuilder(
      column: $table.projectVersion, builder: (column) => column);

  Expression<T> surveySessionsRefs<T extends Object>(
      Expression<T> Function($$SurveySessionsTableAnnotationComposer a) f) {
    final $$SurveySessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.surveySessions,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SurveySessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.surveySessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> storedFormsRefs<T extends Object>(
      Expression<T> Function($$StoredFormsTableAnnotationComposer a) f) {
    final $$StoredFormsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.storedForms,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoredFormsTableAnnotationComposer(
              $db: $db,
              $table: $db.storedForms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> projectFieldsRefs<T extends Object>(
      Expression<T> Function($$ProjectFieldsTableAnnotationComposer a) f) {
    final $$ProjectFieldsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.projectFields,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectFieldsTableAnnotationComposer(
              $db: $db,
              $table: $db.projectFields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> syncConfigsRefs<T extends Object>(
      Expression<T> Function($$SyncConfigsTableAnnotationComposer a) f) {
    final $$SyncConfigsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.syncConfigs,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SyncConfigsTableAnnotationComposer(
              $db: $db,
              $table: $db.syncConfigs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function(
        {bool surveySessionsRefs,
        bool storedFormsRefs,
        bool projectFieldsRefs,
        bool syncConfigsRefs})> {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<double> gpsThresholdM = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> externalId = const Value.absent(),
            Value<int> projectVersion = const Value.absent(),
          }) =>
              ProjectsCompanion(
            id: id,
            name: name,
            description: description,
            archived: archived,
            gpsThresholdM: gpsThresholdM,
            createdAt: createdAt,
            isActive: isActive,
            externalId: externalId,
            projectVersion: projectVersion,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> description = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<double> gpsThresholdM = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> externalId = const Value.absent(),
            Value<int> projectVersion = const Value.absent(),
          }) =>
              ProjectsCompanion.insert(
            id: id,
            name: name,
            description: description,
            archived: archived,
            gpsThresholdM: gpsThresholdM,
            createdAt: createdAt,
            isActive: isActive,
            externalId: externalId,
            projectVersion: projectVersion,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProjectsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {surveySessionsRefs = false,
              storedFormsRefs = false,
              projectFieldsRefs = false,
              syncConfigsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (surveySessionsRefs) db.surveySessions,
                if (storedFormsRefs) db.storedForms,
                if (projectFieldsRefs) db.projectFields,
                if (syncConfigsRefs) db.syncConfigs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (surveySessionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ProjectsTableReferences
                            ._surveySessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0)
                                .surveySessionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items),
                  if (storedFormsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$ProjectsTableReferences._storedFormsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0)
                                .storedFormsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items),
                  if (projectFieldsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ProjectsTableReferences
                            ._projectFieldsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0)
                                .projectFieldsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items),
                  if (syncConfigsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$ProjectsTableReferences._syncConfigsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0)
                                .syncConfigsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function(
        {bool surveySessionsRefs,
        bool storedFormsRefs,
        bool projectFieldsRefs,
        bool syncConfigsRefs})>;
typedef $$SurveySessionsTableCreateCompanionBuilder = SurveySessionsCompanion
    Function({
  Value<int> id,
  required int projectId,
  required String title,
  Value<String> status,
  Value<String> responses,
  Value<DateTime> createdAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> photoSyncedAt,
  Value<String?> externalId,
});
typedef $$SurveySessionsTableUpdateCompanionBuilder = SurveySessionsCompanion
    Function({
  Value<int> id,
  Value<int> projectId,
  Value<String> title,
  Value<String> status,
  Value<String> responses,
  Value<DateTime> createdAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> photoSyncedAt,
  Value<String?> externalId,
});

final class $$SurveySessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SurveySessionsTable, SurveySession> {
  $$SurveySessionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias(
          $_aliasNameGenerator(db.surveySessions.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager get projectId {
    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id($_item.projectId));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SurveySessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SurveySessionsTable> {
  $$SurveySessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get responses => $composableBuilder(
      column: $table.responses, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get photoSyncedAt => $composableBuilder(
      column: $table.photoSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SurveySessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SurveySessionsTable> {
  $$SurveySessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get responses => $composableBuilder(
      column: $table.responses, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get photoSyncedAt => $composableBuilder(
      column: $table.photoSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SurveySessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurveySessionsTable> {
  $$SurveySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get responses =>
      $composableBuilder(column: $table.responses, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get photoSyncedAt => $composableBuilder(
      column: $table.photoSyncedAt, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SurveySessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SurveySessionsTable,
    SurveySession,
    $$SurveySessionsTableFilterComposer,
    $$SurveySessionsTableOrderingComposer,
    $$SurveySessionsTableAnnotationComposer,
    $$SurveySessionsTableCreateCompanionBuilder,
    $$SurveySessionsTableUpdateCompanionBuilder,
    (SurveySession, $$SurveySessionsTableReferences),
    SurveySession,
    PrefetchHooks Function({bool projectId})> {
  $$SurveySessionsTableTableManager(
      _$AppDatabase db, $SurveySessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveySessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> responses = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> photoSyncedAt = const Value.absent(),
            Value<String?> externalId = const Value.absent(),
          }) =>
              SurveySessionsCompanion(
            id: id,
            projectId: projectId,
            title: title,
            status: status,
            responses: responses,
            createdAt: createdAt,
            syncedAt: syncedAt,
            photoSyncedAt: photoSyncedAt,
            externalId: externalId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required String title,
            Value<String> status = const Value.absent(),
            Value<String> responses = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> photoSyncedAt = const Value.absent(),
            Value<String?> externalId = const Value.absent(),
          }) =>
              SurveySessionsCompanion.insert(
            id: id,
            projectId: projectId,
            title: title,
            status: status,
            responses: responses,
            createdAt: createdAt,
            syncedAt: syncedAt,
            photoSyncedAt: photoSyncedAt,
            externalId: externalId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SurveySessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable:
                        $$SurveySessionsTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$SurveySessionsTableReferences._projectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SurveySessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SurveySessionsTable,
    SurveySession,
    $$SurveySessionsTableFilterComposer,
    $$SurveySessionsTableOrderingComposer,
    $$SurveySessionsTableAnnotationComposer,
    $$SurveySessionsTableCreateCompanionBuilder,
    $$SurveySessionsTableUpdateCompanionBuilder,
    (SurveySession, $$SurveySessionsTableReferences),
    SurveySession,
    PrefetchHooks Function({bool projectId})>;
typedef $$StoredFormsTableCreateCompanionBuilder = StoredFormsCompanion
    Function({
  Value<int> id,
  Value<int?> projectId,
  required String name,
  Value<String> description,
  required String json,
  Value<int> version,
  Value<DateTime> createdAt,
});
typedef $$StoredFormsTableUpdateCompanionBuilder = StoredFormsCompanion
    Function({
  Value<int> id,
  Value<int?> projectId,
  Value<String> name,
  Value<String> description,
  Value<String> json,
  Value<int> version,
  Value<DateTime> createdAt,
});

final class $$StoredFormsTableReferences
    extends BaseReferences<_$AppDatabase, $StoredFormsTable, StoredForm> {
  $$StoredFormsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias(
          $_aliasNameGenerator(db.storedForms.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager? get projectId {
    if ($_item.projectId == null) return null;
    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id($_item.projectId!));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$StoredFormsTableFilterComposer
    extends Composer<_$AppDatabase, $StoredFormsTable> {
  $$StoredFormsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StoredFormsTableOrderingComposer
    extends Composer<_$AppDatabase, $StoredFormsTable> {
  $$StoredFormsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StoredFormsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoredFormsTable> {
  $$StoredFormsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StoredFormsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StoredFormsTable,
    StoredForm,
    $$StoredFormsTableFilterComposer,
    $$StoredFormsTableOrderingComposer,
    $$StoredFormsTableAnnotationComposer,
    $$StoredFormsTableCreateCompanionBuilder,
    $$StoredFormsTableUpdateCompanionBuilder,
    (StoredForm, $$StoredFormsTableReferences),
    StoredForm,
    PrefetchHooks Function({bool projectId})> {
  $$StoredFormsTableTableManager(_$AppDatabase db, $StoredFormsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredFormsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredFormsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredFormsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> projectId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              StoredFormsCompanion(
            id: id,
            projectId: projectId,
            name: name,
            description: description,
            json: json,
            version: version,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> projectId = const Value.absent(),
            required String name,
            Value<String> description = const Value.absent(),
            required String json,
            Value<int> version = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              StoredFormsCompanion.insert(
            id: id,
            projectId: projectId,
            name: name,
            description: description,
            json: json,
            version: version,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StoredFormsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable:
                        $$StoredFormsTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$StoredFormsTableReferences._projectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$StoredFormsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StoredFormsTable,
    StoredForm,
    $$StoredFormsTableFilterComposer,
    $$StoredFormsTableOrderingComposer,
    $$StoredFormsTableAnnotationComposer,
    $$StoredFormsTableCreateCompanionBuilder,
    $$StoredFormsTableUpdateCompanionBuilder,
    (StoredForm, $$StoredFormsTableReferences),
    StoredForm,
    PrefetchHooks Function({bool projectId})>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$GpsLogsTableCreateCompanionBuilder = GpsLogsCompanion Function({
  Value<int> id,
  required String name,
  Value<String> surveyor,
  Value<DateTime> createdAt,
});
typedef $$GpsLogsTableUpdateCompanionBuilder = GpsLogsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> surveyor,
  Value<DateTime> createdAt,
});

class $$GpsLogsTableFilterComposer
    extends Composer<_$AppDatabase, $GpsLogsTable> {
  $$GpsLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surveyor => $composableBuilder(
      column: $table.surveyor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$GpsLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $GpsLogsTable> {
  $$GpsLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surveyor => $composableBuilder(
      column: $table.surveyor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$GpsLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GpsLogsTable> {
  $$GpsLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get surveyor =>
      $composableBuilder(column: $table.surveyor, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GpsLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GpsLogsTable,
    GpsLog,
    $$GpsLogsTableFilterComposer,
    $$GpsLogsTableOrderingComposer,
    $$GpsLogsTableAnnotationComposer,
    $$GpsLogsTableCreateCompanionBuilder,
    $$GpsLogsTableUpdateCompanionBuilder,
    (GpsLog, BaseReferences<_$AppDatabase, $GpsLogsTable, GpsLog>),
    GpsLog,
    PrefetchHooks Function()> {
  $$GpsLogsTableTableManager(_$AppDatabase db, $GpsLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GpsLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GpsLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GpsLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> surveyor = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              GpsLogsCompanion(
            id: id,
            name: name,
            surveyor: surveyor,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> surveyor = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              GpsLogsCompanion.insert(
            id: id,
            name: name,
            surveyor: surveyor,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GpsLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GpsLogsTable,
    GpsLog,
    $$GpsLogsTableFilterComposer,
    $$GpsLogsTableOrderingComposer,
    $$GpsLogsTableAnnotationComposer,
    $$GpsLogsTableCreateCompanionBuilder,
    $$GpsLogsTableUpdateCompanionBuilder,
    (GpsLog, BaseReferences<_$AppDatabase, $GpsLogsTable, GpsLog>),
    GpsLog,
    PrefetchHooks Function()>;
typedef $$ProjectFieldsTableCreateCompanionBuilder = ProjectFieldsCompanion
    Function({
  Value<int> id,
  required int projectId,
  required String name,
  Value<DateTime> createdAt,
});
typedef $$ProjectFieldsTableUpdateCompanionBuilder = ProjectFieldsCompanion
    Function({
  Value<int> id,
  Value<int> projectId,
  Value<String> name,
  Value<DateTime> createdAt,
});

final class $$ProjectFieldsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectFieldsTable, ProjectField> {
  $$ProjectFieldsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias(
          $_aliasNameGenerator(db.projectFields.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager get projectId {
    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id($_item.projectId));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ProjectFieldsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectFieldsTable> {
  $$ProjectFieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProjectFieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectFieldsTable> {
  $$ProjectFieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProjectFieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectFieldsTable> {
  $$ProjectFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProjectFieldsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProjectFieldsTable,
    ProjectField,
    $$ProjectFieldsTableFilterComposer,
    $$ProjectFieldsTableOrderingComposer,
    $$ProjectFieldsTableAnnotationComposer,
    $$ProjectFieldsTableCreateCompanionBuilder,
    $$ProjectFieldsTableUpdateCompanionBuilder,
    (ProjectField, $$ProjectFieldsTableReferences),
    ProjectField,
    PrefetchHooks Function({bool projectId})> {
  $$ProjectFieldsTableTableManager(_$AppDatabase db, $ProjectFieldsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectFieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectFieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectFieldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ProjectFieldsCompanion(
            id: id,
            projectId: projectId,
            name: name,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required String name,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ProjectFieldsCompanion.insert(
            id: id,
            projectId: projectId,
            name: name,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ProjectFieldsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable:
                        $$ProjectFieldsTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$ProjectFieldsTableReferences._projectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ProjectFieldsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProjectFieldsTable,
    ProjectField,
    $$ProjectFieldsTableFilterComposer,
    $$ProjectFieldsTableOrderingComposer,
    $$ProjectFieldsTableAnnotationComposer,
    $$ProjectFieldsTableCreateCompanionBuilder,
    $$ProjectFieldsTableUpdateCompanionBuilder,
    (ProjectField, $$ProjectFieldsTableReferences),
    ProjectField,
    PrefetchHooks Function({bool projectId})>;
typedef $$SyncConfigsTableCreateCompanionBuilder = SyncConfigsCompanion
    Function({
  Value<int> projectId,
  Value<String?> syncEndpointUrl,
  Value<String?> syncApiKey,
  Value<DateTime?> lastSyncAt,
});
typedef $$SyncConfigsTableUpdateCompanionBuilder = SyncConfigsCompanion
    Function({
  Value<int> projectId,
  Value<String?> syncEndpointUrl,
  Value<String?> syncApiKey,
  Value<DateTime?> lastSyncAt,
});

final class $$SyncConfigsTableReferences
    extends BaseReferences<_$AppDatabase, $SyncConfigsTable, SyncConfig> {
  $$SyncConfigsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias(
          $_aliasNameGenerator(db.syncConfigs.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager get projectId {
    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id($_item.projectId));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SyncConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncConfigsTable> {
  $$SyncConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncEndpointUrl => $composableBuilder(
      column: $table.syncEndpointUrl,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncApiKey => $composableBuilder(
      column: $table.syncApiKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SyncConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncConfigsTable> {
  $$SyncConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncEndpointUrl => $composableBuilder(
      column: $table.syncEndpointUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncApiKey => $composableBuilder(
      column: $table.syncApiKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SyncConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncConfigsTable> {
  $$SyncConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncEndpointUrl => $composableBuilder(
      column: $table.syncEndpointUrl, builder: (column) => column);

  GeneratedColumn<String> get syncApiKey => $composableBuilder(
      column: $table.syncApiKey, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SyncConfigsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncConfigsTable,
    SyncConfig,
    $$SyncConfigsTableFilterComposer,
    $$SyncConfigsTableOrderingComposer,
    $$SyncConfigsTableAnnotationComposer,
    $$SyncConfigsTableCreateCompanionBuilder,
    $$SyncConfigsTableUpdateCompanionBuilder,
    (SyncConfig, $$SyncConfigsTableReferences),
    SyncConfig,
    PrefetchHooks Function({bool projectId})> {
  $$SyncConfigsTableTableManager(_$AppDatabase db, $SyncConfigsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> projectId = const Value.absent(),
            Value<String?> syncEndpointUrl = const Value.absent(),
            Value<String?> syncApiKey = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
          }) =>
              SyncConfigsCompanion(
            projectId: projectId,
            syncEndpointUrl: syncEndpointUrl,
            syncApiKey: syncApiKey,
            lastSyncAt: lastSyncAt,
          ),
          createCompanionCallback: ({
            Value<int> projectId = const Value.absent(),
            Value<String?> syncEndpointUrl = const Value.absent(),
            Value<String?> syncApiKey = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
          }) =>
              SyncConfigsCompanion.insert(
            projectId: projectId,
            syncEndpointUrl: syncEndpointUrl,
            syncApiKey: syncApiKey,
            lastSyncAt: lastSyncAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SyncConfigsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable:
                        $$SyncConfigsTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$SyncConfigsTableReferences._projectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SyncConfigsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncConfigsTable,
    SyncConfig,
    $$SyncConfigsTableFilterComposer,
    $$SyncConfigsTableOrderingComposer,
    $$SyncConfigsTableAnnotationComposer,
    $$SyncConfigsTableCreateCompanionBuilder,
    $$SyncConfigsTableUpdateCompanionBuilder,
    (SyncConfig, $$SyncConfigsTableReferences),
    SyncConfig,
    PrefetchHooks Function({bool projectId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$SurveySessionsTableTableManager get surveySessions =>
      $$SurveySessionsTableTableManager(_db, _db.surveySessions);
  $$StoredFormsTableTableManager get storedForms =>
      $$StoredFormsTableTableManager(_db, _db.storedForms);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$GpsLogsTableTableManager get gpsLogs =>
      $$GpsLogsTableTableManager(_db, _db.gpsLogs);
  $$ProjectFieldsTableTableManager get projectFields =>
      $$ProjectFieldsTableTableManager(_db, _db.projectFields);
  $$SyncConfigsTableTableManager get syncConfigs =>
      $$SyncConfigsTableTableManager(_db, _db.syncConfigs);
}
