/// XLSForm-style expression engine for survey logic.
///
/// Supports three expression types used by forms:
/// - **Relevance** (visibility): `${field} = 'value'`, comparisons, `and`,
///   `or`, `not`, parentheses, and `selected(${multi_field}, 'value')`.
/// - **Calculation** (computed answers): arithmetic over `${field}` refs,
///   e.g. `${width} * ${length}`.
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
      if (value is String || value is bool) return value.toString();
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

  static bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    return true;
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
      if (left is num && right is num) {
        left = op == '+' ? left + right : left - right;
      } else {
        // Fall back to string concatenation for '+'.
        left = op == '+' ? '${left ?? ''}${right ?? ''}' : left;
      }
    }
    return left;
  }

  dynamic parseMultiplicative() {
    var left = parseUnary();
    while (_peek().type == _TokenType.operator && ['*', '/', '%'].contains(_peek().lexeme)) {
      final op = _advance().lexeme;
      final right = parseUnary();
      if (left is num && right is num) {
        switch (op) {
          case '*':
            left = left * right;
          case '/':
            if (right == 0) throw const FormatException('Division by zero');
            left = left / right;
          case '%':
            left = left % right;
        }
      } else {
        throw const FormatException('Non-numeric operand for arithmetic');
      }
    }
    return left;
  }

  dynamic parseUnary() {
    if (_peek().type == _TokenType.operator && _peek().lexeme == '-') {
      _advance();
      final value = parseUnary();
      if (value is num) return -value;
      throw const FormatException('Non-numeric operand for unary minus');
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
        _advance();
        if (token.lexeme == 'selected') {
          return _parseSelected();
        }
        if (token.lexeme == 'true' || token.lexeme == 'yes') return true;
        if (token.lexeme == 'false' || token.lexeme == 'no') return false;
        return _answers[token.lexeme];
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

  String _toString(dynamic value) => value?.toString() ?? '';

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