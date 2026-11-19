# Actividad 3 - Smart-Environment IoT

Dashboard Flutter de datos ambientales **simulados** en tiempo real. No requiere sensores ni conexión a servidores en la demostración. Se utiliza `StreamController`, `Timer.periodic` cada 1 s, `StreamBuilder` y `fl_chart`.

## Instalar desde PowerShell en Windows

> El ZIP contiene `lib/`, `test/` y `pubspec.yaml`. Los directorios de plataforma Android, Windows y Web se generan con el Flutter SDK.

```powershell
cd "$HOME\Proyectos"
# Extrae el ZIP aquí y entra en la carpeta
cd .\smart_environment_dashboard
flutter create --project-name smart_environment_dashboard --platforms android,web,windows .
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d chrome
```

Para un Android conectado por USB y con depuración habilitada: `flutter run -d <id_dispositivo>` (obtener ID con `flutter devices`).

## Para presentar al docente

1. Mostrar las 3 tarjetas de telemetría (temperatura, humedad y CO₂ referencial/aire en ppm).
2. Indicar que los datos se producen cada segundo por `Timer.periodic` y viajan por un Stream a `StreamBuilder`.
3. Demostrar las líneas animadas y tocar puntos para mostrar su valor.
4. Pulsar **Pausar** y **Reanudar** para probar interactividad.
5. Explicar el origen simulado y cómo se sustituirá por las lecturas del ESP32 (no afirmar que sean datos físicos reales).

## Esquema previsto para integrar ESP32

```json
{"temperature": 25.4, "humidity": 58.2, "airPpm": 706, "deviceId": "ESP32-01"}
```

La fuente actual es `SimulatedSensorService` en `lib/main.dart`. Para conectarlo a ThingsBoard o MQTT se debe implementar un origen real que emita `DashboardData` con el mismo tipo de lectura. La integración a un backend real NO está incluida.

## Rúbrica

- Graficación (40): 2 LineCharts con leyendas, ejes, tooltips y animación.
- Flujo real (40): `StreamController` + `Timer.periodic` + `StreamBuilder`; no exige refresco manual.
- Integración (20): modelo ambiental (`temperature`, `humidity`, `airPpm`) y dispositivo `ESP32-01`, actualmente simulado.

**Nota:** las alertas y los valores son demostrativos y no deben interpretarse como mediciones de seguridad ambiental ni concentraciones calibradas de CO₂.
