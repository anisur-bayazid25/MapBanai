import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/models/survey_form.dart';

Position testPosition({
  double lat = 24.7433,
  double lng = 90.3983,
  double accuracy = 5.0,
  double altitude = 33.0,
}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.utc(2026, 8, 17, 12, 0, 0),
    accuracy: accuracy,
    altitude: altitude,
    altitudeAccuracy: 2,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
    floor: null,
    isMocked: false,
  );
}

SurveyForm sampleSurveyForm() {
  return SurveyForm(
    id: 'demo_form',
    name: 'Demo Form',
    description: 'A sample survey form',
    questions: [
      Question(
        name: 'site_name',
        label: 'Site name',
        type: QuestionType.text,
      ),
      Question(
        name: 'height_m',
        label: 'Height (m)',
        type: QuestionType.integer,
        required: true,
      ),
    ],
    version: 1,
  );
}