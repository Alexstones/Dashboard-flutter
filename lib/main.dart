import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

void main() => runApp(const SmartEnvironmentApp());

const _bg = Color(0xFF0B1220);
const _panel = Color(0xFF151F32);
const _temp = Color(0xFFFFB454);
const _humidity = Color(0xFF4DD5E8);
const _muted = Color(0xFF96A6BD);

class SensorReading {
  const SensorReading({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.airPpm,
  });
  final DateTime time;
  final double temperature;
  final double humidity;
  final int airPpm;

  bool get isAlert => temperature > 30 || humidity > 75 || airPpm > 1000;
}

class DashboardData {
  const DashboardData(this.history, this.running);
  final List<SensorReading> history;
  final bool running;
  SensorReading get latest => history.last;
}

/// Servicio intercambiable por WebSocket, MQTT o API del proyecto integrador.
/// Los datos de esta versión son SIMULADOS, no mediciones físicas.
class SimulatedSensorService {
  final _controller = StreamController<DashboardData>.broadcast();
  final _random = Random();
  final _history = <SensorReading>[];
  Timer? _timer;
  bool _running = true;
  int _tick = 0;

  Stream<DashboardData> get stream => _controller.stream;
  DashboardData get current => DashboardData(List.unmodifiable(_history), _running);

  void start() {
    for (var i = 0; i < 20; i++) {
      _sample();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running) return;
      _sample();
      _emit();
    });
  }

  void toggle() {
    _running = !_running;
    _emit();
  }

  void _sample() {
    final t = _tick.toDouble();
    final temperature = 25 + 3.0 * sin(t / 8) + _random.nextDouble() * 0.6;
    final humidity = 56 + 12 * sin(t / 12 + 1) + _random.nextDouble() * 1.8;
    final air = (650 + 180 * sin(t / 11 + 2) + _random.nextInt(40)).round();
    _history.add(SensorReading(
      time: DateTime.now().subtract(Duration(seconds: 19 - _tick.clamp(0, 19))),
      temperature: temperature,
      humidity: humidity,
      airPpm: air,
    ));
    if (_history.length > 30) _history.removeAt(0);
    _tick++;
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(current);
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

class SmartEnvironmentApp extends StatelessWidget {
  const SmartEnvironmentApp({super.key});

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
        home: const DashboardScreen(),
      );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final SimulatedSensorService _service;

  @override
  void initState() {
    super.initState();
    _service = SimulatedSensorService()..start();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: _bg,
          title: const Row(children: [
            Icon(Icons.sensors, color: _humidity),
            SizedBox(width: 10),
            Expanded(child: Text('Smart-Environment IoT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ]),
        ),
        body: StreamBuilder<DashboardData>(
          stream: _service.stream,
          initialData: _service.current,
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data == null || data.history.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final latest = data.latest;
            return LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 740;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _statusChip(data.running),
                      const Chip(label: Text('DEMO · Datos simulados')),
                      Chip(label: Text('Muestras: ${data.history.length}')),
                      FilledButton.icon(
                        onPressed: _service.toggle,
                        icon: Icon(data.running ? Icons.pause : Icons.play_arrow),
                        label: Text(data.running ? 'Pausar' : 'Reanudar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Monitoreo ambiental', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  const Text('Mediciones en vivo · Actualización automática cada 1 segundo', style: TextStyle(color: _muted)),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: wide ? 3 : 2,
                    childAspectRatio: wide ? 2.0 : 1.23,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      MetricCard(icon: Icons.thermostat, label: 'Temperatura', value: latest.temperature.toStringAsFixed(1), unit: '°C', color: _temp),
                      MetricCard(icon: Icons.water_drop_outlined, label: 'Humedad', value: latest.humidity.toStringAsFixed(1), unit: '%', color: _humidity),
                      MetricCard(icon: Icons.air, label: 'Calidad de aire', value: '${latest.airPpm}', unit: 'ppm', color: const Color(0xFFB7A6FF)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _notice(latest),
                  const SizedBox(height: 16),
                  if (wide)
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: HistoryChart(title: 'Temperatura', unit: '°C', color: _temp, readings: data.history, accessor: (r) => r.temperature, minY: 15, maxY: 35)),
                      const SizedBox(width: 14),
                      Expanded(child: HistoryChart(title: 'Humedad relativa', unit: '%', color: _humidity, readings: data.history, accessor: (r) => r.humidity, minY: 20, maxY: 90)),
                    ])
                  else ...[
                    HistoryChart(title: 'Temperatura', unit: '°C', color: _temp, readings: data.history, accessor: (r) => r.temperature, minY: 15, maxY: 35),
                    const SizedBox(height: 14),
                    HistoryChart(title: 'Humedad relativa', unit: '%', color: _humidity, readings: data.history, accessor: (r) => r.humidity, minY: 20, maxY: 90),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)),
                    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Proyecto integrador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      SizedBox(height: 8),
                      Text('Smart-Environment IoT · Dispositivo: ESP32-01 · Fuente actual: simulador', style: TextStyle(color: _muted)),
                      SizedBox(height: 4),
                      Text('Preparado para recibir temperature, humidity y airPpm de un sensor real.', style: TextStyle(color: _muted)),
                    ]),
                  ),
                ],
              );
            });
          },
        ),
      );

  Widget _statusChip(bool running) => Chip(
        avatar: Icon(Icons.circle, size: 13, color: running ? const Color(0xFF54E3A0) : _temp),
        label: Text(running ? 'STREAM ACTIVO' : 'EN PAUSA'),
      );

  Widget _notice(SensorReading reading) {
    final alert = reading.isAlert;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert ? const Color(0xFF4B2C26) : const Color(0xFF163A35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(alert ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: alert ? _temp : const Color(0xFF54E3A0)),
        const SizedBox(width: 10),
        Expanded(child: Text(alert
            ? 'Alerta: una variable ambiental superó el umbral de demostración.'
            : 'Ambiente estable · Variables dentro de los rangos de demostración.')),
      ]),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.icon, required this.label, required this.value, required this.unit, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: color, size: 27),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: RichText(text: TextSpan(children: [
            TextSpan(text: value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            TextSpan(text: ' $unit', style: const TextStyle(fontSize: 14, color: _muted)),
          ]))),
          Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
        ]),
      );
}

class HistoryChart extends StatelessWidget {
  const HistoryChart({super.key, required this.title, required this.unit, required this.color, required this.readings, required this.accessor, required this.minY, required this.maxY});
  final String title;
  final String unit;
  final Color color;
  final List<SensorReading> readings;
  final double Function(SensorReading) accessor;
  final double minY;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    final spots = [for (var i = 0; i < readings.length; i++) FlSpot(i.toDouble(), accessor(readings[i]))];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 16, 16),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
          Text('Últimas ${readings.length} muestras', style: const TextStyle(fontSize: 11, color: _muted)),
        ]),
        const SizedBox(height: 20),
        SizedBox(height: 230, child: LineChart(
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
          LineChartData(
            minX: 0,
            maxX: max(1, readings.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            clipData: const FlClipData.all(),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (items) => items.map((item) => LineTooltipItem('${item.y.toStringAsFixed(1)} $unit', TextStyle(color: color, fontWeight: FontWeight.bold))).toList(),
              ),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (maxY - minY) / 4, getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.08), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: (maxY - minY) / 4, getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(color: _muted, fontSize: 11)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 5, getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= readings.length || index % 5 != 0) return const SizedBox.shrink();
                final time = readings[index].time;
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text('${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}', style: const TextStyle(color: _muted, fontSize: 10)));
              })),
            ),
            lineBarsData: [LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.22,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.13)),
            )],
          ),
        )),
        const SizedBox(height: 8),
        Text('Eje X: tiempo (mm:ss) · Eje Y: $unit · Toca la línea para consultar valores.', style: const TextStyle(color: _muted, fontSize: 11)),
      ]),
    );
  }
}
