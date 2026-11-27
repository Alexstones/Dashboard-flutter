import 'package:flutter_test/flutter_test.dart';
import 'package:smart_environment_dashboard/models/weather_data.dart';

void main() {
  test('interpreta los datos actuales y el pronóstico horario', () {
    final fetchedAt = DateTime(2026, 11, 26, 16);
    final weather = WeatherData.fromJson(
      {
        'timezone': 'America/Chihuahua',
        'current': {
          'time': '2026-11-26T16:00',
          'temperature_2m': 24.5,
          'relative_humidity_2m': 38,
          'apparent_temperature': 24.1,
          'precipitation': 0.0,
          'wind_speed_10m': 12.4,
          'wind_direction_10m': 180,
          'weather_code': 1,
        },
        'hourly': {
          'time': [
            '2026-11-26T15:00',
            '2026-11-26T16:00',
            '2026-11-26T17:00',
          ],
          'temperature_2m': [25.0, 24.5, 23.8],
          'relative_humidity_2m': [36, 38, 40],
          'wind_speed_10m': [13.0, 12.4, 10.2],
          'precipitation': [0.0, 0.0, 0.1],
        },
      },
      fetchedAt: fetchedAt,
    );

    expect(weather.temperatureC, 24.5);
    expect(weather.relativeHumidity, 38);
    expect(weather.apparentTemperatureC, 24.1);
    expect(weather.windSpeedKmh, 12.4);
    expect(weather.weatherCode, 1);
    expect(weather.timezone, 'America/Chihuahua');
    expect(weather.hourly, hasLength(2));
    expect(weather.hourly.first.time, DateTime(2026, 11, 26, 16));
    expect(weather.hourly.last.precipitationMm, 0.1);
    expect(weather.fetchedAt, fetchedAt);
  });

  test('rechaza respuestas sin campos actuales requeridos', () {
    expect(
      () => WeatherData.fromJson({'current': {}, 'hourly': {}}),
      throwsA(isA<FormatException>()),
    );
  });
}
