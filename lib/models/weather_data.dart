class WeatherSample {
  const WeatherSample({
    required this.time,
    required this.temperatureC,
    required this.relativeHumidity,
    required this.windSpeedKmh,
    required this.precipitationMm,
  });

  final DateTime time;
  final double temperatureC;
  final double relativeHumidity;
  final double windSpeedKmh;
  final double precipitationMm;
}

class WeatherData {
  const WeatherData({
    required this.time,
    required this.temperatureC,
    required this.relativeHumidity,
    required this.apparentTemperatureC,
    required this.precipitationMm,
    required this.windSpeedKmh,
    required this.windDirectionDegrees,
    required this.weatherCode,
    required this.timezone,
    required this.hourly,
    required this.fetchedAt,
  });

  final DateTime time;
  final double temperatureC;
  final double relativeHumidity;
  final double apparentTemperatureC;
  final double precipitationMm;
  final double windSpeedKmh;
  final double windDirectionDegrees;
  final int weatherCode;
  final String timezone;
  final List<WeatherSample> hourly;
  final DateTime fetchedAt;

  factory WeatherData.fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
  }) {
    final current = _asMap(json['current'], 'current');
    final hourlyJson = _asMap(json['hourly'], 'hourly');
    final currentTime = _asDateTime(current['time'], 'current.time');

    final times = _asList(hourlyJson['time'], 'hourly.time');
    final temperatures =
        _asList(hourlyJson['temperature_2m'], 'hourly.temperature_2m');
    final humidities = _asList(
      hourlyJson['relative_humidity_2m'],
      'hourly.relative_humidity_2m',
    );
    final windSpeeds =
        _asList(hourlyJson['wind_speed_10m'], 'hourly.wind_speed_10m');
    final precipitations =
        _asList(hourlyJson['precipitation'], 'hourly.precipitation');

    final hourlyLength = [
      times.length,
      temperatures.length,
      humidities.length,
      windSpeeds.length,
      precipitations.length,
    ].reduce((a, b) => a < b ? a : b);

    final samples = <WeatherSample>[];
    for (var index = 0; index < hourlyLength; index++) {
      if (samples.length >= 24) break;
      final timeValue = times[index];
      if (timeValue is! String) continue;

      final parsedTime = DateTime.tryParse(timeValue);
      final temperature = _asNullableDouble(temperatures[index]);
      final humidity = _asNullableDouble(humidities[index]);
      final windSpeed = _asNullableDouble(windSpeeds[index]);
      final precipitation = _asNullableDouble(precipitations[index]);

      if (parsedTime == null ||
          parsedTime.isBefore(currentTime) ||
          temperature == null ||
          humidity == null ||
          windSpeed == null ||
          precipitation == null) {
        continue;
      }

      samples.add(
        WeatherSample(
          time: parsedTime,
          temperatureC: temperature,
          relativeHumidity: humidity,
          windSpeedKmh: windSpeed,
          precipitationMm: precipitation,
        ),
      );
    }

    return WeatherData(
      time: currentTime,
      temperatureC: _asDouble(current, 'temperature_2m'),
      relativeHumidity: _asDouble(current, 'relative_humidity_2m'),
      apparentTemperatureC: _asDouble(current, 'apparent_temperature'),
      precipitationMm: _asDouble(current, 'precipitation'),
      windSpeedKmh: _asDouble(current, 'wind_speed_10m'),
      windDirectionDegrees: _asDouble(current, 'wind_direction_10m'),
      weatherCode: _asInt(current, 'weather_code'),
      timezone: json['timezone'] is String ? json['timezone'] as String : 'auto',
      hourly: List.unmodifiable(samples),
      fetchedAt: fetchedAt ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> _asMap(Object? value, String field) {
    if (value is Map<String, dynamic>) return value;
    throw FormatException('La respuesta de Open-Meteo no contiene $field.');
  }

  static List<Object?> _asList(Object? value, String field) {
    if (value is List) return value.cast<Object?>();
    throw FormatException('La respuesta de Open-Meteo no contiene $field.');
  }

  static double _asDouble(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is num) return value.toDouble();
    throw FormatException('El campo "$key" no contiene un valor numérico.');
  }

  static int _asInt(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is num) return value.round();
    throw FormatException('El campo "$key" no contiene un valor numérico.');
  }

  static double? _asNullableDouble(Object? value) {
    return value is num ? value.toDouble() : null;
  }

  static DateTime _asDateTime(Object? value, String field) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('El campo "$field" no contiene una fecha válida.');
  }
}
