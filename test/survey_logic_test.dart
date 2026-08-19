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
}
