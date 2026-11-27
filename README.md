# Smart-Environment IoT — Dashboard Flutter

Dashboard Flutter para visualizar información meteorológica real de Chihuahua, México, mediante la API REST de **Open-Meteo**.

## Funcionalidades

- Consulta HTTP GET a `https://api.open-meteo.com/v1/forecast`.
- Temperatura, humedad relativa, sensación térmica, velocidad y dirección del viento, precipitación y código meteorológico.
- Pronóstico horario para las próximas 24 horas.
- Gráficas de temperatura y humedad alimentadas con la respuesta horaria de la API.
- Actualización manual y automática cada 15 minutos.
- Estados de conexión, carga y error.
- Conservación de la última respuesta correcta cuando falla una actualización.
- Pruebas unitarias del modelo y del servicio con respuestas HTTP simuladas.
- Interfaz adaptable a escritorio y móvil.

## Ubicación inicial

- Ciudad: Chihuahua, México.
- Latitud: `28.6353`.
- Longitud: `-106.0889`.
- Zona horaria: `auto`.

La ubicación se puede cambiar en `lib/services/open_meteo_service.dart`, modificando los valores predeterminados de `latitude` y `longitude` al crear `OpenMeteoService`.

## Variables consultadas

**Datos actuales (`current`):**

- `temperature_2m`
- `relative_humidity_2m`
- `apparent_temperature`
- `precipitation`
- `wind_speed_10m`
- `wind_direction_10m`
- `weather_code`

**Pronóstico horario (`hourly`):**

- `temperature_2m`
- `relative_humidity_2m`
- `wind_speed_10m`
- `precipitation`

La consulta utiliza grados Celsius, kilómetros por hora, milímetros y la zona horaria automática. No requiere API Key.

## Arquitectura

```text
lib/
├── main.dart
├── models/
│   └── weather_data.dart
└── services/
    ├── open_meteo_service.dart
    └── weather_dashboard_controller.dart

test/
├── widget_test.dart
├── weather_data_test.dart
└── open_meteo_service_test.dart
```

- `WeatherData`: interpreta y valida la respuesta JSON.
- `OpenMeteoService`: construye la solicitud HTTP, consulta Open-Meteo y gestiona respuestas inválidas.
- `WeatherDashboardController`: administra el estado, el `StreamController`, la actualización manual y el temporizador de 15 minutos.
- `DashboardScreen`: presenta las métricas y las gráficas mediante `StreamBuilder` y `fl_chart`.

## Instalación y ejecución en Windows

Abre PowerShell en la carpeta del proyecto y ejecuta:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Para compilar la versión web:

```powershell
flutter build web
```

Para comprobar los dispositivos disponibles:

```powershell
flutter devices
```

La aplicación Android necesita permiso de Internet, ya incluido en `android/app/src/main/AndroidManifest.xml`.

## Pruebas

Las pruebas cubren:

- Interpretación de valores actuales y horarios.
- Validación de campos obligatorios.
- Solicitud GET y parámetros de ubicación.
- Respuestas HTTP no exitosas.
- Respuestas JSON inválidas.
- Presentación de las métricas en la interfaz.

## Alcance y limitaciones de los datos

Open-Meteo proporciona datos meteorológicos y pronósticos para las coordenadas solicitadas. **No proporciona mediciones de CO₂, calidad del aire ni lecturas de un ESP32** mediante este endpoint. Por ese motivo, el Dashboard ya no presenta una tarjeta `airPpm` como si fuera una medición real; ahora muestra precipitación.

Los datos de la API no deben confundirse con mediciones físicas tomadas dentro de un edificio. Para monitoreo real de CO₂, partículas u otros contaminantes se necesitará un sensor adecuado y una fuente de datos independiente.

## Fuente

- Open-Meteo: <https://open-meteo.com/en/docs>
- Endpoint: <https://api.open-meteo.com/v1/forecast>
