import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../models/health_status.dart';
import '../../services/air_quality_service.dart';
import '../../services/ai_advisor_service.dart';

class MapScreen extends StatefulWidget {
  final Map<String, HealthIndicatorData> healthIndicators;

  const MapScreen({Key? key, required this.healthIndicators}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Position? _position;
  AirQualityData? _airQuality;

  @override
  void initState() {
    super.initState();
    _initLocationAndAirQuality();
  }

  Future<void> _initLocationAndAirQuality() async {
    try {
      debugPrint('🗺️ Début initialisation localisation et qualité air');
      
      // Étape 1: Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('🗺️ Service localisation activé: $serviceEnabled');
      
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Le service de localisation est désactivé. Activez-le dans les paramètres.';
          _isLoading = false;
        });
        return;
      }

      // Étape 2: Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('🗺️ Permission actuelle: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('🗺️ Permission refusée, demande...');
        permission = await Geolocator.requestPermission();
        debugPrint('🗺️ Permission après demande: $permission');
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'La permission de localisation est refusée. Autorisez-la dans les paramètres.';
          _isLoading = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'La permission de localisation est refusée définitivement. Activez-la dans les paramètres système.';
          _isLoading = false;
        });
        return;
      }

      // Étape 3: Obtenir la position
      debugPrint('🗺️ Récupération de la position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      debugPrint('🗺️ Position obtenue: Lat=${position.latitude}, Lng=${position.longitude}');

      // Étape 4: Appeler l'API qualité de l'air
      debugPrint('🗺️ Appel API qualité de l\'air...');
      final airQuality = await AirQualityService.fetchAirQuality(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      debugPrint('🗺️ Qualité air: ${airQuality?.aqiIndex ?? 'null'}');

      setState(() {
        _position = position;
        _airQuality = airQuality;
        _isLoading = false;
        _errorMessage = airQuality == null ? 'Impossible de récupérer les données de qualité de l\'air.' : null;
      });
    } catch (e) {
      debugPrint('🗺️ ERREUR: $e');
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _aqiDescription(int aqi) {
    switch (aqi) {
      case 1:
        return 'Bonne';
      case 2:
        return 'Correcte';
      case 3:
        return 'Modérée';
      case 4:
        return 'Mauvaise';
      case 5:
        return 'Très mauvaise';
      default:
        return 'Inconnue';
    }
  }

  Color _aqiColor(int aqi) {
    switch (aqi) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.redAccent;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHealthIndicator(String title, HealthIndicatorData data) {
    final indicatorColor = data.color;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: indicatorColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${data.value}${data.unit.isNotEmpty ? ' ${data.unit}' : ''}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: indicatorColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: indicatorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsRow() {
    final indicators = widget.healthIndicators;
    final items = <Widget>[];

    final spo2 = indicators['spo2'];
    if (spo2 != null) {
      items.add(_buildHealthIndicator('SpO2', spo2));
    }

    final iqa = indicators['iqa'];
    if (iqa != null) {
      items.add(_buildHealthIndicator('IQA', iqa));
    }

    final bpm = indicators['bpm'] ?? indicators['heart_rate'];
    if (bpm != null) {
      items.add(_buildHealthIndicator('BPM', bpm));
    }

    final bp = indicators['blood_pressure'];
    if (bp != null) {
      items.add(_buildHealthIndicator('Pression', bp));
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(children: items),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Erreur inconnue',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initLocationAndAirQuality();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_position == null) {
      return const Center(child: Text('Position utilisateur indisponible.'));
    }

    final userLatLng = latlng.LatLng(
      _position!.latitude,
      _position!.longitude,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _buildIndicatorsRow(),
        const SizedBox(height: 12),
        if (_airQuality != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Qualité de l\'air autour de vous',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Indice AQI: ${_airQuality!.aqiIndex} - ${_aqiDescription(_airQuality!.aqiIndex)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: _aqiColor(_airQuality!.aqiIndex),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {
                            _updateAIAdviceWithAirQuality();
                          },
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: 'Mettre à jour les conseils IA avec qualité air',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildPollutantsDetails(),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: userLatLng,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'asthmatic_app',
                ),
                if (_airQuality != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: userLatLng,
                        radius: 1000, // Rayon de 1km autour de la position
                        color: _airQuality!.aqiIndex <= 2 
                            ? Colors.green.withValues(alpha: 0.3)
                            : _airQuality!.aqiIndex <= 3 
                                ? Colors.orange.withValues(alpha: 0.3)
                                : Colors.red.withValues(alpha: 0.3),
                        borderColor: _airQuality!.aqiIndex <= 2 
                            ? Colors.green
                            : _airQuality!.aqiIndex <= 3 
                                ? Colors.orange
                                : Colors.red,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLatLng,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPollutantsDetails() {
    if (_airQuality == null) return const SizedBox.shrink();
    
    final components = _airQuality!.components;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Composants polluants (μg/m³):',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildPollutantChip('CO', components['co']?.toDouble()),
            _buildPollutantChip('NO', components['no']?.toDouble()),
            _buildPollutantChip('NO₂', components['no2']?.toDouble()),
            _buildPollutantChip('O₃', components['o3']?.toDouble()),
            _buildPollutantChip('SO₂', components['so2']?.toDouble()),
            _buildPollutantChip('PM2.5', components['pm2_5']?.toDouble()),
            _buildPollutantChip('PM10', components['pm10']?.toDouble()),
            _buildPollutantChip('NH₃', components['nh3']?.toDouble()),
          ],
        ),
      ],
    );
  }

  Widget _buildPollutantChip(String label, double? value) {
    if (value == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }

  void _updateAIAdviceWithAirQuality() async {
    if (_airQuality == null) return;
    
    try {
      // Créer des indicateurs de santé simulés pour la qualité de l'air uniquement
      final airQualityIndicators = <String, HealthIndicatorData>{
        'co': HealthIndicatorData(
          value: _airQuality!.components['co']?.toString() ?? '0',
          status: _getPollutantStatus(_airQuality!.components['co']?.toDouble() ?? 0, 'co'),
          label: 'CO',
          unit: 'μg/m³',
          timestamp: DateTime.now(),
        ),
        'no2': HealthIndicatorData(
          value: _airQuality!.components['no2']?.toString() ?? '0',
          status: _getPollutantStatus(_airQuality!.components['no2']?.toDouble() ?? 0, 'no2'),
          label: 'NO₂',
          unit: 'μg/m³',
          timestamp: DateTime.now(),
        ),
        'o3': HealthIndicatorData(
          value: _airQuality!.components['o3']?.toString() ?? '0',
          status: _getPollutantStatus(_airQuality!.components['o3']?.toDouble() ?? 0, 'o3'),
          label: 'O₃',
          unit: 'μg/m³',
          timestamp: DateTime.now(),
        ),
        'pm2_5': HealthIndicatorData(
          value: _airQuality!.components['pm2_5']?.toString() ?? '0',
          status: _getPollutantStatus(_airQuality!.components['pm2_5']?.toDouble() ?? 0, 'pm2_5'),
          label: 'PM2.5',
          unit: 'μg/m³',
          timestamp: DateTime.now(),
        ),
      };
      
      // Appeler l'IA avec SEULEMENT les données de qualité de l'air environnementale
      final advice = await AIAdvisorService.getEnvironmentalAdvice(
        airQualityIndicators: airQualityIndicators,
        aqiIndex: _airQuality!.aqiIndex,
        userName: 'Utilisateur',
      );
      
      debugPrint('🤖 Conseils IA environnementaux: ${advice.substring(0, advice.length > 50 ? 50 : advice.length)}...');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conseils environnementaux mis à jour'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('🤖 Erreur mise à jour conseils environnementaux: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour des conseils'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  HealthStatus _getPollutantStatus(double value, String pollutant) {
    switch (pollutant.toLowerCase()) {
      case 'co':
        if (value > 10) return HealthStatus.danger;
        if (value > 5) return HealthStatus.warning;
        return HealthStatus.good;
      case 'no2':
        if (value > 40) return HealthStatus.danger;
        if (value > 20) return HealthStatus.warning;
        return HealthStatus.good;
      case 'o3':
        if (value > 60) return HealthStatus.danger;
        if (value > 30) return HealthStatus.warning;
        return HealthStatus.good;
      case 'pm2_5':
        if (value > 15) return HealthStatus.danger;
        if (value > 8) return HealthStatus.warning;
        return HealthStatus.good;
      default:
        return HealthStatus.good;
    }
  }
}
