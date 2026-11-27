import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_environment_dashboard/main.dart';
import 'package:smart_environment_dashboard/services/open_meteo_service.dart';

void main() {
  testWidgets('el dashboard muestra métricas meteorológicas reales',
      (tester) async {
    final fixture = {
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
        'time': ['2026-11-26T16:00', '2026-11-26T17:00'],
        'temperature_2m': [24.5, 23.8],
        'relative_humidity_2m': [38, 40],
        'wind_speed_10m': [12.4, 10.2],
        'precipitation': [0.0, 0.1],
      },
    };

    final client = MockClient(
      (_) async => http.Response(jsonEncode(fixture), 200),
    );

    await tester.pumpWidget(
      SmartEnvironmentApp(
        weatherService: OpenMeteoService(client: client),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Smart-Environment IoT'), findsOneWidget);
    expect(find.text('Temperatura'), findsWidgets);
    expect(find.text('Humedad relativa'), findsOneWidget);
    expect(find.text('Velocidad del viento'), findsOneWidget);
    expect(find.text('Sensación térmica'), findsOneWidget);
    expect(find.text('Precipitación'), findsOneWidget);
    expect(find.text('OPEN-METEO · API REAL'), findsOneWidget);
    expect(find.text('CONECTADO'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    client.close();
  });
}
