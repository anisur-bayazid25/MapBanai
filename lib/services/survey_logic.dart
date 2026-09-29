/// XLSForm-style expression engine for survey logic.
///
/// Supports three expression types used by forms:
/// - **Relevance** (visibility): `${field} = 'value'`, comparisons, `and`,
///   `or`, `not`, parentheses, and `selected(${multi_field}, 'value')`.
/// - **Calculation** (computed answers): arithmetic over `${field}` refs,
///   e.g. `${width} * ${length}`, plus ODK functions: `now()`, `today()`,
///   `date()`, `time()`, `format-date()`, `format-date-time()`, `concat()`,
///   `join()`, `if()`, `coalesce()`, string helpers (`substr`,
///   `string-length`, `upper`, `lower`, `contains`, `starts-with`,
///   `ends-with`), `selected-at()`, `count-selected()`, and math helpers
///   (`round`, `floor`, `ceil`, `abs`, `min`, `max`, `pow`, `sqrt`,
///   `number`, `string`, `boolean`).
/// - **Constraint** (validation): same syntax as relevance, evaluated with
///   `.` standing for the question's own answer, e.g. `. > 0 and . <= 100`.
class SurveyLogic {
  /// Evaluates a relevance expression. Returns `true` when there is no
  /// expression or when it cannot be parsed (fail-open for visibility).
  static bool evaluateRelevance(String? expression, Map<String, dynamic> answers) {
    if (expression == null || expression.trim().isEmpty) return true;
    try {
      final tokens = _Lexer(expression).tokenize();
      final value = _Parser(tokens, answers).parse();
      return _isTruthy(value);
    } catch (_) {
      // Fail open: unparsable expressions leave the question visible.
      return true;
    }
  }

  /// Evaluates a calculation expression. Returns `null` when the expression
  /// is missing or cannot be computed (referenced answers missing/non-numeric).
  static String? evaluateCalculation(
    String? expression,
    Map<String, dynamic> answers,
  ) {
    if (expression == null || expression.trim().isEmpty) return null;
    try {
      final tokens = _Lexer(expression).tokenize();
      final value = _Parser(tokens, answers).parse();
      if (value is num) return _formatNumber(value);
      if (value is DateTime) return value.toIso8601String();
      if (value is String || value is bool) return value.toString();
      if (value is List) {
        return value.map((e) => e?.toString() ?? '').join(' ');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Evaluates a constraint against the question's own answer.
  /// Returns `null` when the constraint passes, otherwise an error message.
  static String? evaluateConstraint(
    String? constraint,
    dynamic answer,
    String? message,
  ) {
    if (constraint == null || constraint.trim().isEmpty) return null;
    if (answer == null || answer.toString().trim().isEmpty) return null;

    final answers = <String, dynamic>{'.': answer};
    try {
      final tokens = _Lexer(constraint).tokenize();
      final value = _Parser(tokens, answers).parse();
      if (_isTruthy(value)) return null;
    } catch (_) {
      // Parse failure means the constraint cannot be satisfied as written.
    }
    return message ?? 'Constraint not satisfied';
  }

  static String _formatNumber(num value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '');
  }

  /// Strips HTML markup from XLSForm labels/hints. Real-world ODK forms
  /// embed tags like `<span style=...>`, `<b>`, `<i>` in labels; the app has
  /// no HTML renderer, so tags are removed (`<br>`/`</p>` become newlines)
  /// and entities (`&amp;`, `&nbsp;`, …) are decoded.
  static String stripHtml(String input) {
    var s = input.replaceAll(
        RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<[^>]*>'), '');
    const entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&nbsp;': ' ',
    };
    entities.forEach((k, v) => s = s.replaceAll(k, v));
    s = s.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) {
        final code = int.tryParse(m.group(1)!);
        return code == null ? m.group(0)! : String.fromCharCode(code);
      },
    );
    return s.trim();
  }

  static final RegExp _refPattern =
      RegExp(r'\$\{\s*([A-Za-z_][A-Za-z0-9_.\-]*)\s*\}');

  /// Replaces `${name}` placeholders in [template] with the current answer
  /// values (ODK dynamic labels). Missing answers become empty strings,
  /// multi-select lists are comma-joined, datetimes use ISO format.
  static String interpolate(String template, Map<String, dynamic> answers) {
    return template.replaceAllMapped(_refPattern, (m) {
      final value = answers[m.group(1)!];
      if (value == null) return '';
      if (value is List) {
        return value.map((e) => e?.toString() ?? '').join(', ');
      }
      if (value is DateTime) return value.toIso8601String();
      return value.toString();
    });
  }

  /// Parses the ODK label HTML subset into styled runs for RichText
  /// rendering: `<span style="color:…; font-weight:bold">`, `<b>`,
  /// `<strong>`, `<i>`, `<em>`, `<u>`, `<font color="…">`, `<br/>` and
  /// entities. Unknown/malformed tags are skipped with their text kept, so
  /// messy real-world labels (e.g. `</f3_0 span>`) degrade gracefully.
  static List<RichRun> parseStyledText(String input) {
    final runs = <RichRun>[];
    final stack = <_TextStyleSpec>[_TextStyleSpec()];
    final buffer = StringBuffer();

    void flush() {
      if (buffer.isEmpty) return;
      final current = stack.last;
      runs.add(RichRun(
        _decodeEntities(buffer.toString()),
        bold: current.bold,
        italic: current.italic,
        underline: current.underline,
        color: current.color,
      ));
      buffer.clear();
    }

    // Attribute values in ODK labels never contain angle brackets, so a
    // simple negated-class pattern is enough (and avoids quote nesting).
    final tagPattern = RegExp('<(/?)([A-Za-z][A-Za-z0-9]*)([^<>]*)>');
    var pos = 0;
    for (final match in tagPattern.allMatches(input)) {
      if (match.start > pos) {
        buffer.write(input.substring(pos, match.start));
      }
      pos = match.end;
      final closing = match.group(1) == '/';
      final tag = match.group(2)!.toLowerCase();
      final attrs = match.group(3) ?? '';
      final selfClosing = attrs.trimRight().endsWith('/');

      if (tag == 'br') {
        flush();
        final current = stack.last;
        runs.add(RichRun(
          '\n',
          bold: current.bold,
          italic: current.italic,
          underline: current.underline,
          color: current.color,
        ));
        continue;
      }
      if (closing || selfClosing) {
        // Only pop for known style tags; stray closers are ignored.
        if (_isStyleTag(tag) && stack.length > 1) {
          flush();
          stack.removeLast();
        }
        continue;
      }
      switch (tag) {
        case 'b':
        case 'strong':
          flush();
          stack.add(stack.last.copyWith(bold: true));
        case 'i':
        case 'em':
          flush();
          stack.add(stack.last.copyWith(italic: true));
        case 'u':
          flush();
          stack.add(stack.last.copyWith(underline: true));
        case 'span':
        case 'font':
          flush();
          stack.add(_styleFromAttrs(tag, attrs, stack.last));
        default:
          // Unknown tag: drop the tag itself, keep the text.
          break;
      }
    }
    if (pos < input.length) {
      buffer.write(input.substring(pos));
    }
    flush();
    return runs;
  }

  static bool _isStyleTag(String tag) {
    return tag == 'b' ||
        tag == 'strong' ||
        tag == 'i' ||
        tag == 'em' ||
        tag == 'u' ||
        tag == 'span' ||
        tag == 'font';
  }

  static _TextStyleSpec _styleFromAttrs(
      String tag, String attrs, _TextStyleSpec base) {
    var spec = base;
    // <font color="red">
    final fontColor =
        RegExp('color\\s*=\\s*["\']?([^"\'\\s>]+)').firstMatch(attrs);
    if (tag == 'font' && fontColor != null) {
      final parsed = _parseCssColor(fontColor.group(1)!);
      if (parsed != null) spec = spec.copyWith(color: parsed);
    }
    // <span style="color:red; font-weight:bold; ...">
    final styleAttr =
        RegExp('style\\s*=\\s*"([^"]*)"').firstMatch(attrs) ??
            RegExp("style\\s*=\\s*'([^']*)'").firstMatch(attrs);
    if (styleAttr != null) {
      for (final decl in styleAttr.group(1)!.split(';')) {
        final parts = decl.split(':');
        if (parts.length < 2) continue;
        final prop = parts[0].trim().toLowerCase();
        final value = parts.sublist(1).join(':').trim().toLowerCase();
        switch (prop) {
          case 'color':
            final parsed = _parseCssColor(value);
            if (parsed != null) spec = spec.copyWith(color: parsed);
          case 'font-weight':
            if (value == 'bold' ||
                value == 'bolder' ||
                (int.tryParse(value) ?? 0) >= 700) {
              spec = spec.copyWith(bold: true);
            }
          case 'font-style':
            if (value == 'italic' || value == 'oblique') {
              spec = spec.copyWith(italic: true);
            }
          case 'text-decoration':
            if (value.contains('underline')) {
              spec = spec.copyWith(underline: true);
            }
        }
      }
    }
    return spec;
  }

  static const Map<String, int> _namedColors = {
    'red': 0xFFFF0000,
    'maroon': 0xFF800000,
    'green': 0xFF008000,
    'blue': 0xFF0000FF,
    'black': 0xFF000000,
    'white': 0xFFFFFFFF,
    'gray': 0xFF808080,
    'grey': 0xFF808080,
    'darkgray': 0xFFA9A9A9,
    'darkgrey': 0xFFA9A9A9,
    'lightgray': 0xFFD3D3D3,
    'lightgrey': 0xFFD3D3D3,
    'yellow': 0xFFFFFF00,
    'orange': 0xFFFFA500,
    'purple': 0xFF800080,
    'teal': 0xFF008080,
    'navy': 0xFF000080,
    'lime': 0xFF00FF00,
    'aqua': 0xFF00FFFF,
    'cyan': 0xFF00FFFF,
    'fuchsia': 0xFFFF00FF,
    'magenta': 0xFFFF00FF,
    'silver': 0xFFC0C0C0,
    'olive': 0xFF808000,
    'darkred': 0xFF8B0000,
    'darkgreen': 0xFF006400,
    'darkblue': 0xFF00008B,
    'pink': 0xFFFFC0CB,
    'brown': 0xFFA52A2A,
  };

  /// Parses CSS colors: named colors plus `#rgb` / `#rrggbb`. Returns an
  /// ARGB int or null when unparsable.
  static int? _parseCssColor(String value) {
    final v = value.trim().toLowerCase();
    final named = _namedColors[v];
    if (named != null) return named;
    final hex = RegExp(r'^#([0-9a-f]{3}|[0-9a-f]{6})$').firstMatch(v);
    if (hex == null) return null;
    var digits = hex.group(1)!;
    if (digits.length == 3) {
      digits = digits.split('').map((c) => '$c$c').join();
    }
    return 0xFF000000 | int.parse(digits, radix: 16);
  }

  static String _decodeEntities(String s) {
    const entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&nbsp;': ' ',
    };
    var out = s;
    entities.forEach((k, v) => out = out.replaceAll(k, v));
    out = out.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) {
        final code = int.tryParse(m.group(1)!);
        return code == null ? m.group(0)! : String.fromCharCode(code);
      },
    );
    return out;
  }

  static bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    return true;
  }
}

/// One styled run of label text produced by [SurveyLogic.parseStyledText].
class RichRun {
  final String text;
  final bool bold;
  final bool italic;
  final bool underline;

  /// ARGB color int (e.g. `0xFFFF0000`), or null to inherit.
  final int? color;

  const RichRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.color,
  });

  bool get hasStyle =>
      bold || italic || underline || color != null;
}

/// Mutable style accumulator used while parsing styled label text.
class _TextStyleSpec {
  final bool bold;
  final bool italic;
  final bool underline;
  final int? color;

  const _TextStyleSpec({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.color,
  });

  _TextStyleSpec copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    int? color,
  }) {
    return _TextStyleSpec(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      color: color ?? this.color,
    );
  }
}

/// Token types used by the expression parser.
enum _TokenType {
  number,
  string,
  field,
  ident,
  and,
  or,
  not,
  operator,
  lparen,
  rparen,
  comma,
  eof,
}

class _Token {
  final _TokenType type;
  final String lexeme;

  const _Token(this.type, this.lexeme);

  @override
  String toString() => '${type.name}($lexeme)';
}

class _Lexer {
  final String _input;
  int _pos = 0;

  _Lexer(this._input);

  List<_Token> tokenize() {
    final tokens = <_Token>[];
    _Token? token;
    do {
      token = _next();
      tokens.add(token);
    } while (token.type != _TokenType.eof);
    return tokens;
  }

  _Token _next() {
    while (_pos < _input.length && _input[_pos].trim().isEmpty) {
      _pos++;
    }
    if (_pos >= _input.length) return const _Token(_TokenType.eof, '');

    final ch = _input[_pos];

    if (ch == '(') {
      _pos++;
      return const _Token(_TokenType.lparen, '(');
    }
    if (ch == ')') {
      _pos++;
      return const _Token(_TokenType.rparen, ')');
    }
    if (ch == ',') {
      _pos++;
      return const _Token(_TokenType.comma, ',');
    }

    if (ch == '\'' || ch == '"') {
      return _lexString(ch);
    }

    if (ch == '\$') {
      return _lexField();
    }

    if (_isDigit(ch) ||
        (ch == '.' && _pos + 1 < _input.length && _isDigit(_input[_pos + 1]))) {
      return _lexNumber();
    }

    if (ch == '.') {
      // ODK parent-axis '..' (used in position(..)): lex as one token so
      // function argument parsing sees a single argument.
      if (_pos + 1 < _input.length && _input[_pos + 1] == '.') {
        _pos += 2;
        return const _Token(_TokenType.ident, '..');
      }
      // Standalone '.' refers to the current answer in constraints.
      _pos++;
      return const _Token(_TokenType.ident, '.');
    }

    if (_isIdentStart(ch)) {
      return _lexIdent();
    }

    return _lexOperator();
  }

  _Token _lexString(String quote) {
    final start = _pos;
    _pos++; // skip opening quote
    final buffer = StringBuffer();
    while (_pos < _input.length && _input[_pos] != quote) {
      buffer.write(_input[_pos]);
      _pos++;
    }
    if (_pos < _input.length) _pos++; // skip closing quote
    if (_pos >= _input.length && _input[_pos - 1] == quote && start == _pos - 1) {
      _pos++;
    }
    return _Token(_TokenType.string, buffer.toString().replaceAllMapped(
      RegExp(r'\\(.)'),
      (m) => m.group(1)!,
    ));
  }

  _Token _lexField() {
    _pos++; // skip $
    if (_pos < _input.length && _input[_pos] == '{') {
      _pos++; // skip {
      final buffer = StringBuffer();
      while (_pos < _input.length && _input[_pos] != '}') {
        buffer.write(_input[_pos]);
        _pos++;
      }
      if (_pos < _input.length) _pos++; // skip }
      return _Token(_TokenType.field, buffer.toString().trim());
    }
    return const _Token(_TokenType.field, '');
  }

  _Token _lexNumber() {
    final start = _pos;
    while (_pos < _input.length && _isDigit(_input[_pos])) {
      _pos++;
    }
    if (_pos < _input.length &&
        _input[_pos] == '.' &&
        _pos + 1 < _input.length &&
        _isDigit(_input[_pos + 1])) {
      _pos++;
      while (_pos < _input.length && _isDigit(_input[_pos])) {
        _pos++;
      }
    }
    return _Token(_TokenType.number, _input.substring(start, _pos));
  }

  _Token _lexIdent() {
    final start = _pos;
    while (_pos < _input.length && _isIdentPart(_input[_pos])) {
      _pos++;
    }
    final word = _input.substring(start, _pos).toLowerCase();
    switch (word) {
      case 'and':
        return _Token(_TokenType.and, word);
      case 'or':
        return _Token(_TokenType.or, word);
      case 'not':
        return _Token(_TokenType.not, word);
      default:
        return _Token(_TokenType.ident, word);
    }
  }

  _Token _lexOperator() {
    final rest = _input.substring(_pos);
    const twoCharOps = ['!=', '<=', '>='];
    for (final op in twoCharOps) {
      if (rest.startsWith(op)) {
        _pos += 2;
        return _Token(_TokenType.operator, op);
      }
    }
    final ch = _input[_pos++];
    if ('=<>+-*/%'.contains(ch)) {
      return _Token(_TokenType.operator, ch);
    }
    // Unknown character: skip it.
    return _next();
  }

  bool _isDigit(String ch) => ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39;

  bool _isIdentStart(String ch) =>
      ch.codeUnitAt(0) >= 0x41 && ch.codeUnitAt(0) <= 0x5A ||
      ch.codeUnitAt(0) >= 0x61 && ch.codeUnitAt(0) <= 0x7A ||
      ch == '_';

  bool _isIdentPart(String ch) => _isIdentStart(ch) || _isDigit(ch);
}

class _Parser {
  final List<_Token> _tokens;
  final Map<String, dynamic> _answers;
  int _pos = 0;

  _Parser(this._tokens, this._answers);

  dynamic parse() {
    final value = parseOr();
    return value;
  }

  dynamic parseOr() {
    var left = parseAnd();
    while (_peek().type == _TokenType.or) {
      _advance();
      final right = parseAnd();
      left = _isTruthy(left) || _isTruthy(right);
    }
    return left;
  }

  dynamic parseAnd() {
    var left = parseNot();
    while (_peek().type == _TokenType.and) {
      _advance();
      final right = parseNot();
      left = _isTruthy(left) && _isTruthy(right);
    }
    return left;
  }

  dynamic parseNot() {
    if (_peek().type == _TokenType.not) {
      _advance();
      final value = parseNot();
      return !_isTruthy(value);
    }
    return parseComparison();
  }

  dynamic parseComparison() {
    var left = parseAdditive();
    while (_peek().type == _TokenType.operator &&
        ['=', '!=', '<', '>', '<=', '>='].contains(_peek().lexeme)) {
      final op = _advance().lexeme;
      final right = parseAdditive();
      left = _compare(op, left, right);
    }
    return left;
  }

  dynamic parseAdditive() {
    var left = parseMultiplicative();
    while (_peek().type == _TokenType.operator && ['+', '-'].contains(_peek().lexeme)) {
      final op = _advance().lexeme;
      final right = parseMultiplicative();
      // ODK coerces numeric strings: '3' + 0 = 3 (critical for
      // coalesce(${count}, 0) + ... totals over string answers).
      final leftNum = _tryNum(left);
      final rightNum = _tryNum(right);
      if (leftNum != null && rightNum != null) {
        left = op == '+' ? leftNum + rightNum : leftNum - rightNum;
      } else if (op == '+') {
        // Fall back to string concatenation for '+'.
        left = '${left ?? ''}${right ?? ''}';
      } else {
        throw const FormatException('Non-numeric operand for arithmetic');
      }
    }
    return left;
  }

  /// Numeric value of an operand, coercing numeric strings (answers arrive
  /// as strings from text fields). Null for anything non-numeric.
  static num? _tryNum(dynamic value) {
    if (value is num) return value;
    if (value == null || value is bool) return null;
    return num.tryParse(value.toString().trim());
  }

  dynamic parseMultiplicative() {
    var left = parseUnary();
    while (_peek().type == _TokenType.operator && ['*', '/', '%'].contains(_peek().lexeme)) {
      final op = _advance().lexeme;
      final right = parseUnary();
      final leftNum = _tryNum(left);
      final rightNum = _tryNum(right);
      if (leftNum == null || rightNum == null) {
        throw const FormatException('Non-numeric operand for arithmetic');
      }
      switch (op) {
        case '*':
          left = leftNum * rightNum;
        case '/':
          if (rightNum == 0) throw const FormatException('Division by zero');
          left = leftNum / rightNum;
        case '%':
          left = leftNum % rightNum;
      }
    }
    return left;
  }

  dynamic parseUnary() {
    if (_peek().type == _TokenType.operator && _peek().lexeme == '-') {
      _advance();
      final value = parseUnary();
      final n = _tryNum(value);
      if (n == null) {
        throw const FormatException('Non-numeric operand for unary minus');
      }
      return -n;
    }
    return parsePrimary();
  }

  dynamic parsePrimary() {
    final token = _peek();
    switch (token.type) {
      case _TokenType.number:
        _advance();
        return num.parse(token.lexeme);
      case _TokenType.string:
        _advance();
        return token.lexeme;
      case _TokenType.field:
        _advance();
        return _answers[token.lexeme];
      case _TokenType.ident:
        final name = token.lexeme;
        _advance();
        // Hyphenated ODK function names: format-date, selected-at, ...
        var fullName = name;
        while (_peek().type == _TokenType.operator &&
            _peek().lexeme == '-' &&
            _pos + 1 < _tokens.length &&
            _tokens[_pos + 1].type == _TokenType.ident) {
          _advance(); // consume '-'
          fullName += '-${_advance().lexeme}';
        }
        if (_peek().type == _TokenType.lparen) {
          // Legacy special syntax for selected(${f}, 'v').
          if (fullName == 'selected') return _parseSelected();
          return _parseFunctionCall(fullName);
        }
        if (name == 'true' || name == 'yes') return true;
        if (name == 'false' || name == 'no') return false;
        return _answers[name];
      case _TokenType.lparen:
        _advance();
        final value = parseOr();
        if (_peek().type != _TokenType.rparen) {
          throw const FormatException('Missing closing parenthesis');
        }
        _advance();
        return value;
      default:
        throw const FormatException('Unexpected token');
    }
  }

  /// Parses `selected(${field}, 'value')` or `selected($field, 'value')`,
  /// matching XLSForm's `selected()` helper for multi-select questions.
  dynamic _parseSelected() {
    if (_peek().type != _TokenType.lparen) {
      throw const FormatException('Expected ( after selected');
    }
    _advance();
    final fieldToken = _peek();
    if (fieldToken.type != _TokenType.field && fieldToken.type != _TokenType.ident) {
      throw const FormatException('selected() expects a field reference');
    }
    _advance();
    if (_peek().type != _TokenType.comma) {
      throw const FormatException('selected() expects a value argument');
    }
    _advance();
    final valueToken = _peek();
    if (valueToken.type != _TokenType.string && valueToken.type != _TokenType.number) {
      throw const FormatException('selected() expects a string/number value');
    }
    _advance();
    if (_peek().type != _TokenType.rparen) {
      throw const FormatException('Missing closing parenthesis in selected()');
    }
    _advance();

    final fieldName = fieldToken.lexeme;
    final expected = valueToken.lexeme;
    final actual = _answers[fieldName];
    if (actual is List) {
      return actual.any((item) => item.toString() == expected);
    }
    return actual?.toString() == expected;
  }

  /// Parses a generic function call `name(arg, ...)` after the opening
  /// parenthesis has been confirmed.
  dynamic _parseFunctionCall(String name) {
    _advance(); // consume '('
    final args = <dynamic>[];
    if (_peek().type != _TokenType.rparen) {
      args.add(parseOr());
      while (_peek().type == _TokenType.comma) {
        _advance();
        args.add(parseOr());
      }
    }
    if (_peek().type != _TokenType.rparen) {
      throw FormatException('Missing closing parenthesis in $name()');
    }
    _advance();
    return _callFunction(name, args);
  }

  /// ODK function library. Throws [FormatException] on bad arguments; the
  /// public evaluate* entry points convert that into null / fail-open.
  dynamic _callFunction(String name, List<dynamic> args) {
    switch (name) {
      // -- dates & times (device-local, like ODK Collect) --
      case 'now':
        _requireArgCount(name, args, 0, 0);
        return DateTime.now();
      case 'today':
        _requireArgCount(name, args, 0, 0);
        final n = DateTime.now();
        return DateTime(n.year, n.month, n.day);
      case 'date':
        _requireArgCount(name, args, 0, 1);
        if (args.isEmpty) {
          final n = DateTime.now();
          return DateTime(n.year, n.month, n.day);
        }
        final d = _toDateTime(args[0]);
        if (d == null) throw FormatException('date() got an unparsable value');
        return DateTime(d.year, d.month, d.day);
      case 'time':
        _requireArgCount(name, args, 0, 1);
        final n = DateTime.now();
        if (args.isEmpty) return n;
        final t = _toDateTime(args[0]);
        if (t == null) throw FormatException('time() got an unparsable value');
        return DateTime(n.year, n.month, n.day, t.hour, t.minute, t.second);
      case 'format-date':
      case 'format-date-time':
        _requireArgCount(name, args, 2, 2);
        final d = _toDateTime(args[0]);
        if (d == null) {
          throw FormatException('$name() got an unparsable date');
        }
        return _formatDateTime(d, _str(args[1]));

      // -- strings --
      case 'concat':
        return args.map(_str).join();
      case 'join':
        if (args.isEmpty) {
          throw FormatException('join() needs a separator argument');
        }
        final sep = _str(args[0]);
        final parts = <String>[];
        for (final a in args.skip(1)) {
          if (a == null) continue;
          if (a is List) {
            parts.addAll(a.map((e) => e?.toString() ?? ''));
          } else {
            parts.add(_str(a));
          }
        }
        return parts.join(sep);
      case 'string-length':
        _requireArgCount(name, args, 1, 1);
        return _str(args[0]).length;
      case 'substr':
        _requireArgCount(name, args, 2, 3);
        final s = _str(args[0]);
        var start = _num(args[1]).toInt() - 1; // XPath is 1-based
        if (start < 0) start = 0;
        if (start >= s.length) return '';
        if (args.length > 2) {
          final len = _num(args[2]).toInt();
          if (len <= 0) return '';
          final end = (start + len).clamp(0, s.length);
          return s.substring(start, end);
        }
        return s.substring(start);
      case 'upper':
        _requireArgCount(name, args, 1, 1);
        return _str(args[0]).toUpperCase();
      case 'lower':
        _requireArgCount(name, args, 1, 1);
        return _str(args[0]).toLowerCase();
      case 'contains':
        _requireArgCount(name, args, 2, 2);
        return _str(args[0]).contains(_str(args[1]));
      case 'regex':
        // ODK regex(value, pattern) uses full-match semantics (Java
        // String.matches): the whole value must match, so the pattern is
        // anchored. Existing ^/$ anchors in form patterns stay harmless.
        _requireArgCount(name, args, 2, 2);
        final subject = _str(args[0]);
        final pattern = _str(args[1]);
        try {
          return RegExp('^(?:$pattern)\$').hasMatch(subject);
        } catch (_) {
          throw FormatException('regex() got an invalid pattern');
        }
      case 'starts-with':
        _requireArgCount(name, args, 2, 2);
        return _str(args[0]).startsWith(_str(args[1]));
      case 'ends-with':
        _requireArgCount(name, args, 2, 2);
        return _str(args[0]).endsWith(_str(args[1]));

      // -- branching / null handling --
      case 'if':
        _requireArgCount(name, args, 3, 3);
        return _isTruthy(args[0]) ? args[1] : args[2];
      case 'once':
        // ODK once(x): keep the existing value, compute only when blank.
        // The renderer enforces the freeze (skips re-evaluation when the
        // answer is already set); at engine level this evaluates the inner
        // expression, which is the correct fallback everywhere else.
        _requireArgCount(name, args, 1, 1);
        return args[0];
      case 'coalesce':
        if (args.isEmpty) {
          throw FormatException('coalesce() needs at least one argument');
        }
        for (final a in args) {
          if (a == null) continue;
          if (a is String && a.isEmpty) continue;
          return a;
        }
        return '';

      // -- multi-select helpers --
      case 'count-selected':
        _requireArgCount(name, args, 1, 1);
        final v = args[0];
        if (v == null) return 0;
        if (v is List) return v.length;
        final parts = v
            .toString()
            .split(RegExp(r'\s+'))
            .where((e) => e.isNotEmpty)
            .toList();
        return parts.length;
      case 'selected-at':
        _requireArgCount(name, args, 2, 2);
        final v = args[0];
        final pos = _num(args[1]).toInt();
        List<String> items;
        if (v is List) {
          items = v.map((e) => e?.toString() ?? '').toList();
        } else if (v == null) {
          return '';
        } else {
          items = v
              .toString()
              .split(RegExp(r'\s+'))
              .where((e) => e.isNotEmpty)
              .toList();
        }
        if (pos < 0 || pos >= items.length) return '';
        return items[pos];

      // -- math --
      case 'sum':
        // ODK sum() aggregates a repeat; outside repeats it simply totals
        // its arguments (lists flattened, null/blank skipped).
        if (args.isEmpty) return 0;
        var total = 0.0;
        var seen = false;
        void addValue(dynamic v) {
          if (v == null) return;
          if (v is List) {
            for (final e in v) {
              addValue(e);
            }
            return;
          }
          if (v is String && v.trim().isEmpty) return;
          total += _num(v).toDouble();
          seen = true;
        }

        for (final a in args) {
          addValue(a);
        }
        if (!seen) return 0;
        return total == total.roundToDouble() ? total.toInt() : total;
      case 'round':
        _requireArgCount(name, args, 1, 2);
        final x = _num(args[0]).toDouble();
        final decimals = args.length > 1 ? _num(args[1]).toInt() : 0;
        final factor = _pow10(decimals);
        final shifted = x * factor;
        final rounded =
            shifted >= 0 ? (shifted + 0.5).floor() : (shifted - 0.5).ceil();
        return rounded / factor;
      case 'floor':
        _requireArgCount(name, args, 1, 1);
        return _num(args[0]).toDouble().floor();
      case 'ceil':
        _requireArgCount(name, args, 1, 1);
        return _num(args[0]).toDouble().ceil();
      case 'abs':
        _requireArgCount(name, args, 1, 1);
        final x = _num(args[0]);
        return x is int ? x.abs() : (x as num).abs();
      case 'min':
        if (args.isEmpty) throw FormatException('min() needs arguments');
        return args.map(_num).reduce((a, b) => a < b ? a : b);
      case 'max':
        if (args.isEmpty) throw FormatException('max() needs arguments');
        return args.map(_num).reduce((a, b) => a > b ? a : b);
      case 'pow':
        _requireArgCount(name, args, 2, 2);
        return _powNum(_num(args[0]).toDouble(), _num(args[1]).toDouble());
      case 'sqrt':
        _requireArgCount(name, args, 1, 1);
        final x = _num(args[0]).toDouble();
        if (x < 0) throw const FormatException('sqrt() of negative number');
        return _sqrtNum(x);

      // -- conversions & literals --
      case 'position':
        // ODK position(..): 1-based index inside the current repeat.
        // Repeats render a single instance, so this is always 1.
        return 1;
      case 'number':
        _requireArgCount(name, args, 1, 1);
        return _num(args[0]);
      case 'int':
        _requireArgCount(name, args, 1, 1);
        return _num(args[0]).toDouble().truncate();
      case 'string':
        _requireArgCount(name, args, 1, 1);
        return _str(args[0]);
      case 'boolean':
        _requireArgCount(name, args, 1, 1);
        return _isTruthy(args[0]);
      case 'true':
        _requireArgCount(name, args, 0, 0);
        return true;
      case 'false':
        _requireArgCount(name, args, 0, 0);
        return false;

      default:
        throw FormatException('Unknown function: $name()');
    }
  }

  void _requireArgCount(String name, List<dynamic> args, int min, int max) {
    if (args.length < min || args.length > max) {
      throw FormatException('$name() expects $min..$max argument(s)');
    }
  }

  static String _str(dynamic value) {
    if (value == null) return '';
    if (value is num) return SurveyLogic._formatNumber(value);
    if (value is DateTime) return value.toIso8601String();
    if (value is bool) return value.toString();
    if (value is List) return value.map(_str).join(' ');
    return value.toString();
  }

  static num _num(dynamic value) {
    if (value is num) return value;
    if (value is bool) return value ? 1 : 0;
    final parsed = num.tryParse((value?.toString() ?? '').trim());
    if (parsed == null) throw const FormatException('Expected a number');
    return parsed;
  }

  static double _pow10(int n) {
    var result = 1.0;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  static double _powNum(double base, double exp) {
    // Integer exponents without dart:math dependency.
    if (exp == exp.roundToDouble() && exp.abs() < 64) {
      var result = 1.0;
      final count = exp.abs().toInt();
      for (var i = 0; i < count; i++) {
        result *= base;
      }
      return exp < 0 ? 1 / result : result;
    }
    // Fractional exponents via exp/log series.
    return _expNum(exp * _logNum(base));
  }

  static double _logNum(double x) {
    if (x <= 0) throw const FormatException('log() of non-positive number');
    // Normalize to [1, 2) then use the atanh series for ln.
    var e = 0;
    while (x >= 2) {
      x /= 2;
      e++;
    }
    while (x < 1) {
      x *= 2;
      e--;
    }
    final y = (x - 1) / (x + 1);
    final y2 = y * y;
    var term = y;
    var sum = 0.0;
    for (var n = 1; n <= 101; n += 2) {
      sum += term / n;
      term *= y2;
    }
    const ln2 = 0.6931471805599453;
    return 2 * sum + e * ln2;
  }

  static double _expNum(double x) {
    var term = 1.0;
    var sum = 1.0;
    for (var n = 1; n <= 60; n++) {
      term *= x / n;
      sum += term;
    }
    return sum;
  }

  static double _sqrtNum(double x) {
    if (x == 0) return 0;
    var guess = x > 1 ? x / 2 : 1.0;
    for (var i = 0; i < 40; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  /// Parses ISO date/datetime strings or `HH:MM[:SS]` time-of-day strings
  /// (resolved against today). Returns null when unparsable.
  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {}
    final tm = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(s);
    if (tm != null) {
      final now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(tm.group(1)!),
        int.parse(tm.group(2)!),
        tm.group(3) != null ? int.parse(tm.group(3)!) : 0,
      );
    }
    return null;
  }

  static const List<String> _monthNamesFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> _monthNamesShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<String> _weekdayNamesFull = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  static const List<String> _weekdayNamesShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  /// Formats a date with ODK `%`-style specifiers (%Y %y %m %d %e %H %M %S
  /// %b %h %B %a %A %p and %%).
  static String _formatDateTime(DateTime dt, String format) {
    var out = format;
    out = out.replaceAll('%Y', dt.year.toString().padLeft(4, '0'));
    out = out.replaceAll('%y', (dt.year % 100).toString().padLeft(2, '0'));
    out = out.replaceAll('%m', dt.month.toString().padLeft(2, '0'));
    out = out.replaceAll('%d', dt.day.toString().padLeft(2, '0'));
    out = out.replaceAll('%e', dt.day.toString());
    out = out.replaceAll('%H', dt.hour.toString().padLeft(2, '0'));
    out = out.replaceAll('%M', dt.minute.toString().padLeft(2, '0'));
    out = out.replaceAll('%S', dt.second.toString().padLeft(2, '0'));
    out = out.replaceAll('%b', _monthNamesShort[dt.month - 1]);
    out = out.replaceAll('%h', _monthNamesShort[dt.month - 1]);
    out = out.replaceAll('%B', _monthNamesFull[dt.month - 1]);
    out = out.replaceAll('%a', _weekdayNamesShort[dt.weekday - 1]);
    out = out.replaceAll('%A', _weekdayNamesFull[dt.weekday - 1]);
    out = out.replaceAll('%p', dt.hour < 12 ? 'AM' : 'PM');
    out = out.replaceAll('%%', '%');
    return out;
  }

  dynamic _compare(String op, dynamic left, dynamic right) {
    switch (op) {
      case '=':
        return _toString(left) == _toString(right);
      case '!=':
        return _toString(left) != _toString(right);
      case '<':
      case '>':
      case '<=':
      case '>=':
        if (left is num && right is num) {
          switch (op) {
            case '<':
              return left < right;
            case '>':
              return left > right;
            case '<=':
              return left <= right;
            case '>=':
              return left >= right;
          }
        }
        // Date/datetime comparison (ISO strings and DateTime objects mix).
        final leftDt = _tryParseDate(left);
        final rightDt = _tryParseDate(right);
        if (leftDt != null && rightDt != null) {
          final c = leftDt.compareTo(rightDt);
          switch (op) {
            case '<':
              return c < 0;
            case '>':
              return c > 0;
            case '<=':
              return c <= 0;
            case '>=':
              return c >= 0;
          }
        }
        // Fall back to lexicographic comparison for strings.
        final a = _toString(left);
        final b = _toString(right);
        switch (op) {
          case '<':
            return a.compareTo(b) < 0;
          case '>':
            return a.compareTo(b) > 0;
          case '<=':
            return a.compareTo(b) <= 0;
          case '>=':
            return a.compareTo(b) >= 0;
        }
    }
    return false;
  }

  String _toString(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  /// Parses a value into a [DateTime] for comparisons: DateTime objects pass
  /// through, date-like strings (containing `-`, `/`, `T` or `:`) are parsed.
  /// Returns null for anything else so plain words/numbers never compare
  /// as dates.
  static DateTime? _tryParseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is! String) return null;
    final s = value.trim();
    if (!RegExp(r'[-/T:]').hasMatch(s)) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  _Token _peek() => _tokens[_pos];

  _Token _advance() => _tokens[_pos++];

  static bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    return true;
  }
}