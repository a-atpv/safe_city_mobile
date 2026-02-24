import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api.dart';

enum EmergencyStatus {
  created,
  searching,
  offerSent,
  accepted,
  enRoute,
  arrived,
  completed,
  cancelledByUser,
  cancelledBySystem,
}

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  Timer? _timer;
  Timer? _pollTimer;
  int _elapsedSeconds = 0;
  EmergencyStatus _status = EmergencyStatus.searching;
  int? _callId;
  String? _error;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _startTimer();
    _createEmergencyCall();
  }
  
  @override
  void dispose() {
    _radarController.dispose();
    _timer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
    });
  }
  
  String get _formattedTime {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  Future<void> _createEmergencyCall() async {
    try {
      final position = await _getCurrentLocation();
      if (position == null) {
        setState(() {
          _error = 'Не удалось определить местоположение';
          _isLoading = false;
        });
        return;
      }
      
      final response = await ApiClient().dio.post('/emergency/call', data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      
      if (response.statusCode == 200) {
        setState(() {
          _callId = response.data['id'];
          _status = EmergencyStatus.searching;
          _isLoading = false;
        });
        
        _pollStatus();
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка создания вызова';
        _isLoading = false;
      });
    }
  }
  
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      
      if (permission == LocationPermission.deniedForever) return null;
      
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }
  
  void _pollStatus() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_callId == null) {
        timer.cancel();
        return;
      }
      
      try {
        final response = await ApiClient().dio.get('/emergency/call/$_callId');
        if (response.statusCode == 200) {
          final statusStr = response.data['status'] as String;
          final newStatus = _parseStatus(statusStr);
          
          if (newStatus != _status) {
            setState(() => _status = newStatus);
          }
          
          if (newStatus == EmergencyStatus.completed ||
              newStatus == EmergencyStatus.cancelledByUser ||
              newStatus == EmergencyStatus.cancelledBySystem) {
            timer.cancel();
            _timer?.cancel();
          }
        }
      } catch (_) {}
    });
  }
  
  EmergencyStatus _parseStatus(String status) {
    switch (status) {
      case 'created': return EmergencyStatus.created;
      case 'searching': return EmergencyStatus.searching;
      case 'offer_sent': return EmergencyStatus.offerSent;
      case 'accepted': return EmergencyStatus.accepted;
      case 'en_route': return EmergencyStatus.enRoute;
      case 'arrived': return EmergencyStatus.arrived;
      case 'completed': return EmergencyStatus.completed;
      case 'cancelled_by_user': return EmergencyStatus.cancelledByUser;
      case 'cancelled_by_system': return EmergencyStatus.cancelledBySystem;
      default: return EmergencyStatus.searching;
    }
  }
  
  Future<void> _cancelCall() async {
    if (_callId == null) {
      context.go('/home');
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Отменить вызов?'),
        content: const Text('Вы уверены, что хотите отменить вызов охраны?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Нет'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await ApiClient().dio.post('/emergency/call/$_callId/cancel');
      } catch (_) {}
      if (mounted) context.go('/home');
    }
  }
  
  String get _statusText {
    switch (_status) {
      case EmergencyStatus.created:
      case EmergencyStatus.searching:
        return 'Поиск охраны...';
      case EmergencyStatus.offerSent:
        return 'Ожидание ответа...';
      case EmergencyStatus.accepted:
        return 'Вызов принят';
      case EmergencyStatus.enRoute:
        return 'Охрана в пути';
      case EmergencyStatus.arrived:
        return 'Охрана прибыла';
      case EmergencyStatus.completed:
        return 'Вызов завершён';
      case EmergencyStatus.cancelledByUser:
        return 'Отменён';
      case EmergencyStatus.cancelledBySystem:
        return 'Отменён системой';
    }
  }
  
  Color get _statusColor {
    switch (_status) {
      case EmergencyStatus.created:
      case EmergencyStatus.searching:
      case EmergencyStatus.offerSent:
        return AppColors.sosRed;
      case EmergencyStatus.accepted:
      case EmergencyStatus.enRoute:
        return AppColors.warning;
      case EmergencyStatus.arrived:
      case EmergencyStatus.completed:
        return AppColors.success;
      case EmergencyStatus.cancelledByUser:
      case EmergencyStatus.cancelledBySystem:
        return AppColors.textSecondary;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(51),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Вызов активен',
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              if (_isLoading || _status == EmergencyStatus.searching)
                _buildRadar(),
              
              if (_error != null) ...[
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              
              if (!_isLoading && _error == null) ...[
                Text(
                  _statusText,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  _formattedTime,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: _statusColor,
                  ),
                ),
              ],
              
              const Spacer(),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Ближайшие службы оповещены',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 40),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _cancelCall,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Отменить вызов',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRadar() {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, _) {
        return SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ...List.generate(4, (index) {
                final size = 60.0 + (index * 50);
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.sosRed.withAlpha(76),
                      width: 1,
                    ),
                  ),
                );
              }),
              
              Transform.rotate(
                angle: _radarController.value * 2 * 3.14159,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.sosRed.withAlpha(127),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25, 0.5],
                    ),
                  ),
                ),
              ),
              
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.sosRed,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
