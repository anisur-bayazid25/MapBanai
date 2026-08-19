import 'package:mapbanai/services/survey_logic.dart';

/// Survey form schema and models for defining surveys with conditional logic
/// Compatible with XLSForm/XForm concepts

class SurveyForm {
  final String id;
  final String name;
  final String description;
  final List<Question> questions;
  final int version;

  SurveyForm({
    required this.id,
    required this.name,
    required this.description,
    required this.questions,
    this.version = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'questions': questions.map((q) => q.toJson()).toList(),
    'version': version,
  };

  factory SurveyForm.fromJson(Map<String, dynamic> json) => SurveyForm(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    questions: (json['questions'] as List?)
        ?.map((q) => Question.fromJson(q))
        .toList() ?? [],
    version: json['version'] ?? 1,
  );
}

class Question {
  final String name;
  final String label;
  final QuestionType type;
  final String? hint;
  final bool required;
  final String? relevance; // e.g., "${previous_question} = 'yes'"
  final String? constraint; // e.g., ". > 0 and . < 150"
  final String? constraintMessage;
  final List<Choice>? choices; // For select/radio/checkbox types
  final String? defaultValue;
  final bool readOnly;
  final String? calculation; // e.g., "${width} * ${length}"

  Question({
    required this.name,
    required this.label,
    required this.type,
    this.hint,
    this.required = false,
    this.relevance,
    this.constraint,
    this.constraintMessage,
    this.choices,
    this.defaultValue,
    this.readOnly = false,
    this.calculation,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'label': label,
    'type': type.toString().split('.').last,
    'hint': hint,
    'required': required,
    'relevance': relevance,
    'constraint': constraint,
    'constraint_message': constraintMessage,
    'choices': choices?.map((c) => c.toJson()).toList(),
    'default': defaultValue,
    'read_only': readOnly,
    'calculation': calculation,
  };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    name: json['name'] ?? '',
    label: json['label'] ?? '',
    type: _parseQuestionType(json['type']),
    hint: json['hint'],
    required: json['required'] ?? false,
    relevance: json['relevance'],
    constraint: json['constraint'],
    constraintMessage: json['constraint_message'],
    choices: (json['choices'] as List?)
        ?.map((c) => Choice.fromJson(c))
        .toList(),
    defaultValue: json['default'],
    readOnly: json['read_only'] ?? false,
    calculation: json['calculation'],
  );

  bool isRelevant(Map<String, dynamic> answers) {
    return SurveyLogic.evaluateRelevance(relevance, answers);
  }
}

enum QuestionType {
  text,
  long_text,
  integer,
  decimal,
  yes_no,
  select_one,
  select_multiple,
  dropdown,
  date,
  time,
  datetime,
  image,
  geopoint,
  calculated,
  note,
  gps_accuracy,
  hidden,
}

QuestionType _parseQuestionType(String? type) {
  switch (type?.toLowerCase()) {
    case 'long_text':
      return QuestionType.long_text;
    case 'integer':
      return QuestionType.integer;
    case 'decimal':
      return QuestionType.decimal;
    case 'yes_no':
      return QuestionType.yes_no;
    case 'select_one':
      return QuestionType.select_one;
    case 'select_multiple':
      return QuestionType.select_multiple;
    case 'dropdown':
      return QuestionType.dropdown;
    case 'date':
      return QuestionType.date;
    case 'time':
      return QuestionType.time;
    case 'datetime':
      return QuestionType.datetime;
    case 'image':
      return QuestionType.image;
    case 'geopoint':
      return QuestionType.geopoint;
    case 'calculated':
      return QuestionType.calculated;
    case 'note':
      return QuestionType.note;
    case 'gps_accuracy':
      return QuestionType.gps_accuracy;
    case 'hidden':
      return QuestionType.hidden;
    default:
      return QuestionType.text;
  }
}

class Choice {
  final String name;
  final String label;

  Choice({required this.name, required this.label});

  Map<String, dynamic> toJson() => {
    'name': name,
    'label': label,
  };

  factory Choice.fromJson(Map<String, dynamic> json) => Choice(
    name: json['name'] ?? '',
    label: json['label'] ?? '',
  );
}

// Example survey definitions that users can reference

class SurveyExamples {
  static SurveyForm riverBankSurvey() => SurveyForm(
    id: 'riverbank_v1',
    name: 'Riverbank Inspection',
    description: 'Field assessment of riverbank conditions',
    questions: [
      Question(
        name: 'site_name',
        label: 'Site name',
        type: QuestionType.text,
        required: true,
        hint: 'e.g., Jones Creek North Section',
      ),
      Question(
        name: 'erosion_present',
        label: 'Is erosion visible?',
        type: QuestionType.select_one,
        required: true,
        choices: [
          Choice(name: 'yes', label: 'Yes'),
          Choice(name: 'no', label: 'No'),
          Choice(name: 'unclear', label: 'Unclear'),
        ],
      ),
      Question(
        name: 'erosion_severity',
        label: 'Erosion severity',
        type: QuestionType.select_one,
        relevance: "\${erosion_present} = 'yes'",
        required: true,
        choices: [
          Choice(name: 'mild', label: 'Mild'),
          Choice(name: 'moderate', label: 'Moderate'),
          Choice(name: 'severe', label: 'Severe'),
        ],
      ),
      Question(
        name: 'erosion_width',
        label: 'Estimated erosion width (meters)',
        type: QuestionType.decimal,
        relevance: "\${erosion_present} = 'yes'",
        constraint: '. > 0 and . < 100',
        constraintMessage: 'Width must be between 0 and 100 meters',
      ),
      Question(
        name: 'vegetation_coverage',
        label: 'Vegetation coverage (%)',
        type: QuestionType.integer,
        constraint: '. >= 0 and . <= 100',
        constraintMessage: 'Must be between 0 and 100%',
      ),
      Question(
        name: 'notes',
        label: 'Additional observations',
        type: QuestionType.text,
        hint: 'Any other relevant details',
      ),
    ],
  );

  static SurveyForm infrastructureSurvey() => SurveyForm(
    id: 'infrastructure_v1',
    name: 'Infrastructure Assessment',
    description: 'Condition assessment of water infrastructure',
    questions: [
      Question(
        name: 'structure_type',
        label: 'Structure type',
        type: QuestionType.select_one,
        required: true,
        choices: [
          Choice(name: 'culvert', label: 'Culvert'),
          Choice(name: 'bridge', label: 'Bridge'),
          Choice(name: 'dam', label: 'Dam'),
          Choice(name: 'weir', label: 'Weir'),
        ],
      ),
      Question(
        name: 'condition',
        label: 'Overall condition',
        type: QuestionType.select_one,
        required: true,
        choices: [
          Choice(name: 'good', label: 'Good'),
          Choice(name: 'fair', label: 'Fair'),
          Choice(name: 'poor', label: 'Poor'),
        ],
      ),
      Question(
        name: 'maintenance_needed',
        label: 'Does maintenance appear needed?',
        type: QuestionType.select_one,
        required: true,
        choices: [
          Choice(name: 'yes', label: 'Yes'),
          Choice(name: 'no', label: 'No'),
        ],
      ),
      Question(
        name: 'maintenance_type',
        label: 'Type of maintenance needed',
        type: QuestionType.select_multiple,
        relevance: "\${maintenance_needed} = 'yes'",
        choices: [
          Choice(name: 'cleaning', label: 'Cleaning'),
          Choice(name: 'repair', label: 'Repair'),
          Choice(name: 'replacement', label: 'Replacement'),
        ],
      ),
    ],
  );
}
