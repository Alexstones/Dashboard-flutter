import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_environment_dashboard/main.dart';

void main() {
  testWidgets('El dashboard presenta el proyecto y las métricas', (tester) async {
    await tester.pumpWidget(const SmartEnvironmentApp());
    expect(find.text('Smart-Environment IoT'), findsOneWidget);
    expect(find.text('Temperatura'), findsWidgets);
    expect(find.text('Humedad'), findsWidgets);
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });
}
