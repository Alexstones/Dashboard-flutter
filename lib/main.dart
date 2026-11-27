import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'models/weather_data.dart';
import 'services/open_meteo_service.dart';
import 'services/weather_dashboard_controller.dart';

void main() => runApp(const SmartEnvironmentApp());

const _bg = Color(0xFF0B1220);
const _panel = Color(0xFF151F32);
const _temp = Color(0xFFFFB454);
const _humidity = Color(0xFF4DD5E8);
const _muted = Color(0xFF96A6BD);
const _green = Color(0xFF54E3A0);
const _purple = Color(0xFFB7A6FF);

class SmartEnvironmentApp extends StatelessWidget {
  const SmartEnvironmentApp({super.key, this.weatherService});

  final OpenMeteoService? weatherService;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Environment IoT',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _bg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _humidity,
            brightness: Brightness.dark,
          ),
        ),
        home: DashboardScreen(weatherService: weatherService),
      );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.weatherService});

  final OpenMeteoService? weatherService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final WeatherDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WeatherDashboardController(
      widget.weatherService ?? OpenMeteoService(),
    )..start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: _bg,
          title: const Row(
            children: [
              Icon(Icons.sensors, color: _humidity),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Smart-Environment IoT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        body: StreamBuilder<DashboardData>(
          stream: _controller.stream,
          initialData: _controller.current,
          builder: (context, snapshot) {
            final data = snapshot.data ?? _controller.current;
            final weather = data.weather;

            if (weather == null) {
              return _emptyState(data);
            }

            final history = weather.hourly.isNotEmpty
                ? weather.hourly
                : [
                    WeatherSample(
                      time: weather.time,
                      temperatureC: weather.temperatureC,
                      relativeHumidity: weather.relativeHumidity,
                      windSpeedKmh: weather.windSpeedKmh,
                      precipitationMm: weather.precipitationMm,
                    ),
                  ];

            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 740;
                final veryWide = constraints.maxWidth >= 1050;
                final columns = veryWide ? 3 : 2;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _statusChip(data),
                        const Chip(
                          avatar: Icon(Icons.cloud_outlined, size: 17),
                          label: Text('OPEN-METEO · API REAL'),
                        ),
                        Chip(
                          label: Text(
                            '${weather.hourly.length} horas de pronóstico',
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: data.isLoading
                              ? null
                              : _controller.refresh,
                          icon: data.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(
                            data.isLoading ? 'Actualizando' : 'Actualizar',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Monitoreo ambiental',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Datos meteorológicos de Chihuahua, México · '
                      'Consulta: ${_formatDateTime(weather.fetchedAt)}',
                      style: const TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 18),
                    GridView.count(
                      crossAxisCount: columns,
                      childAspectRatio: wide ? 2.0 : 1.32,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: [
                        MetricCard(
                          icon: Icons.thermostat,
                          label: 'Temperatura',
                          value: weather.temperatureC.toStringAsFixed(1),
                          unit: '°C',
                          color: _temp,
                        ),
                        MetricCard(
                          icon: Icons.water_drop_outlined,
                          label: 'Humedad relativa',
                          value: weather.relativeHumidity.toStringAsFixed(0),
                          unit: '%',
                          color: _humidity,
                        ),
                        MetricCard(
                          icon: Icons.air,
                          label: 'Velocidad del viento',
                          value: weather.windSpeedKmh.toStringAsFixed(1),
                          unit: 'km/h',
                          color: _purple,
                        ),
                        MetricCard(
                          icon: Icons.thermostat_auto,
                          label: 'Sensación térmica',
                          value: weather.apparentTemperatureC
                              .toStringAsFixed(1),
                          unit: '°C',
                          color: const Color(0xFFFF8F9C),
                        ),
                        MetricCard(
                          icon: Icons.grain,
                          label: 'Precipitación',
                          value: weather.precipitationMm.toStringAsFixed(1),
                          unit: 'mm',
                          color: const Color(0xFF83B7FF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _weatherSummary(weather),
                    if (data.error != null) ...[
                      const SizedBox(height: 12),
                      _errorBanner(data.error!),
                    ],
                    const SizedBox(height: 16),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: HistoryChart(
                              title: 'Pronóstico de temperatura',
                              unit: '°C',
                              color: _temp,
                              readings: history,
                              accessor: (reading) => reading.temperatureC,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: HistoryChart(
                              title: 'Pronóstico de humedad',
                              unit: '%',
                              color: _humidity,
                              readings: history,
                              accessor: (reading) =>
                                  reading.relativeHumidity,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      HistoryChart(
                        title: 'Pronóstico de temperatura',
                        unit: '°C',
                        color: _temp,
                        readings: history,
                        accessor: (reading) => reading.temperatureC,
                      ),
                      const SizedBox(height: 14),
                      HistoryChart(
                        title: 'Pronóstico de humedad',
                        unit: '%',
                        color: _humidity,
                        readings: history,
                        accessor: (reading) => reading.relativeHumidity,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _sourceCard(weather),
                  ],
                );
              },
            );
          },
        ),
      );

  Widget _emptyState(DashboardData data) {
    final hasError = data.error != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasError ? Icons.cloud_off : Icons.cloud_outlined,
                size: 54,
                color: hasError ? _temp : _humidity,
              ),
              const SizedBox(height: 16),
              Text(
                hasError ? 'No se pudieron cargar los datos' : 'Conectando con Open-Meteo',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.error ??
                    'Estamos consultando las condiciones meteorológicas de Chihuahua.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 20),
              if (data.isLoading)
                const CircularProgressIndicator()
              else
                FilledButton.icon(
                  onPressed: _controller.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(DashboardData data) {
    final String label;
    final Color color;

    if (data.isLoading && data.weather == null) {
      label = 'CONECTANDO';
      color = _humidity;
    } else if (data.isLoading) {
      label = 'ACTUALIZANDO';
      color = _temp;
    } else if (data.error != null) {
      label = data.weather == null ? 'SIN CONEXIÓN' : 'DATOS ANTERIORES';
      color = _temp;
    } else {
      label = 'CONECTADO';
      color = _green;
    }

    return Chip(
      avatar: Icon(Icons.circle, size: 12, color: color),
      label: Text(label),
    );
  }

  Widget _weatherSummary(WeatherData weather) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF163A35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_outlined, color: _green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_weatherDescription(weather.weatherCode)} · '
              'Viento con dirección de ${weather.windDirectionDegrees.toStringAsFixed(0)}°.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF4B2C26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _temp),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No se pudo actualizar. Se conservan los últimos datos recibidos. $message',
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceCard(WeatherData weather) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fuente de datos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open-Meteo · API meteorológica REST · Chihuahua, México',
            style: TextStyle(color: _muted),
          ),
          const SizedBox(height: 4),
          Text(
            'Coordenadas: ${OpenMeteoService.defaultLatitude}, '
            '${OpenMeteoService.defaultLongitude} · Zona horaria: ${weather.timezone}',
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 4),
          const Text(
            'Actualización automática cada 15 minutos. '
            'Estos datos son meteorológicos y no sustituyen mediciones de sensores físicos ni de calidad del aire.',
            style: TextStyle(color: _muted),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 27),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(fontSize: 14, color: _muted),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        ),
      );
}

class HistoryChart extends StatelessWidget {
  const HistoryChart({
    super.key,
    required this.title,
    required this.unit,
    required this.color,
    required this.readings,
    required this.accessor,
  });

  final String title;
  final String unit;
  final Color color;
  final List<WeatherSample> readings;
  final double Function(WeatherSample) accessor;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var index = 0; index < readings.length; index++)
        FlSpot(index.toDouble(), accessor(readings[index])),
    ];

    final values = readings.map(accessor).toList();
    final lowest = values.reduce((a, b) => a < b ? a : b);
    final highest = values.reduce((a, b) => a > b ? a : b);
    final spread = highest - lowest;
    final padding = spread == 0 ? 1.0 : spread * 0.15;
    final chartMin = lowest - padding;
    final chartMax = highest + padding;
    final chartInterval = (chartMax - chartMin) / 4;
    final xInterval = max(1, (readings.length / 5).floor()).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 16, 16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${readings.length} puntos',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 230,
            child: LineChart(
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeOutCubic,
              LineChartData(
                minX: 0,
                maxX: max(1, readings.length - 1).toDouble(),
                minY: chartMin,
                maxY: chartMax,
                clipData: const FlClipData.all(),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (items) => items.map((item) {
                      final index = item.x
                          .round()
                          .clamp(0, readings.length - 1)
                          .toInt();
                      final time = _formatHour(readings[index].time);
                      return LineTooltipItem(
                        '$time\n${item.y.toStringAsFixed(1)} $unit',
                        TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartInterval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: chartInterval,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= readings.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _formatHour(readings[index].time),
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.22,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pronóstico horario · Toca la línea para consultar los valores.',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year} ${_formatHour(value)}';
}

String _formatHour(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

String _weatherDescription(int code) {
  if (code == 0) return 'Cielo despejado';
  if (code == 1) return 'Principalmente despejado';
  if (code == 2) return 'Parcialmente nublado';
  if (code == 3) return 'Cielo cubierto';
  if (code == 45 || code == 48) return 'Niebla';
  if ([51, 53, 55].contains(code)) return 'Llovizna';
  if ([56, 57].contains(code)) return 'Llovizna helada';
  if ([61, 63, 65].contains(code)) return 'Lluvia';
  if ([66, 67].contains(code)) return 'Lluvia helada';
  if ([71, 73, 75, 77].contains(code)) return 'Nieve';
  if ([80, 81, 82].contains(code)) return 'Chubascos';
  if ([85, 86].contains(code)) return 'Chubascos de nieve';
  if (code == 95) return 'Tormenta';
  if ([96, 99].contains(code)) return 'Tormenta con granizo';
  return 'Condición meteorológica no especificada';
}
