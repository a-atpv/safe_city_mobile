import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/emergency_call.dart';
import '../../../shared/providers/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _searchTimer;
  Timer? _statusPollTimer;
  StreamSubscription<Position>? _locationSubscription;
  bool _isPressed = false;
  bool _isSearchingEmergency = false;
  bool _isLoading = false;
  int _elapsedSeconds = 0;
  int? _callId;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Fetch user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).fetchUser();
    });
  }
  
  @override
  void dispose() {
    _searchTimer?.cancel();
    _statusPollTimer?.cancel();
    _locationSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
  
  void _onSosPressed() {
    final user = ref.read(userProvider).user;
    
    if (user == null || !user.hasActiveSubscription) {
      _showSubscriptionDialog();
      return;
    }

    _createEmergencyCall();
  }

  void _startSearchTimer() {
    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isSearchingEmergency) return;
      setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _cancelEmergencySearch() async {
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

    if (confirmed != true) return;

    _searchTimer?.cancel();
    _statusPollTimer?.cancel();
    _locationSubscription?.cancel();
    if (_callId != null) {
      await ref.read(emergencyProvider.notifier).cancelCall(_callId!, null);
    }
    setState(() {
      _isSearchingEmergency = false;
      _isPressed = false;
      _elapsedSeconds = 0;
      _callId = null;
      _isLoading = false;
    });
  }

  void _startStatusPolling() {
    _statusPollTimer?.cancel();
    ref.read(emergencyProvider.notifier).getActiveCall();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_isSearchingEmergency) return;
      ref.read(emergencyProvider.notifier).getActiveCall();
    });
  }

  Future<void> _createEmergencyCall() async {
    setState(() {
      _error = null;
      _isLoading = true;
      _isSearchingEmergency = true;
      _elapsedSeconds = 0;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error =
              'Службы геолокации отключены. Включите GPS в настройках устройства.';
          _isLoading = false;
          _isSearchingEmergency = false;
        });
        _showEmergencyError(_error!);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error =
                'Доступ к геолокации запрещён. Разрешите доступ для вызова охраны.';
            _isLoading = false;
            _isSearchingEmergency = false;
          });
          _showEmergencyError(_error!);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error =
              'Доступ к геолокации запрещён навсегда. Откройте настройки приложения и разрешите доступ к геолокации.';
          _isLoading = false;
          _isSearchingEmergency = false;
        });
        _showEmergencyError(_error!);
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );

      final success = await ref.read(emergencyProvider.notifier).createCall(
            position.latitude,
            position.longitude,
            null,
          );

      if (success) {
        final activeCall = ref.read(emergencyProvider).activeCall;
        setState(() {
          _callId = activeCall?.id;
          _isLoading = false;
        });
        _startSearchTimer();
        _startStatusPolling();
        _startLocationUpdates();
      } else {
        setState(() {
          _error =
              ref.read(emergencyProvider).error ?? 'Не удалось создать вызов.';
          _isLoading = false;
          _isSearchingEmergency = false;
        });
        _showEmergencyError(_error!);
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
        _isSearchingEmergency = false;
      });
      _showEmergencyError(_error!);
    } on DioException catch (e) {
      final apiError = ApiException.fromDioError(e);
      setState(() {
        _error = kDebugMode
            ? '${apiError.message} (status: ${apiError.statusCode})'
            : apiError.message;
        _isLoading = false;
        _isSearchingEmergency = false;
      });
      _showEmergencyError(_error!);
    } on LocationServiceDisabledException catch (_) {
      setState(() {
        _error =
            'Службы геолокации отключены. Включите GPS в настройках устройства.';
        _isLoading = false;
        _isSearchingEmergency = false;
      });
      _showEmergencyError(_error!);
    } on PermissionDeniedException catch (_) {
      setState(() {
        _error =
            'Доступ к геолокации запрещён. Разрешите доступ для вызова охраны.';
        _isLoading = false;
        _isSearchingEmergency = false;
      });
      _showEmergencyError(_error!);
    } on TimeoutException catch (_) {
      setState(() {
        _error =
            'Не удалось определить местоположение за отведенное время. Проверьте GPS и повторите.';
        _isLoading = false;
        _isSearchingEmergency = false;
      });
      _showEmergencyError(_error!);
    } catch (e) {
      setState(() {
        _error = kDebugMode
            ? 'Не удалось определить местоположение: $e'
            : 'Не удалось определить местоположение. Проверьте настройки GPS.';
        _isLoading = false;
        _isSearchingEmergency = false;
      });
      _showEmergencyError(_error!);
    }
  }

  void _startLocationUpdates() {
    _locationSubscription?.cancel();
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      if (_isSearchingEmergency) {
        ref.read(userProvider.notifier).updateLocation(
              position.latitude,
              position.longitude,
            );
      }
    });
  }

  void _showEmergencyError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String get _formattedTime {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Подписка не активна'),
        content: const Text(
          'Для использования функции экстренного вызова необходима активная подписка.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Оформить'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final emergencyState = ref.watch(emergencyProvider);
    final user = userState.user;
    final hasSubscription = user?.hasActiveSubscription ?? false;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 1,
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: SvgPicture.asset(
                    'assets/images/home_dots_decoration.svg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 1,
                child: SvgPicture.asset(
                  'assets/images/home_line_decoration.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SafeArea(
            child: _isSearchingEmergency
                ? _buildSearchingState(hasSubscription, emergencyState.activeCall)
                : _buildDefaultState(hasSubscription),
          ),
        ]
      ),
    );
  }

  Widget _buildDefaultState(bool hasSubscription) {
    return Column(
      children: [
          _buildHeader(hasSubscription),
            
            // SOS Button
          Expanded(
            child: Center(
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  _onSosPressed();
                },
                onTapCancel: () => setState(() => _isPressed = false),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse rings
                        ...List.generate(3, (index) {
                          final delay = index * 0.33;
                          final value = (_pulseController.value + delay) % 1.0;
                          return Container(
                            width: 200 + (value * 80),
                            height: 200 + (value * 80),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.sosRed.withAlpha(
                                  (76 * (1 - value)).toInt(),
                                ),
                                width: 2,
                              ),
                            ),
                          );
                        }),

                        // Glow
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.sosRed.withAlpha(102),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),

                        // Button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: _isPressed ? 180 : 200,
                          height: _isPressed ? 180 : 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.sosRed,
                                AppColors.sosRed.withRed(180),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.sosRed.withAlpha(153),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'SOS',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
            
            // Instructions
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Нажмите для вызова охраны',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            
            const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSearchingState(bool hasSubscription, EmergencyCall? activeCall) {
    final isAccepted = _isActiveGuardStatus(activeCall?.status);
    final radarColor = isAccepted ? AppColors.success : AppColors.sosRed;

    return Column(
      children: [
        _buildHeader(hasSubscription),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) => SizedBox(
                  width: 350,
                  height: 350,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Static glow behind the whole searching radar area.
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: radarColor.withAlpha(70),
                              blurRadius: 120,
                              spreadRadius: 35,
                            ),
                          ],
                        ),
                      ),
                      // Crosshair behind radar rings (same size as largest ring).
                      SizedBox(
                        width: 270,
                        height: 270,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 270,
                              height: 1,
                              color: radarColor.withAlpha(36),
                            ),
                            Container(
                              width: 1,
                              height: 270,
                              color: radarColor.withAlpha(36),
                            ),
                          ],
                        ),
                      ),
                      ...List.generate(7, (index) {
                        final delay = (16 - index) * 0.12;
                        final value = (_pulseController.value + delay) % 1.0;
                        final size = (90.0 + (index * 30)) + (value * 8);
                        return Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: radarColor
                                  .withAlpha((80 * (1 - value)).toInt()),
                              width: 1,
                            ),
                          ),
                        );
                      }),
                      Transform.rotate(
                        angle: _pulseController.value * 6.28318,
                        child: Container(
                          width: 270,
                          height: 270,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                radarColor.withAlpha(160),
                                radarColor.withAlpha(80),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.7, 0.4, 0.2],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 185,
                        height: 185,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: radarColor.withAlpha(140),
                            width: 6,
                          ),
                        ),
                        child: Container(
                          width: 185,
                          height: 185,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background.withAlpha(140),
                              width: 6,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isAccepted ? 'В работе' : 'Поиск\nохраны...',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 40 / 2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _formattedTime,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 30 / 2,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),
              if (!isAccepted)
                Text(
                  'Ближайшие службы\nоповещены',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                ),
            ],
          ),
        ),
        if (isAccepted && activeCall != null)
          _buildCurrentCallWidget(activeCall)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
              onPressed: () => _cancelEmergencySearch(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  backgroundColor: AppColors.error.withAlpha(15),
                ),
                child: const Text(
                  'Отменить вызов',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 26 / 2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isActiveGuardStatus(String? status) {
    return status == 'accepted' || status == 'en_route' || status == 'arrived';
  }

  Widget _buildCurrentCallWidget(EmergencyCall call) {
    final companyName = call.securityCompany?.name ?? 'Охрана назначена';
    final companyPhone = call.securityCompany?.phone;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                  color: AppColors.backgroundLight,
                ),
                child: const Icon(Icons.person, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.star, color: AppColors.warning, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '4.8 (127 отзывов)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (call.id != 0) {
                      context.push('/emergency/chat', extra: call.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0x2B22C55E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call, color: AppColors.success),
                  ),
                ),
              ),
            ],
          ),
          if (companyPhone != null && companyPhone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                companyPhone,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.push('/emergency/chat', extra: call.id),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.backgroundLight.withAlpha(180),
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Детали вызова',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _cancelEmergencySearch(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool hasSubscription) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Safe City',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (hasSubscription ? AppColors.success : AppColors.textSecondary)
                  .withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasSubscription ? Icons.check_circle : Icons.cancel,
                  color:
                      hasSubscription ? AppColors.success : AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  hasSubscription ? 'Активна' : 'Не активна',
                  style: TextStyle(
                    color: hasSubscription
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
