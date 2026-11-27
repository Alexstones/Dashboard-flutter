import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_environment_dashboard/services/open_meteo_service.dart';

Map<String, dynamic> _fixture() => {
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
        'time': ['2026-11-26T16:00'],
        'temperature_2m': [24.5],
        'relative_humidity_2m': [38],
        'wind_speed_10m': [12.4],
        'precipitation': [0.0],
      },
    };

void main() {
  test('consulta Open-Meteo y convierte la respuesta JSON', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.host, 'api.open-meteo.com');
      expect(request.url.path, '/v1/forecast');
      expect(request.url.queryParameters['latitude'], '28.6353');
      expect(request.url.queryParameters['longitude'], '-106.0889');
      expect(request.url.queryParameters['timezone'], 'auto');
      expect(
        request.url.queryParameters['current'],
        contains('apparent_temperature'),
      );
      return http.Response(jsonEncode(_fixture()), 200);
    });

    final service = OpenMeteoService(client: client);
    final weather = await service.fetchWeather();

    expect(weather.temperatureC, 24.5);
    expect(weather.hourly, hasLength(1));
    client.close();
    service.dispose();
  });

  test('informa un error cuando la API devuelve HTTP distinto de 200',
      () async {
    final client = MockClient(
      (_) async => http.Response('Servicio no disponible', 503),
    );
    final service = OpenMeteoService(client: client);

    await expectLater(
      service.fetchWeather(),
      throwsA(isA<WeatherApiException>()),
    );

    client.close();
    service.dispose();
  });

  test('informa cuando la respuesta no es JSON válido', () async {
    final client = MockClient(
      (_) async => http.Response('<html>error</html>', 200),
    );
    final service = OpenMeteoService(client: client);

    await expectLater(
      service.fetchWeather(),
      throwsA(isA<WeatherApiException>()),
    );

    client.close();
    service.dispose();
  });
}
