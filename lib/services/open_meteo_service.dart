import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_data.dart';

class WeatherApiException implements Exception {
  const WeatherApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OpenMeteoService {
  OpenMeteoService({
    http.Client? client,
    this.latitude = defaultLatitude,
    this.longitude = defaultLongitude,
    this.timeout = const Duration(seconds: 15),
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  static const double defaultLatitude = 28.6353;
  static const double defaultLongitude = -106.0889;

  final http.Client _client;
  final bool _ownsClient;
  final double latitude;
  final double longitude;
  final Duration timeout;

  static const _currentVariables = [
    'temperature_2m',
    'relative_humidity_2m',
    'apparent_temperature',
    'precipitation',
    'wind_speed_10m',
    'wind_direction_10m',
    'weather_code',
  ];

  static const _hourlyVariables = [
    'temperature_2m',
    'relative_humidity_2m',
    'wind_speed_10m',
    'precipitation',
  ];

  Uri get requestUri => Uri.https(
        'api.open-meteo.com',
        '/v1/forecast',
        {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'current': _currentVariables.join(','),
          'hourly': _hourlyVariables.join(','),
          'forecast_days': '2',
          'timezone': 'auto',
          'temperature_unit': 'celsius',
          'wind_speed_unit': 'kmh',
          'precipitation_unit': 'mm',
        },
      );

  Future<WeatherData> fetchWeather() async {
    final response = await _client
        .get(
          requestUri,
          headers: const {'Accept': 'application/json'},
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw WeatherApiException(
        'Open-Meteo respondió con el código HTTP ${response.statusCode}.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const WeatherApiException(
        'Open-Meteo devolvió una respuesta JSON inválida.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const WeatherApiException(
        'La respuesta de Open-Meteo tiene un formato inesperado.',
      );
    }

    if (decoded['error'] == true) {
      final reason = decoded['reason'];
      throw WeatherApiException(
        reason is String ? reason : 'Open-Meteo informó un error.',
      );
    }

    try {
      return WeatherData.fromJson(decoded);
    } on FormatException catch (error) {
      throw WeatherApiException(
        'No se pudieron interpretar los datos meteorológicos: ${error.message}',
      );
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
