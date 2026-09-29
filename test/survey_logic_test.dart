import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/services/survey_logic.dart';

void main() {
  group('SurveyLogic.evaluateRelevance', () {
    test('no expression means always visible', () {
      expect(SurveyLogic.evaluateRelevance(null, {}), isTrue);
      expect(SurveyLogic.evaluateRelevance('', {}), isTrue);
      expect(SurveyLogic.evaluateRelevance('   ', {}), isTrue);
    });

    test('simple equality', () {
      expect(
        SurveyLogic.evaluateRelevance("\${erosion_present} = 'yes'", {
          'erosion_present': 'yes',
        }),
        isTrue,
      );
      expect(
        SurveyLogic.evaluateRelevance("\${erosion_present} = 'yes'", {
          'erosion_present': 'no',
        }),
        isFalse,
      );
    });

    test('inequality and numeric comparisons', () {
      expect(
        SurveyLogic.evaluateRelevance("\${count} != 5", {'count': 3}),
        isTrue,
      );
      expect(
        SurveyLogic.evaluateRelevance("\${count} > 5", {'count': 10}),
        isTrue,
      );
      expect(
        SurveyLogic.evaluateRelevance("\${count} > 5", {'count': 2}),
        isFalse,
      );
      expect(
        SurveyLogic.evaluateRelevance("\${percent} >= 50.5", {'percent': 50.5}),
        isTrue,
      );
      expect(
        SurveyLogic.evaluateRelevance("\${percent} <= 50", {'percent': 49.9}),
        isTrue,
      );
    });

    test('and / or / not', () {
      expect(
        SurveyLogic.evaluateRelevance(
          "\${a} = 'x' and \${b} = 'y'",
          {'a': 'x', 'b': 'y'},
        ),
        isTrue,
      );
      expect(
        SurveyLogic.evaluateRelevance(
          "\${a} = 'x' and \${b} = 'y'",
          {'a': 'x', 'b': 'z'},
        ),
        isFalse,
      );
      expect(
        SurveyLogic.evaluateRelevance(
          "\${a} = 'x' or \${b} = 'y'",
          {'a': 'z', 'b': 'y'},
        ),
        isTrue,
      );
      expect(
        SurveyLogic.evaluateRelevance("not \${a} = 'x'", {'a': 'z'}),
        isTrue,
      );
      expect(
        SurveyLogic.evaluateRelevance("not \${a} = 'x'", {'a': 'x'}),
        isFalse,
      );
    });

    test('parentheses change precedence', () {
      expect(
        SurveyLogic.evaluateRelevance(
          "(\${a} = 'x' or \${b} = 'y') and \${c} = 'z'",
          {'a': 'x', 'b': 'nope', 'c': 'z'},
        ),
        isTrue,
      );
      expect(
        SurveyLogic.evaluateRelevance(
          "(\${a} = 'x' or \${b} = 'y') and \${c} = 'z'",
          {'a': 'nope', 'b': 'nope', 'c': 'z'},
        ),
        isFalse,
      );
    });

    test('selected() for multi-select', () {
      expect(
        SurveyLogic.evaluateRelevance(
          "selected(\${maintenance}, 'repair')",
          {'maintenance': ['cleaning', 'repair']},
        ),
        isTrue,
      );
      expect(
        SurveyLogic.evaluateRelevance(
          "selected(\${maintenance}, 'replacement')",
          {'maintenance': ['cleaning', 'repair']},
        ),
        isFalse,
      );
    });

    test('garbage expressions fail open (visible)', () {
      expect(SurveyLogic.evaluateRelevance('((((', {}), isTrue);
      expect(SurveyLogic.evaluateRelevance('\${} = ', {}), isTrue);
    });
  });

  group('SurveyLogic.evaluateCalculation', () {
    test('basic arithmetic', () {
      expect(
        SurveyLogic.evaluateCalculation("\${width} * \${length}", {
          'width': 10,
          'length': 5,
        }),
        '50',
      );
      expect(
        SurveyLogic.evaluateCalculation("\${width} * \${length}", {
          'width': 2.5,
          'length': 4,
        }),
        '10',
      );
    });

    test('mixed operators and decimals', () {
      expect(
        SurveyLogic.evaluateCalculation("\${a} + \${b} * 2", {'a': 1, 'b': 3}),
        '7',
      );
      expect(
        SurveyLogic.evaluateCalculation("\${a} / \${b}", {'a': 1, 'b': 3}),
        '0.3333',
      );
      expect(
        SurveyLogic.evaluateCalculation("\${a} % \${b}", {'a': 7, 'b': 3}),
        '1',
      );
    });

    test('string concatenation', () {
      expect(
        SurveyLogic.evaluateCalculation("\${first} + \${last}", {
          'first': 'abc',
          'last': 'def',
        }),
        'abcdef',
      );
    });

    test('missing or non-numeric answers yield null', () {
      expect(SurveyLogic.evaluateCalculation("\${missing} * 2", {}), isNull);
      expect(
        SurveyLogic.evaluateCalculation("\${width} * 2", {'width': 'abc'}),
        isNull,
      );
      expect(SurveyLogic.evaluateCalculation(null, {}), isNull);
    });

    test('division by zero yields null', () {
      expect(
        SurveyLogic.evaluateCalculation("\${a} / \${b}", {'a': 1, 'b': 0}),
        isNull,
      );
    });
  });

  group('SurveyLogic.evaluateConstraint', () {
    test('passing and failing constraints', () {
      expect(SurveyLogic.evaluateConstraint('. > 0 and . < 100', 50, null),
          isNull);
      expect(SurveyLogic.evaluateConstraint('. > 0 and . < 100', 150, null),
          isNotNull);
      expect(SurveyLogic.evaluateConstraint('. >= 0 and . <= 100', 0, null),
          isNull);
    });

    test('uses custom message', () {
      expect(
        SurveyLogic.evaluateConstraint(
          '. > 0 and . < 100',
          200,
          'Must be between 0 and 100 meters',
        ),
        'Must be between 0 and 100 meters',
      );
    });

    test('empty or null answer skips validation', () {
      expect(SurveyLogic.evaluateConstraint('. > 0', null, null), isNull);
      expect(SurveyLogic.evaluateConstraint('. > 0', '', null), isNull);
      expect(SurveyLogic.evaluateConstraint(null, 5, null), isNull);
    });
  });

  group('SurveyLogic ODK functions (v2.4.2)', () {
    test('now() and today() return ISO datetime strings', () {
      final now = SurveyLogic.evaluateCalculation('now()', {});
      expect(now, isNotNull);
      expect(DateTime.tryParse(now!), isNotNull);
      final today = SurveyLogic.evaluateCalculation('today()', {});
      expect(today, isNotNull);
      final parsed = DateTime.parse(today!);
      expect(parsed.hour, 0);
      expect(parsed.minute, 0);
    });

    test('format-date-time() formats with ODK specifiers', () {
      expect(
        SurveyLogic.evaluateCalculation(
          "format-date-time('2024-03-05 14:07:09', '%Y-%m-%d %H:%M')",
          {},
        ),
        '2024-03-05 14:07',
      );
      expect(
        SurveyLogic.evaluateCalculation(
          "format-date('2024-03-05', '%d %b %Y')",
          {},
        ),
        '05 Mar 2024',
      );
    });

    test('start_time style chained date calculation', () {
      // Mirrors the UGGP form: Interview date + start time questions.
      final date = SurveyLogic.evaluateCalculation("date('2024-08-07')", {});
      expect(date, isNotNull);
      expect(DateTime.tryParse(date!), isNotNull);
      expect(
        SurveyLogic.evaluateCalculation(
          "format-date(\${date}, '%Y-%m-%d')",
          {'date': date},
        ),
        '2024-08-07',
      );
    });

    test('concat() and join() build note-style strings', () {
      expect(
        SurveyLogic.evaluateCalculation(
          "concat('Interview date: ', \${date})",
          {'date': '2024-08-07'},
        ),
        'Interview date: 2024-08-07',
      );
      expect(
        SurveyLogic.evaluateCalculation(
          "join(' | ', 'a', 'b', 'c')",
          {},
        ),
        'a | b | c',
      );
    });

    test('if() and coalesce() branch correctly', () {
      expect(
        SurveyLogic.evaluateCalculation(
          "if(\${x} = 'yes', 'Y', 'N')",
          {'x': 'yes'},
        ),
        'Y',
      );
      expect(
        SurveyLogic.evaluateCalculation("coalesce('', \${x}, 'dflt')", {'x': 'v'}),
        'v',
      );
      expect(
        SurveyLogic.evaluateCalculation("coalesce('', 'dflt')", {}),
        'dflt',
      );
    });

    test('string helpers', () {
      expect(
        SurveyLogic.evaluateCalculation("upper('abc')", {}),
        'ABC',
      );
      expect(
        SurveyLogic.evaluateCalculation("substr('abcdef', 2, 3)", {}),
        'bcd',
      );
      expect(
        SurveyLogic.evaluateCalculation("string-length('hello')", {}),
        '5',
      );
      expect(
        SurveyLogic.evaluateRelevance("contains(\${s}, 'ell')", {'s': 'hello'}),
        isTrue,
      );
      expect(
        SurveyLogic.evaluateRelevance(
            "starts-with(\${s}, 'he') and ends-with(\${s}, 'lo')",
            {'s': 'hello'}),
        isTrue,
      );
    });

    test('math helpers', () {
      expect(SurveyLogic.evaluateCalculation('round(2.5)', {}), '3');
      expect(SurveyLogic.evaluateCalculation('round(2.345, 2)', {}), '2.35');
      expect(SurveyLogic.evaluateCalculation('floor(2.9)', {}), '2');
      expect(SurveyLogic.evaluateCalculation('abs(0 - 4)', {}), '4');
      expect(SurveyLogic.evaluateCalculation('max(1, 9, 3)', {}), '9');
      expect(SurveyLogic.evaluateCalculation('min(1, 9, 3)', {}), '1');
      expect(SurveyLogic.evaluateCalculation('pow(2, 3)', {}), '8');
      expect(SurveyLogic.evaluateCalculation('sqrt(16)', {}), '4');
    });

    test('count-selected() and selected-at()', () {
      expect(
        SurveyLogic.evaluateCalculation(
            'count-selected(\${crops})', {
          'crops': ['rice', 'wheat']
        }),
        '2',
      );
      expect(
        SurveyLogic.evaluateCalculation(
            'selected-at(\${crops}, 1)', {
          'crops': ['rice', 'wheat']
        }),
        'wheat',
      );
    });

    test('date comparisons work in relevance', () {
      expect(
        SurveyLogic.evaluateRelevance(
          "\${d} > '2024-01-01'",
          {'d': '2024-08-07'},
        ),
        isTrue,
      );
      expect(
        SurveyLogic.evaluateRelevance(
          "\${d} < '2024-01-01'",
          {'d': '2024-08-07'},
        ),
        isFalse,
      );
    });

    test('unknown functions yield null instead of crashing', () {
      expect(
        SurveyLogic.evaluateCalculation('frobnicate(1, 2)', {}),
        isNull,
      );
      expect(
        SurveyLogic.evaluateRelevance('frobnicate(1) = 1', {}),
        isTrue, // fail-open for visibility
      );
    });
  });

  group('SurveyLogic.stripHtml', () {
    test('removes span/bold tags but keeps text', () {
      expect(
        SurveyLogic.stripHtml(
          '<span style="color:red; font-weight:bold">Extreme Heat</span>',
        ),
        'Extreme Heat',
      );
      expect(
        SurveyLogic.stripHtml('<b>Bold</b> and <i>italic</i>'),
        'Bold and italic',
      );
    });

    test('br and paragraph breaks become newlines', () {
      expect(SurveyLogic.stripHtml('a<br>b'), 'a\nb');
      expect(SurveyLogic.stripHtml('<p>one</p><p>two</p>'), 'one\ntwo');
    });

    test('decodes entities', () {
      expect(
        SurveyLogic.stripHtml('Fish &amp; Chips &nbsp; &#65;'),
        'Fish & Chips   A',
      );
    });

    test('plain text passes through', () {
      expect(
        SurveyLogic.stripHtml('Household Unique Identification Number (ID)'),
        'Household Unique Identification Number (ID)',
      );
    });
  });

  group('SurveyLogic.interpolate', () {
    test('substitutes answer values into note labels', () {
      expect(
        SurveyLogic.interpolate(
          'Interview date: \${date} | Start time: \${start_time}',
          {'date': '2024-08-07', 'start_time': '09:30'},
        ),
        'Interview date: 2024-08-07 | Start time: 09:30',
      );
    });

    test('missing answers become empty strings', () {
      expect(
        SurveyLogic.interpolate('Hi \${name}!', {}),
        'Hi !',
      );
    });

    test('lists are comma-joined', () {
      expect(
        SurveyLogic.interpolate('Crops: \${crops}', {
          'crops': ['rice', 'wheat']
        }),
        'Crops: rice, wheat',
      );
    });
  });

  group('SurveyLogic repeat-adjacent functions (v2.4.3)', () {
    test('once() evaluates its inner expression', () {
      expect(
        SurveyLogic.evaluateCalculation('once(today())', {}),
        isNotNull,
      );
      expect(
        SurveyLogic.evaluateCalculation('once(2 + 3)', {}),
        '5',
      );
    });

    test('sum() totals numerics and skips blanks', () {
      expect(
        SurveyLogic.evaluateCalculation(
          'coalesce(\${a}, 0) + coalesce(\${b}, 0)',
          {'a': '3', 'b': ''},
        ),
        '3',
      );
      expect(
        SurveyLogic.evaluateCalculation('sum(\${v})', {'v': '5000'}),
        '5000',
      );
      expect(SurveyLogic.evaluateCalculation('sum()', {}), '0');
    });

    test('regex() uses full-match semantics', () {
      expect(
        SurveyLogic.evaluateConstraint(
          "regex(., '^[A-Z][a-zA-Z .()]{2,}\$')",
          'John Doe',
          null,
        ),
        isNull,
      );
      expect(
        SurveyLogic.evaluateConstraint(
          "regex(., '^[A-Z][a-zA-Z .()]{2,}\$')",
          'jo',
          'Bad name',
        ),
        'Bad name',
      );
      expect(
        SurveyLogic.evaluateConstraint(
          "regex(., '^01[3-9][0-9]{8}\$') or . = 99",
          '99',
          null,
        ),
        isNull,
      );
      expect(
        SurveyLogic.evaluateConstraint(
          "regex(., '^01[3-9][0-9]{8}\$') or . = 99",
          '01512345678',
          null,
        ),
        isNull,
      );
    });

    test('position() returns 1 outside repeats', () {
      expect(
        SurveyLogic.evaluateCalculation('position(..)', {}),
        '1',
      );
      expect(
        SurveyLogic.evaluateRelevance('position(..) = 1', {}),
        isTrue,
      );
    });
  });

  group('SurveyLogic.parseStyledText (v2.4.3)', () {
    test('span color and bold render as styled runs', () {
      final runs = SurveyLogic.parseStyledText(
        '<span style="color:red; font-weight:bold">Extreme Heat</span> and more',
      );
      expect(runs.length, 2);
      expect(runs[0].text, 'Extreme Heat');
      expect(runs[0].bold, isTrue);
      expect(runs[0].color, 0xFFFF0000);
      expect(runs[1].text, ' and more');
      expect(runs[1].hasStyle, isFalse);
    });

    test('named and hex colors parse', () {
      final maroon = SurveyLogic.parseStyledText(
        '<span style="color:maroon">M</span>',
      );
      expect(maroon.single.color, 0xFF800000);
      final hex = SurveyLogic.parseStyledText(
        '<span style="color:#0066CC">C</span>',
      );
      expect(hex.single.color, 0xFF0066CC);
    });

    test('b/i/u tags and br newlines', () {
      final runs = SurveyLogic.parseStyledText('<b>B</b><i>I</i><u>U</u>a<br/>b');
      expect(runs.map((r) => r.text).join('|'), 'B|I|U|a|\n|b');
      expect(runs[0].bold, isTrue);
      expect(runs[1].italic, isTrue);
      expect(runs[2].underline, isTrue);
    });

    test('malformed tags degrade gracefully', () {
      final runs = SurveyLogic.parseStyledText(
        'Height <span>ok</span> and bad</f3_0 span> tail',
      );
      expect(
        runs.map((r) => r.text).join(),
        'Height ok and bad tail',
      );
    });

    test('plain text yields a single unstyled run', () {
      final runs = SurveyLogic.parseStyledText('Just text');
      expect(runs.length, 1);
      expect(runs.single.hasStyle, isFalse);
    });
  });
}
