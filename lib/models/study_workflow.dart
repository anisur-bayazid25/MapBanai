enum StudyWorkflow {
  verification,
  recurring,
  visits;

  String get title => switch (this) {
        verification => 'Field Verification',
        recurring => 'Recurring Collection',
        visits => 'Study Area Visits',
      };
  String get description => switch (this) {
        verification => 'Check locations and update existing features.',
        recurring => 'Collect measurements at the same sites each round.',
        visits => 'Visit facilities and track done, pending or review.',
      };
  static StudyWorkflow parse(String? value) =>
      values.where((mode) => mode.name == value).firstOrNull ?? verification;
}

class CollectionRound {
  final String id;
  final String name;
  final String layerId;
  final String period;
  final String date;
  const CollectionRound(
      {required this.id,
      required this.name,
      required this.layerId,
      this.period = '',
      this.date = ''});
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'layer_id': layerId,
        'period': period,
        'date': date
      };
  factory CollectionRound.fromJson(Map json) => CollectionRound(
      id: json['id'] as String,
      name: json['name'] as String,
      layerId: json['layer_id'] as String,
      period: '${json['period'] ?? ''}',
      date: '${json['date'] ?? ''}');
}
