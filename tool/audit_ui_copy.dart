import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class CopyVisitor extends RecursiveAstVisitor<void> {
  final String path;
  final String source;
  final List<Map<String, dynamic>> records;
  CopyVisitor(this.path, this.source, this.records);
  void capture(StringLiteral n) {
    if (n.thisOrAncestorMatching((e) => e is StringLiteral && e != n) != null)
      return;
    AstNode branch = n;
    while (branch.parent != null && branch.parent is! ArgumentList)
      branch = branch.parent!;
    final args = branch.parent;
    if (args is! ArgumentList) return;
    // A Text expression can contain data lookups and comparisons. Their keys
    // are program data, not interface copy (e.g. metadata['form_validated']).
    AstNode? owner = n.parent;
    while (owner != null && owner != args) {
      if (owner is IndexExpression ||
          owner is MapLiteralEntry ||
          owner is BinaryExpression && owner.operator.lexeme != '??') return;
      owner = owner.parent;
    }
    final call = args.parent;
    String name = '';
    if (call is InstanceCreationExpression)
      name = call.constructorName.type.name2.lexeme;
    if (call is MethodInvocation) name = call.methodName.name;
    final named = branch is NamedExpression ? branch.name.label.name : '';
    final visible = name == 'Text' && args.arguments.first == branch ||
        const [
          'labelText',
          'hintText',
          'helperText',
          'errorText',
          'tooltip',
          'message',
          'semanticLabel',
          'title',
          'subtitle',
          'label',
          'text'
        ].contains(named) ||
        const ['_message', '_showSnack', '_snack', '_notify'].contains(name) &&
            args.arguments.first == branch;
    if (!visible ||
        branch.toSource().contains('l10n') ||
        branch.toSource().contains('AppLocalizations')) return;
    final params = <String>[];
    String? template(StringLiteral value) {
      if (value is SimpleStringLiteral) return value.value;
      if (value is AdjacentStrings) return value.strings.map(template).join();
      if (value is StringInterpolation)
        return value.elements.map((e) {
          if (e is InterpolationString) return e.value;
          final item = e as InterpolationExpression;
          final i = params.length;
          params.add(item.expression.toSource());
          return '{v$i}';
        }).join();
      return null;
    }

    final key = template(n);
    if (key == null ||
        !RegExp(r'[A-Za-z]{2}').hasMatch(key) ||
        key.trim().startsWith('http') ||
        key.contains('<html')) return;
    final consts = <int>[];
    AstNode? parent = n.parent;
    while (parent != null && parent is! FunctionBody) {
      if (parent is InstanceCreationExpression &&
          parent.keyword?.lexeme == 'const') consts.add(parent.keyword!.offset);
      if (parent is TypedLiteral && parent.constKeyword != null)
        consts.add(parent.constKeyword!.offset);
      parent = parent.parent;
    }
    records.add({
      'path': path.replaceAll('\\', '/'),
      'start': n.offset,
      'end': n.end,
      'source': source.substring(n.offset, n.end),
      'key': key,
      'params': params,
      'consts': consts
    });
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral n) {
    capture(n);
  }

  @override
  void visitStringInterpolation(StringInterpolation n) {
    capture(n);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings n) {
    capture(n);
  }
}

void main(List<String> arguments) {
  final records = <Map<String, dynamic>>[];
  for (final f in Directory('lib/ui')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))) {
    final source = f.readAsStringSync();
    final unit = parseString(content: source, path: f.path).unit;
    unit.accept(CopyVisitor(f.path, source, records));
  }
  File(arguments.isEmpty
          ? '${Directory.systemTemp.path}${Platform.pathSeparator}mapbanai-ui-copy-audit.json'
          : arguments.first)
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(records));
  print(
      '${records.length} UI text expressions, ${records.map((r) => r['key']).toSet().length} distinct messages');
}
