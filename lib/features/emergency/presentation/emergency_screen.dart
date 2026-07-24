import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api.dart';
import '../../../core/services/location_permission_service.dart';
import '../../../shared/providers/providers.dart';

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
  /// When set, the screen resumes tracking this existing call instead of
  /// creating a new one (used after a call is redirected to another service).
  final int? existingCallId;

  /// Whether this call was handed off to another service — changes the copy
  /// shown while a new responder is being found.
  final bool redirected;

  const EmergencyScreen({
    super.key,
    this.existingCallId,
    this.redirected = false,
  });

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
    if (widget.existingCallId != null) {
      _resumeExistingCall(widget.existingCallId!);
    } else {
      _createEmergencyCall();
    }
  }

  // Resume tracking an already-existing call (e.g. after it was redirected to
  // another service) without creating a new emergency call.
  void _resumeExistingCall(int callId) {
    setState(() {
      _callId = callId;
      _status = EmergencyStatus.searching;
      _isLoading = false;
    });
    _pollStatus();
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
    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final hasPermissions = await LocationPermissionService.checkAndRequestPermissions(context);
      if (!hasPermissions) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 3. Get position
      // Try fast path first (helps in cases where GPS "fix" takes time).
      // Берём максимально точную стартовую координату: свежий high-accuracy
      // фикс, а не потенциально устаревший кэш getLastKnownPosition.
      final position =
          await LocationPermissionService.getBestInitialPosition();

      final success = await ref.read(emergencyProvider.notifier).createCall(
        position.latitude,
        position.longitude,
        null, // address if available
      );

      if (success) {
        final activeCall = ref.read(emergencyProvider).activeCall;
        setState(() {
          _callId = activeCall?.id;
          _status = EmergencyStatus.searching;
          _isLoading = false;
        });

        _pollStatus();
      } else {
        setState(() {
          _error = ref.read(emergencyProvider).error ?? 'Не удалось создать вызов.';
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } on DioException catch (e) {
      // EmergencyScreen calls dio directly; convert Dio error -> ApiException
      // so we can show backend `detail`/`message` instead of raw DioException.
      final apiError = ApiException.fromDioError(e);
      setState(() {
        _error = kDebugMode
            ? '${apiError.message} (status: ${apiError.statusCode})'
            : apiError.message;
        _isLoading = false;
      });
    } on LocationServiceDisabledException catch (_) {
      setState(() {
        _error = 'Службы геолокации отключены. Включите GPS в настройках устройства.';
        _isLoading = false;
      });
    } on PermissionDeniedException catch (_) {
      setState(() {
        _error = 'Доступ к геолокации запрещён. Разрешите доступ для вызова охраны.';
        _isLoading = false;
      });
    } on TimeoutException catch (_) {
      setState(() {
        _error = 'Не удалось определить местоположение за отведенное время. Проверьте GPS и повторите.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // Keep the user-friendly message, but provide details in debug builds.
        _error = kDebugMode ? 'Не удалось определить местоположение: $e' : 'Не удалось определить местоположение. Проверьте настройки GPS.';
        _isLoading = false;
      });
    }
  }
  
  // Координаты во время вызова шлёт emergencyLocationProvider — он привязан к
  // состоянию вызова, а не к экрану, и переживает переход в чат с экипажем.

  void _pollStatus() {
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      await ref.read(emergencyProvider.notifier).getActiveCall();
      final callState = ref.read(emergencyProvider).activeCall;
      
      if (callState != null) {
        final newStatus = _parseStatus(callState.status);
        
        if (newStatus != _status) {
          setState(() => _status = newStatus);
        }
        
        if (newStatus == EmergencyStatus.accepted || 
            newStatus == EmergencyStatus.enRoute || 
            newStatus == EmergencyStatus.arrived) {
          // Could open chat popup or navigate to chat screen
          // We will let the user navigate to chat screen manually or automatically
          // for the sake of presentation we navigate:
          if (mounted) {
             timer.cancel();
             _timer?.cancel();
             context.push('/emergency/chat', extra: callState.id);
          }
        }

        if (newStatus == EmergencyStatus.completed) {
          timer.cancel();
          _timer?.cancel();
          if (mounted) context.go('/emergency/review', extra: callState.id);
        } else if (newStatus == EmergencyStatus.cancelledByUser ||
                   newStatus == EmergencyStatus.cancelledBySystem) {
          timer.cancel();
          _timer?.cancel();
          if (mounted) context.go('/home');
        }
      }
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
    
    final secretPhraseController = TextEditingController();
    bool obscure = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Отменить вызов?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Введите секретный код для подтверждения отмены вызова охраны.'),
              const SizedBox(height: 16),
              TextField(
                controller: secretPhraseController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Секретный код',
                  hintText: 'Ваше секретное слово',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
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
      ),
    );
    
    if (confirmed == true) {
      await ref.read(emergencyProvider.notifier).cancelCall(
        _callId!,
        null,
        secretPhrase: secretPhraseController.text.isNotEmpty
            ? secretPhraseController.text
            : null,
      );
      // Трекинг гасит сам провайдер: cancelCall обнуляет активный вызов.
      if (mounted) context.go('/home');
    }
  }
  
  String get _statusText {
    switch (_status) {
      case EmergencyStatus.created:
      case EmergencyStatus.searching:
        return widget.redirected ? 'Передаём другой службе...' : 'Поиск охраны...';
      case EmergencyStatus.offerSent:
        return widget.redirected ? 'Передаём другой службе...' : 'Ожидание ответа...';
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _createEmergencyCall,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Повторить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sosRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => Geolocator.openAppSettings(),
                      icon: const Icon(Icons.settings),
                      label: const Text('Настройки'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
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
                  widget.redirected
                      ? 'Ваш вызов передан другой службе.\nИщем ближайшего свободного сотрудника.'
                      : 'Ближайшие службы оповещены',
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
