import 'package:mapbanai/services/study_area_service.dart';

class StudyCategoryStyle {
  static const palette = [
    '#0072B2',
    '#D55E00',
    '#009E73',
    '#CC79A7',
    '#E69F00',
    '#56B4E9',
    '#6A3D9A',
    '#8C510A',
    '#1B7837',
    '#E7298A',
    '#7570B3',
    '#66A61E',
    '#A6761D',
    '#666666',
    '#C51B7D',
    '#01665E'
  ];
  String? column;
  final Map<String, String> colors;
  final Set<String> hidden;
  double radius;
  StudyCategoryStyle(
      {this.column,
      Map<String, String>? colors,
      Set<String>? hidden,
      this.radius = 6})
      : colors = colors ?? {},
        hidden = hidden ?? {};
  String category(StudyAreaSite site) => column == null
      ? 'All features'
      : column == '__verification_status__'
          ? site.status.label
          : (site.attributes[column]?.trim().isNotEmpty == true
              ? site.attributes[column]!.trim()
              : '(No value)');
  String color(StudyAreaSite site) => colors[category(site)] ?? palette[0];
  bool visible(StudyAreaSite site) =>
      column == null || !hidden.contains(category(site));
  List<String> categories(List<StudyAreaSite> sites) {
    final values = sites.map(category).toSet().toList()..sort();
    for (var i = 0; i < values.length; i++) {
      colors.putIfAbsent(
          values[i],
          () => column == '__verification_status__'
              ? sites
                  .firstWhere((site) => category(site) == values[i])
                  .status
                  .mapColor
              : palette[i % palette.length]);
    }
    return values;
  }

  Map<String, dynamic> toJson() => {
        'column': column,
        'colors': colors,
        'hidden': hidden.toList(),
        'radius': radius
      };
  factory StudyCategoryStyle.fromJson(Map<String, dynamic> json) =>
      StudyCategoryStyle(
          column: json['column'] as String?,
          colors: Map<String, String>.from(json['colors'] ?? {}),
          hidden: Set<String>.from(json['hidden'] ?? []),
          radius: ((json['radius'] as num?)?.toDouble() ?? 6).clamp(4, 12));
}
