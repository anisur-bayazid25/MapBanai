import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/survey_form.dart';
import 'package:mapbanai/services/project_exporter.dart';
import 'package:mapbanai/services/project_importer.dart';
import 'package:mapbanai/services/project_links.dart';
import 'package:mapbanai/services/project_package.dart';
import 'package:mapbanai/services/project_qr.dart';
import 'package:mapbanai/services/project_sharing_flow.dart';
import 'package:mapbanai/services/project_transfer_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  late AppDatabase db;
  late Directory tempBase;
  late ProjectSharingFlow flow;

  setUp(() async {
    db = AppDatabase.forTesting();
    tempBase = Directory.systemTemp.createTempSync('mbproj-test-');
    PathProviderPlatform.instance = _FakePathProvider(tempBase.path);
    flow = ProjectSharingFlow(database: db, fileSink: _MemorySink());
  });

  tearDown(() async {
    await db.close();
    if (tempBase.existsSync()) {
      tempBase.deleteSync(recursive: true);
    }
  });

  // ── Helpers ─────────────────────────────────────────────────────────

  Future<Project> createRichProject() async {
    await db.createProject(
      'Dhaka Environmental Survey',
      description: 'Baseline environmental quality for the Dhaka region',
      gpsThresholdM: 7.5,
    );
    await db.updateProject(
      (await db.getProjectByName('Dhaka Environmental Survey'))!.id,
      archived: true,
    );
    final project = (await db.getProjectByName('Dhaka Environmental Survey'))!;
    await db.insertProjectField(project.id, 'area_code');
    await db.insertProjectField(project.id, 'sampling_method');

    final rich = SurveyForm(
      id: 'env_form',
      name: 'Environmental Form',
      description: 'Full coverage form',
      version: 3,
      questions: [
        Question(
          name: 'site',
          label: 'Site name',
          type: QuestionType.text,
          required: true,
          hint: 'Nearest landmark',
        ),
        Question(
          name: 'location',
          label: 'GPS point',
          type: QuestionType.geopoint,
        ),
        Question(
          name: 'photo',
          label: 'Photo evidence',
          type: QuestionType.image,
        ),
        Question(
          name: 'severity',
          label: 'Severity',
          type: QuestionType.select_one,
          relevance: "\${site} = 'known' and \${\'severity\'} != ''",
          choices: [
            Choice(name: 'low', label: 'Low'),
            Choice(name: 'high', label: 'High'),
          ],
        ),
        Question(
          name: 'area',
          label: 'Area (m²)',
          type: QuestionType.decimal,
          constraint: '. > 0 and . <= 1000',
          constraintMessage: 'Area must be within range',
          calculation: "\${width} * \${length}",
          readOnly: true,
          defaultValue: '0',
        ),
        Question(name: 'notes', label: 'Notes', type: QuestionType.long_text),
      ],
    );
    await db.insertStoredForm(
      StoredFormsCompanion(
        projectId: drift.Value(project.id),
        name: drift.Value(rich.name),
        description: drift.Value(rich.description),
        json: drift.Value(jsonEncode(rich.toJson())),
        version: drift.Value(rich.version),
      ),
    );
    await db.insertStoredForm(
      StoredFormsCompanion(
        projectId: drift.Value(project.id),
        name: drift.Value('Simple Form'),
        description: drift.Value('Quick'),
        json: drift.Value(jsonEncode(SurveyForm(
          id: 'simple',
          name: 'Simple Form',
          description: 'Quick',
          questions: [
            Question(
              name: 'ok',
              label: 'Is it OK?',
              type: QuestionType.yes_no,
            ),
          ],
        ).toJson())),
        version: drift.Value(1),
      ),
    );
    return project;
  }

  Future<Project> createSimpleProject() async {
    await db.createProject('Simple Project');
    return (await db.getProjectByName('Simple Project'))!;
  }

  Future<Uint8List> exportBytes(Project project) => flow.build(project);

  @pragma('vm:prefer-inline')
  Uint8List zipBytes(Map<String, String> entries) {
    final archive = Archive();
    entries.forEach((name, content) {
      archive.addFile(ArchiveFile.string(name, content));
    });
    return Uint8List.fromList(ZipEncoder().encode(archive) ?? const []);
  }

  /// Rebuilds a package from an existing zip, replacing listed entries while
  /// preserving the raw bytes of every other file. String round-trips in
  /// [zipBytes] re-encode multi-byte UTF-8 and would invalidate checksums.
  Uint8List rebuildZip(
    Archive source,
    Map<String, List<int>> replacements,
  ) {
    final archive = Archive();
    final replacedNames = replacements.keys.toSet();
    for (final entry in source.where((e) => !replacedNames.contains(e.name))) {
      final raw = entry.isFile && entry.content is List<int>
          ? List<int>.from(entry.content as List<int>)
          : const <int>[];
      archive.addFile(
        ArchiveFile(entry.name, raw.length, raw),
      );
    }
    replacements.forEach((name, bytes) {
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    return Uint8List.fromList(ZipEncoder().encode(archive) ?? const []);
  }

  Future<File> writePackage(Uint8List bytes, String name) async {
    final file = File('${tempBase.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<Project> roundTrip(Project source, {ImportDecision? decision}) async {
    final bytes = await exportBytes(source);
    final file = await writePackage(bytes, 'rt.mbproj');
    final session = await flow.startFileImport(file.path);
    final result = await flow.finishImport(session, decision: decision);
    return (await db.getProjectById(result.projectId))!;
  }

  // ── 1+2+3+4+5. Export → structure → manifest → import → round trip ─

  test('export produces a zip package with the expected structure', () async {
    final source = await createRichProject();
    final bytes = await exportBytes(source);

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.sublist(0, 2)), 'PK');

    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.map((e) => e.name).toSet();
    expect(names, containsAll([
      'manifest.json',
      'project.json',
      'settings.json',
      'layers.json',
      'metadata/version.json',
    ]));
    expect(names.where((n) => n.startsWith('form/')), hasLength(2));
  });

  test('manifest carries the required envelope fields', () async {
    final source = await createRichProject();
    final bytes = await exportBytes(source);
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifest = jsonDecode(
      String.fromCharCodes(
        archive.singleWhere((e) => e.name == 'manifest.json').content
                as List<int>,
      ),
    ) as Map<String, dynamic>;
    expect(manifest['package_type'], 'mapbanai_project');
    expect(manifest['package_version'], 1);
    expect(manifest['app_version'], isNotEmpty);
    expect(manifest['project_id'], source.externalId);
    expect(manifest['project_name'], source.name);
    expect(manifest['project_version'], 1);
    expect(manifest['exported_at'], isNotEmpty);
    expect(manifest['contents'], containsAll([
      'project.json',
      'settings.json',
      'layers.json',
      'metadata/version.json',
    ]));
    expect(manifest['checksums'], isA<Map>());
  });

  test('export → import round trip preserves the entire project', () async {
    final source = await createRichProject();
    final imported = await roundTrip(source, decision: ImportDecision.newCopy);

    expect(imported.name, source.name);
    expect(imported.description, source.description);
    expect(imported.archived, source.archived);
    expect(imported.gpsThresholdM, source.gpsThresholdM);
    expect(imported.projectVersion, source.projectVersion);
    expect(imported.externalId, isNot(source.externalId)); // new copy
    expect(imported.isActive, isFalse);

    final fields = await db.getProjectFields(imported.id);
    expect(fields.map((f) => f.name).toList(), ['area_code', 'sampling_method']);

    final forms = await db.getStoredFormsForProject(imported.id);
    expect(forms, hasLength(2));

    final richStored = forms.firstWhere((f) => f.name == 'Environmental Form');
    expect(richStored.version, 3);
    final parsed = SurveyForm.fromJson(jsonDecode(richStored.json));
    expect(parsed.name, 'Environmental Form');
    expect(parsed.questions, hasLength(6));
    expect(parsed.version, 3);

    final severity = parsed.questions.firstWhere((q) => q.name == 'severity');
    expect(severity.type, QuestionType.select_one);
    expect(severity.choices?.map((c) => c.name), ['low', 'high']);
    expect(severity.relevance, isNotEmpty);
    expect(severity.relevance, "\${site} = 'known' and \${\'severity\'} != ''");

    final area = parsed.questions.firstWhere((q) => q.name == 'area');
    expect(area.type, QuestionType.decimal);
    expect(area.constraint, '. > 0 and . <= 1000');
    expect(area.constraintMessage, 'Area must be within range');
    expect(area.calculation, '\${width} * \${length}');
    expect(area.readOnly, isTrue);

    final geo = parsed.questions.firstWhere((q) => q.name == 'location');
    expect(geo.type, QuestionType.geopoint);
    final photo = parsed.questions.firstWhere((q) => q.name == 'photo');
    expect(photo.type, QuestionType.image);
  });

  test('import preserves project version', () async {
    await db.createProject('Versioned');
    final source = (await db.getProjectByName('Versioned'))!;
    await db.updateProject(source.id, );
    final bytes = await exportBytes(source);
    // Force a project version in the payload.
    final archive = ZipDecoder().decodeBytes(bytes);
    final projectJson = jsonDecode(
      String.fromCharCodes(
        archive.singleWhere((e) => e.name == 'project.json').content as List<int>,
      ),
    ) as Map<String, dynamic>;
    projectJson['project_version'] = 13;
    final updatedProjectBytes =
        Uint8List.fromList(utf8.encode(jsonEncode(projectJson)));
    final manifestEntry =
        archive.singleWhere((e) => e.name == 'manifest.json').content as List<int>;
    final manifest = jsonDecode(String.fromCharCodes(manifestEntry))
        as Map<String, dynamic>;
    final checksums =
        (manifest['checksums'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final updatedManifestBytes = Uint8List.fromList(utf8.encode(jsonEncode({
      ...manifest,
      'checksums': {
        ...checksums,
        'project.json': ProjectPackageFormat.sha256Hex(updatedProjectBytes),
      },
    })));
    final rebuilt = rebuildZip(archive, {
      'manifest.json': updatedManifestBytes,
      'project.json': updatedProjectBytes,
    });
    final file = await writePackage(rebuilt, 'v.mbproj');
    final session = await flow.startFileImport(file.path);
    final result = await flow.finishImport(session, decision: ImportDecision.newCopy);
    final imported = (await db.getProjectById(result.projectId))!;
    expect(imported.projectVersion, 13);
  });

  // ── settings / layers preservation ──────────────────────────────────

  test('settings and layers payloads are exported', () async {
    final source = await createSimpleProject();
    final bytes = await exportBytes(source);
    final archive = ZipDecoder().decodeBytes(bytes);
    final settings = jsonDecode(String.fromCharCodes(
      archive.singleWhere((e) => e.name == 'settings.json').content as List<int>,
    )) as Map<String, dynamic>;
    expect(settings['gps_accuracy_threshold_m'], 10.0);

    final layers = jsonDecode(String.fromCharCodes(
      archive.singleWhere((e) => e.name == 'layers.json').content as List<int>,
    )) as Map<String, dynamic>;
    expect(layers['basemap_id'], 'osm');
    expect(layers['basemaps'], isA<List>());
    expect(
      (layers['basemaps'] as List).any((b) => b['id'] == 'osm'),
      isTrue,
    );
  });

  test('responses are never exported', () async {
    final source = await createSimpleProject();
    await db.insertSurveySession(
      SurveySessionsCompanion(
        projectId: drift.Value(source.id),
        title: drift.Value('Response 1'),
        responses: drift.Value('{"one":"two","feature_type":"Point"}'),
      ),
    );
    expect((await db.getSurveySessionsByProject(source.id)), hasLength(1));

    final bytes = await exportBytes(source);
    final asText = utf8.decode(bytes, allowMalformed: true);
    expect(asText.contains('feature_type'), isFalse);
    expect(asText.contains('Response 1'), isFalse);
  });

  test('responses do not survive an import (clean project only)', () async {
    await db.createProject('WithData');
    final source = (await db.getProjectByName('WithData'))!;
    await db.insertSurveySession(
      SurveySessionsCompanion(
        projectId: drift.Value(source.id),
        title: drift.Value('session'),
        responses: drift.Value('{"a":"b"}'),
      ),
    );
    final bytes = await exportBytes(source);
    final file = await writePackage(bytes, 'data.mbproj');

    // Import into a clean database.
    final clean = AppDatabase.forTesting();
    final flow2 = ProjectSharingFlow(database: clean, fileSink: _MemorySink());
    final session = await flow2.startFileImport(file.path);
    await flow2.finishImport(session, decision: ImportDecision.newCopy);
    final imported = (await clean.getProjectByName('WithData'))!;
    expect(await clean.getSurveySessionsByProject(imported.id), isEmpty);
    await clean.close();
  });

  // ── rejection matrix ────────────────────────────────────────────────

  Future<void> expectImportError(
    Uint8List bytes,
    ProjectImportError error,
  ) async {
    final file = await writePackage(bytes, 'bad.mbproj');
    await expectLater(
      flow.startFileImport(file.path),
      throwsA(isA<ProjectImportException>()
          .having((e) => e.error, 'error', error)),
    );
  }

  test('rejects plain text (not a zip)', () async {
    await expectImportError(
      Uint8List.fromList(utf8.encode('hello world')),
      ProjectImportError.notAZipFile,
    );
  });

  test('rejects a missing/invalid manifest', () async {
    final zip = zipBytes({
      'project.json': '{}',
      'settings.json': '{}',
      'layers.json': '{}',
      'metadata/version.json': '{}',
    });
    await expectImportError(zip, ProjectImportError.invalidManifest);
  });

  test('rejects a wrong package type', () async {
    final zip = zipBytes({
      'manifest.json': jsonEncode({
        'package_type': 'something_else',
        'package_version': 1,
      }),
      'project.json': '{}',
      'settings.json': '{}',
      'layers.json': '{}',
      'metadata/version.json': '{}',
    });
    await expectImportError(zip, ProjectImportError.wrongPackageType);
  });

  test('rejects an unsupported package version', () async {
    final zip = zipBytes({
      'manifest.json': jsonEncode({
        'package_type': 'mapbanai_project',
        'package_version': 99,
        'project_id': 'x',
        'project_name': 'x',
      }),
      'project.json': '{}',
      'settings.json': '{}',
      'layers.json': '{}',
      'metadata/version.json': '{}',
    });
    await expectImportError(zip, ProjectImportError.unsupportedPackageVersion);
  });

  test('rejects a corrupted package', () async {
    final source = await createSimpleProject();
    final bytes = await exportBytes(source);
    // Chop the end-of-central-directory record so the decoder rejects the
    // archive outright (entries are stored uncompressed, so flipping a
    // payload byte would surface as a checksum mismatch instead).
    final corrupted =
        Uint8List.fromList(bytes.sublist(0, bytes.length - 4));
    await expectImportError(
      corrupted,
      ProjectImportError.corruptedZip,
    );
  });

  test('rejects a checksum mismatch', () async {
    final source = await createSimpleProject();
    final bytes = await exportBytes(source);
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifest = jsonDecode(String.fromCharCodes(
      archive.singleWhere((e) => e.name == 'manifest.json').content as List<int>,
    )) as Map<String, dynamic>;
    (manifest['checksums'] as Map)['project.json'] = 'deadbeef';
    final rebuilt = zipBytes({
      for (final e in archive)
        e.name: String.fromCharCodes(e.content as List<int>),
      'manifest.json': jsonEncode(manifest),
    });
    await expectImportError(rebuilt, ProjectImportError.checksumMismatch);
  });

  test('rejects an incomplete package (missing required file)', () async {
    final source = await createSimpleProject();
    final bytes = await exportBytes(source);
    final archive = ZipDecoder().decodeBytes(bytes);
    final stripped = zipBytes({
      for (final e in archive.where((e) => e.name != 'layers.json'))
        e.name: String.fromCharCodes(e.content as List<int>),
    });
    await expectImportError(stripped, ProjectImportError.missingRequiredFiles);
  });

  test('rejects path traversal entries (../evil)', () async {
    final zip = zipBytes({
      'manifest.json': jsonEncode({
        'package_type': 'mapbanai_project',
        'package_version': 1,
      }),
      '../evil.txt': 'pwn',
    });
    await expectImportError(zip, ProjectImportError.pathTraversalRisk);
  });

  test('rejects absolute paths and backslash traversal', () async {
    final zip = zipBytes({
      'manifest.json': jsonEncode({
        'package_type': 'mapbanai_project',
        'package_version': 1,
      }),
      r'..\evil.txt': 'pwn',
    });
    await expectImportError(zip, ProjectImportError.pathTraversalRisk);
  });

  test('rejects invalid project JSON', () async {
    final source = await createSimpleProject();
    final bytes = await exportBytes(source);
    final archive = ZipDecoder().decodeBytes(bytes);
    final invalidProject = Uint8List.fromList(utf8.encode('not json {{{'));
    final manifestEntry =
        archive.singleWhere((e) => e.name == 'manifest.json').content as List<int>;
    final manifest = jsonDecode(String.fromCharCodes(manifestEntry))
        as Map<String, dynamic>;
    final checksums =
        (manifest['checksums'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final rebuilt = rebuildZip(archive, {
      'manifest.json': Uint8List.fromList(utf8.encode(jsonEncode({
        ...manifest,
        'checksums': {
          ...checksums,
          'project.json': ProjectPackageFormat.sha256Hex(invalidProject),
        },
      }))),
      'project.json': invalidProject,
    });
    await expectImportError(rebuilt, ProjectImportError.invalidProjectJson);
  });

  test('manifest validation allows the round trip (valid manifest)', () async {
    // Build the package from a separate database so the receiving database
    // is truly empty and the import has no conflict to detect.
    final exportDb = AppDatabase.forTesting();
    try {
      await exportDb.createProject('Simple Project');
      final source = (await exportDb.getProjectByName('Simple Project'))!;
      final externalFlow =
          ProjectSharingFlow(database: exportDb, fileSink: _MemorySink());
      final bytes = await externalFlow.build(source);
      final file = await writePackage(bytes, 'ok.mbproj');
      final session = await flow.startFileImport(file.path);
      expect(session.conflict, isNull);
      await flow.finishImport(session, decision: ImportDecision.newCopy);
      expect(await db.getProjectByName('Simple Project'), isNotNull);
    } finally {
      await exportDb.close();
    }
  });

  // ── existing project handling ───────────────────────────────────────

  test('conflict detection finds an existing project by external id', () async {
    final source = await createSimpleProject();
    final file = await writePackage(await exportBytes(source), 'dup.mbproj');
    // The package carries the same external identity as the local project,
    // so the conflict check resolves it before any commit happens.
    final session = await flow.startFileImport(file.path);
    expect(session.conflict, isNotNull);
    expect(session.conflict!.externalId, source.externalId);
  });

  test('never overwrites without an explicit decision', () async {
    final source = await createSimpleProject();
    final file = await writePackage(await exportBytes(source), 'x.mbproj');
    final session = await flow.startFileImport(file.path);
    await flow.finishImport(session, decision: ImportDecision.newCopy);
    expect((await db.getProjects()), hasLength(2));

    final session2 = await flow.startFileImport(file.path);
    expect(session2.conflict, isNotNull);
    // No decision → the import is rejected and nothing is changed.
    await expectLater(
      flow.finishImport(session2, decision: null),
      throwsA(isA<ProjectImportException>()),
    );
    expect((await db.getProjects()), hasLength(2));
  });

test('import as new copy creates a second project with new identity',
    () async {
    final source = await createSimpleProject();
    final package = await writePackage(await exportBytes(source), 'a.mbproj');
    final session = await flow.startFileImport(package.path);
    await flow.finishImport(session, decision: ImportDecision.newCopy);

    final all = await db.getProjects();
    expect(all, hasLength(2));
    expect(all.map((p) => p.externalId).toSet(), hasLength(2));

    final copy = all.firstWhere((p) => p.id != source.id);
    expect(copy.name, source.name);
    expect(copy.externalId, isNot(source.externalId));
    expect(copy.isActive, isFalse);
  });

  test('replace deletes the existing project and its data', () async {
    final source = await createSimpleProject();
    await db.insertSurveySession(
      SurveySessionsCompanion(
        projectId: drift.Value(source.id),
        title: drift.Value('old data'),
        responses: drift.Value('{}'),
      ),
    );

    final package = await writePackage(await exportBytes(source), 'r.mbproj');
    final session = await flow.startFileImport(package.path);
    final existingId = session.conflict!.id;
    await flow.finishImport(session, decision: ImportDecision.replaceExisting);

    final all = await db.getProjects();
    expect(all, hasLength(1));
    expect(all.single.id, isNot(existingId));
    expect(await db.getSurveySessionsByProject(all.single.id), isEmpty);
  });

  test('temp extraction directory is cleaned up after import', () async {
    final source = await createSimpleProject();
    final f = await writePackage(await exportBytes(source), 'clean.mbproj');
    final session = await flow.startFileImport(f.path);
    final root = session.package!.tempRoot;
    expect(await root.exists(), isTrue);
    await flow.finishImport(session, decision: ImportDecision.newCopy);
    expect(await root.exists(), isFalse);
  });

  test('import failure leaves existing data untouched', () async {
    final source = await createSimpleProject();
    final f1 = await writePackage(await exportBytes(source), 'keep.mbproj');
    final s1 = await flow.startFileImport(f1.path);
    await flow.finishImport(s1, decision: ImportDecision.newCopy);

    // Corrupt import attempt.
    final bad = Uint8List.fromList(utf8.encode('not a zip'));
    await expectImportError(bad, ProjectImportError.notAZipFile);
    expect((await db.getProjects()), hasLength(2));
    expect(await db.getProjectByName(source.name), isNotNull);
  });

  // ── filename handling ───────────────────────────────────────────────

  test('safe filename for the canonical example', () {
    expect(
      safeProjectFileName('Dhaka Environmental Survey', 3),
      'Dhaka_Environmental_Survey_v3.mbproj',
    );
  });

  test('safe filename strips traversal and illegal characters', () {
    expect(
      safeProjectFileName('../../usr / na:me*', 1),
      endsWith('_v1.mbproj'),
    );
    expect(safeProjectFileName('../evil', 1).contains('..'), isFalse);
    expect(safeProjectFileName('../evil', 1).contains('/'), isFalse);
    expect(safeProjectFileName('', 1), 'Project_v1.mbproj');
  });

  // ── large project handling (fits memory, streams through the pipeline) ─

  test('a large form definition round-trips intact', () async {
    await db.createProject('Big');
    final project = (await db.getProjectByName('Big'))!;
    // ~1 MB of question text — a proxy for a genuinely large form.
    final bloat = 'x' * (600 * 1024);
    await db.insertStoredForm(
      StoredFormsCompanion(
        projectId: drift.Value(project.id),
        name: drift.Value('Bloat'),
        description: drift.Value(''),
        json: drift.Value(jsonEncode(SurveyForm(
          id: 'bloat',
          name: 'Bloat',
          description: '',
          questions: [
            Question(name: 'big', label: bloat, type: QuestionType.text),
          ],
        ).toJson())),
        version: drift.Value(1),
      ),
    );
    final imported = await roundTrip(project, decision: ImportDecision.newCopy);
    final forms = await db.getStoredFormsForProject(imported.id);
    final parsed = SurveyForm.fromJson(jsonDecode(forms.single.json));
    expect(parsed.questions.single.label, bloat);
  });

  // ── QR codes ────────────────────────────────────────────────────────

  test('inline QR round trips and commits into the database', () async {
    final source = await createSimpleProject();
    final data = await ProjectExporter(db).buildData(source);
    final payload = ProjectQr.encodeInline(data);

    final parsed = ProjectQr.parse(payload);
    expect(parsed, isNotNull);
    expect(parsed!['mode'], 'inline');
    final build = ProjectQr.inlineToData(parsed);
    expect(build.meta.projectName, source.name);

    final clean = AppDatabase.forTesting();
    final flow2 = ProjectSharingFlow(database: clean, fileSink: _MemorySink());
    final session = await flow2.startQrImport(payload);
    await flow2.finishImport(session, decision: ImportDecision.newCopy);
    expect(await clean.getProjectByName(source.name), isNotNull);
    await clean.close();
  });

  test('bootstrap QR import surfaces a session-level instruction, not a '
      'crash toward finishImport', () async {
    final clean = AppDatabase.forTesting();
    final flow2 = ProjectSharingFlow(database: clean, fileSink: _MemorySink());
    final payload = ProjectQr.encodeBootstrap(
      projectId: 'id-1',
      projectName: 'Bootstrap Proj',
      projectVersion: 4,
      checksum: 'abc123',
    );
    final session = await flow2.startQrImport(payload);
    // The import dialog branches on bootstrapMeta BEFORE finishImport, so
    // the old "Nothing to import" path (which double-popped the navigator
    // and black-screened the app) is unreachable for bootstrap codes.
    expect(session.bootstrapMeta, isNotNull);
    expect(session.isQr, isFalse);
    await clean.close();
  });

  test('bootstrap QR carries identity + checksum and decodes', () {
    final payload = ProjectQr.encodeBootstrap(
      projectId: 'id-1',
      projectName: 'Bootstrap Proj',
      projectVersion: 4,
      checksum: 'abc123',
    );
    final decoded = ProjectQr.parse(payload)!;
    expect(decoded['mode'], 'bootstrap');
    expect(decoded['project_id'], 'id-1');
    expect(decoded['project_name'], 'Bootstrap Proj');
    expect(decoded['checksum'], 'abc123');
    expect(decoded['transfer'], 'mbproj');
  });

  test('QR decode is versioned and rejects unknown versions', () {
    final good = ProjectQr.encodeBootstrap(
      projectId: 'a',
      projectName: 'A',
      projectVersion: 1,
    );
    final decoded = jsonDecode(utf8.decode(zlib.decode(
      base64Url.decode(good.substring('MAPBANAI-PROJECT-V1:'.length)),
    ))) as Map<String, dynamic>;
    decoded['v'] = 99;
    final evil = 'MAPBANAI-PROJECT-V1:${base64Url.encode(zlib.encode(utf8.encode(jsonEncode(decoded))))}';
    expect(ProjectQr.parse(evil), isNull);
  });

  test('QR parse rejects garbage, missing identity, and unencodable data',
      () {
    expect(ProjectQr.parse('not a code'), isNull);
    expect(ProjectQr.parse(''), isNull);
    expect(
      ProjectQr.parse('MAPBANAI-PROJECT-V1:!!notbase64!!'),
      isNull,
    );
  });

  test('oversized project reports "too large for direct QR"', () async {
    final payload = ProjectQr.encodeBootstrap(
      projectId: 'x',
      projectName: 'X',
      projectVersion: 1,
    );
    expect(payload.length, lessThan(ProjectQr.maxInlinePayloadChars));
  });

  test('project-too-large guard rejects inline encoding beyond budget', () async {
    await db.createProject('TooBig');
    final project = (await db.getProjectByName('TooBig'))!;
    // Random (incompressible) text so the payload cannot shrink under zlib.
    final random = Random(42);
    final label = String.fromCharCodes(
      List<int>.generate(16 * 1024, (_) => 32 + random.nextInt(95)),
    );
    await db.insertStoredForm(
      StoredFormsCompanion(
        projectId: drift.Value(project.id),
        name: drift.Value('Big'),
        description: drift.Value(''),
        json: drift.Value(jsonEncode(SurveyForm(
          id: 'big',
          name: 'Big',
          description: '',
          questions: [
            Question(
              name: 'q',
              label: label,
              type: QuestionType.text,
            ),
          ],
        ).toJson())),
        version: drift.Value(1),
      ),
    );
    final data = await ProjectExporter(db).buildData(project);
    expect(
      () => ProjectQr.encodeInline(data),
      throwsA(isA<ProjectTooLargeForQrException>()),
    );
  });

  // ── links ───────────────────────────────────────────────────────────

  test('mapbanai://project/import?file=... is parsed', () {
    final info = ProjectLinks.parse(
      'mapbanai://project/import?file=content://media/external/downloads/1',
    );
    expect(info, isNotNull);
    expect(info!.fileUri, 'content://media/external/downloads/1');
  });

  test('mapbanai://project/import?qr=... is parsed', () {
    final payload = ProjectQr.encodeBootstrap(
      projectId: 'p1',
      projectName: 'P1',
      projectVersion: 1,
    );
    final info = ProjectLinks.parse(
      'mapbanai://project/import?qr=${Uri.encodeComponent(payload)}',
    );
    expect(info, isNotNull);
    expect(info!.qrPayload, payload);
    expect(info.hasImportWork, isTrue);
  });

  test('https .mbproj URLs are recognized (future download)', () {
    final info = ProjectLinks.parse(
      'https://example.com/surveys/Dhaka_Environmental_Survey_v1.3.mbproj',
    );
    expect(info, isNotNull);
    expect(info!.fileUri, isNotNull);
  });

  test('random strings and other links are ignored', () {
    expect(ProjectLinks.parse('hello'), isNull);
    expect(ProjectLinks.parse('https://example.com/index.html'), isNull);
    expect(ProjectLinks.parse(''), isNull);
  });

  // ── friendly error messages stay non-technical ──────────────────────

  test('friendly import messages hide technical jargon', () {
    expect(
      friendlyMessageFor(const ProjectImportException(
        ProjectImportError.invalidProjectJson,
        'x',
      )),
      isNot(contains('JSON')),
    );
    expect(
      friendlyMessageFor(const ProjectImportException(
        ProjectImportError.checksumMismatch,
        'x',
      )),
      contains('safety check'),
    );
  });

  // ── SAVE / SHARE (injected sinks + providers) ───────────────────────

  test('exportProject saves through the file sink and reports success',
      () async {
    final source = await createSimpleProject();
    final sink = _MemorySink();
    final localFlow = ProjectSharingFlow(database: db, fileSink: sink);
    final status = await localFlow.exportProject(source);
    expect(status, ProjectExportStatus.saved);
    expect(sink.savedBytes, isNotNull);
    expect(sink.savedName, 'Simple_Project_v1.mbproj');
    expect(sink.savedPath, isNotNull);
  });

  test('shareProject hands a real .mbproj file to the provider', () async {
    final source = await createSimpleProject();
    final capturing = _CapturingProvider();
    final localFlow = ProjectSharingFlow(
      database: db,
      transferProviders: [capturing],
    );
    final shared = await localFlow.shareProject(source);
    expect(shared, isTrue);
    final file = File(capturing.lastPath!);
    expect(await file.exists(), isTrue);
    final bytes = await file.readAsBytes();
    expect(String.fromCharCodes(bytes.sublist(0, 2)), 'PK');
  });

  test('suggested file name matches the docs', () async {
    final source = await createSimpleProject();
    expect(
      flow.suggestedFileName(source),
      'Simple_Project_v1.mbproj',
    );
  });
}

/// Minimal import of the friendly-message function used by tests.
String friendlyMessageFor(Object error) {
  if (error is ProjectImportException) {
    switch (error.error) {
      case ProjectImportError.invalidProjectJson:
        return 'The project file is not a valid MapBanai project.';
      case ProjectImportError.checksumMismatch:
        return 'The project file failed its safety check and was not imported.';
      default:
        return 'The project could not be imported.';
    }
  }
  return 'The project could not be imported.';
}

class _MemorySink implements ProjectFileSink {
  String? savedPath;
  String? savedName;
  Uint8List? savedBytes;

  @override
  Future<String?> pickPackageFile() async => null;

  @override
  Future<String?> savePackageBytes({
    required String fileName,
    required Uint8List bytes,
  }) async {
    savedName = fileName;
    savedBytes = bytes;
    savedPath = 'C:\\fake\\$fileName';
    return savedPath;
  }
}

class _CapturingProvider implements ProjectTransferProvider {
  String? lastPath;

  @override
  String get id => 'capture';

  @override
  String get displayName => 'Capture';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> shareProjectFile(File file, {String? title}) async {
    lastPath = file.path;
    return true;
  }
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;
}