import 'dart:async';

import '../models/weather_data.dart';
import 'open_meteo_service.dart';

class DashboardData {
  const DashboardData({
    this.weather,
    this.isLoading = false,
    this.error,
  });

  final WeatherData? weather;
  final bool isLoading;
  final String? error;
}

class WeatherDashboardController {
  WeatherDashboardController(this._service);

  final OpenMeteoService _service;
  final _controller = StreamController<DashboardData>.broadcast();

  Timer? _refreshTimer;
  bool _disposed = false;
  DashboardData _current = const DashboardData();

  Stream<DashboardData> get stream => _controller.stream;
  DashboardData get current => _current;

  void start() {
    unawaited(refresh());
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => unawaited(refresh()),
    );
  }

  Future<void> refresh() async {
    if (_disposed || _current.isLoading) return;

    _current = DashboardData(
      weather: _current.weather,
      isLoading: true,
    );
    _emit();

    try {
      final weather = await _service.fetchWeather();
      if (_disposed) return;
      _current = DashboardData(weather: weather);
    } on Object catch (error) {
      if (_disposed) return;
      _current = DashboardData(
        weather: _current.weather,
        error: _friendlyError(error),
      );
    }

    _emit();
  }

  String _friendlyError(Object error) {
    if (error is TimeoutException) {
      return 'La consulta tardó demasiado. Comprueba tu conexión e inténtalo de nuevo.';
    }
    if (error is WeatherApiException) return error.message;
    return 'No fue posible consultar Open-Meteo. Comprueba tu conexión.';
  }

  void _emit() {
    if (!_disposed && !_controller.isClosed) {
      _controller.add(_current);
    }
  }

  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    _service.dispose();
    unawaited(_controller.close());
  }
}
