import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/analytics/app_analytics.dart';
import '../../../core/api/api.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/location_permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/update/update_prompt.dart';
import '../../../l10n/l10n.dart';
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
  bool _isPressed = false;
  bool _isSearchingEmergency = false;
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
    
    // Fetch user data and check for active calls on startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(userProvider.notifier).fetchUser();
      ref.read(emergencyProvider.notifier).getActiveCall();
      // Первый экран после входа — единственное место, где диалог об
      // обновлении никому не мешает: тревожная кнопка ещё не нажата.
      await UpdatePrompt.maybeShow(context);
      // Запрос ATT — строго после него и только один раз за всё время: два
      // диалога подряд iOS схлопывает, и системный запрос теряется навсегда.
      // Раньше главного экрана его показывать нельзя — на сплеше человек
      // закрывает такое не читая, а второй попытки система не даёт.
      await AppAnalytics.requestTrackingPermission();
    });
  }
  
  @override
  void dispose() {
    _searchTimer?.cancel();
    _statusPollTimer?.cancel();
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
    if (_callId == null) return;

    final l10n = context.l10n;
    final secretPhraseController = TextEditingController();
    bool obscure = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.sosCancelTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.sosCancelBody),
              const SizedBox(height: 16),
              TextField(
                controller: secretPhraseController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: l10n.profileSecretLabel,
                  hintText: l10n.sosSecretHint,
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
              child: Text(l10n.commonNo),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(l10n.sosCancelConfirm),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    _searchTimer?.cancel();
    _statusPollTimer?.cancel();
    // Трекинг гасит сам провайдер: cancelCall обнуляет активный вызов.

    await ref.read(emergencyProvider.notifier).cancelCall(
      _callId!,
      null,
      secretPhrase: secretPhraseController.text.isNotEmpty
          ? secretPhraseController.text
          : null,
    );

    setState(() {
      _isSearchingEmergency = false;
      _isPressed = false;
      _elapsedSeconds = 0;
      _callId = null;
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
    // Строки берём до первого await: к концу запроса экран может уйти.
    final l10n = context.l10n;
    setState(() {
      _error = null;
      _isSearchingEmergency = true;
      _elapsedSeconds = 0;
    });

    try {
      final hasPermissions = await LocationPermissionService.checkAndRequestPermissions(context);
      if (!hasPermissions) {
        setState(() {
          _isSearchingEmergency = false;
        });
        return;
      }

      // Берём максимально точную стартовую координату: свежий high-accuracy
      // фикс, а не потенциально устаревший кэш getLastKnownPosition.
      final position =
          await LocationPermissionService.getBestInitialPosition();

      final success = await ref.read(emergencyProvider.notifier).createCall(
            position.latitude,
            position.longitude,
            null,
          );

      if (success) {
        final activeCall = ref.read(emergencyProvider).activeCall;
        setState(() {
          _callId = activeCall?.id;
        });
        _startSearchTimer();
        _startStatusPolling();
      } else {
        final emergencyState = ref.read(emergencyProvider);
        setState(() {
          _error = emergencyState.error ?? l10n.sosCreateFailed;
          _isSearchingEmergency = false;
        });
        _showCreateCallError(_error!, emergencyState.errorCode);
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isSearchingEmergency = false;
      });
      _showCreateCallError(_error!, e.code);
    } on DioException catch (e) {
      final apiError = ApiException.fromDioError(e);
      setState(() {
        _error = kDebugMode
            ? '${apiError.message} (status: ${apiError.statusCode})'
            : apiError.message;
        _isSearchingEmergency = false;
      });
      _showCreateCallError(_error!, apiError.code);
    } on LocationServiceDisabledException catch (_) {
      setState(() {
        _error = l10n.sosLocationServicesOff;
        _isSearchingEmergency = false;
      });
      _showEmergencyError(_error!);
    } on PermissionDeniedException catch (_) {
      setState(() {
        _error = l10n.sosLocationDenied;
        _isSearchingEmergency = false;
      });
      _showEmergencyError(_error!);
    } on TimeoutException catch (_) {
      setState(() {
        _error = l10n.sosLocationTimeout;
        _isSearchingEmergency = false;
      });
      _showEmergencyError(_error!);
    } catch (e) {
      setState(() {
        _error = kDebugMode
            ? l10n.sosLocationFailedDetails('$e')
            : l10n.sosLocationFailed;
        _isSearchingEmergency = false;
      });
      _showEmergencyError(_error!);
    }
  }

  // Координаты во время вызова шлёт emergencyLocationProvider — он привязан к
  // состоянию вызова, а не к экрану, и переживает переход в чат с экипажем.

  void _showEmergencyError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Показывает, почему вызов не создан.
  ///
  /// Отказ по зоне обслуживания — не сбой, а ответ по существу: снекбар для
  /// него слишком мимолётный. Человек должен успеть прочитать, что экипаж не
  /// приедет, и сразу получить рабочий запасной путь — звонок 102.
  void _showCreateCallError(String message, String? code) {
    if (!mounted) return;
    if (code == ApiErrorCodes.outsideServiceArea) {
      _showOutsideServiceAreaDialog(message);
      return;
    }
    _showEmergencyError(message);
  }

  void _showOutsideServiceAreaDialog(String message) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_off_outlined, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.sosOutsideAreaTitle)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonClose),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _callPolice();
            },
            icon: const Icon(Icons.call),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            label: Text(l10n.sosCall102),
          ),
        ],
      ),
    );
  }

  Future<void> _callPolice() async {
    try {
      await launchUrl(Uri(scheme: 'tel', path: '102'));
    } catch (_) {
      if (!mounted) return;
      _showEmergencyError(context.l10n.sosDialerFailed);
    }
  }

  String get _formattedTime {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  void _showSubscriptionDialog() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.homeNoSubscriptionTitle),
        content: Text(l10n.homeNoSubscriptionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose),
          ),
          // Purchase flow is hidden while payments are disabled.
          if (AppConstants.paymentEnabled)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/subscribe');
              },
              child: Text(l10n.homeSubscribe),
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
    
    // 1. Sync local searching state if a call is active in the provider (e.g. on app start/resume)
    if (emergencyState.activeCall != null && !_isSearchingEmergency) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final activeCall = emergencyState.activeCall!;
          final diff = DateTime.now().difference(activeCall.createdAt).inSeconds;
          setState(() {
            _isSearchingEmergency = true;
            _callId = activeCall.id;
            _elapsedSeconds = diff > 0 ? diff : 0;
          });
          _startSearchTimer();
          _startStatusPolling();
        }
      });
    }

    // 2. Reset local searching state when the active call is cleared/ended
    if (_isSearchingEmergency && _callId != null && emergencyState.activeCall == null && !emergencyState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchTimer?.cancel();
          _statusPollTimer?.cancel();
          setState(() {
            _isSearchingEmergency = false;
            _elapsedSeconds = 0;
            _callId = null;
          });
        }
      });
    }

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
    // When there is no active subscription the SOS button is shown inactive
    // (grey, no pulse) — tapping it opens the subscription paywall.
    final Color sosColor =
        hasSubscription ? AppColors.sosRed : const Color(0xFF6B7280);
    final Color sosColorDark =
        hasSubscription ? AppColors.sosRed.withRed(180) : const Color(0xFF4B5563);
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
                        // Pulse rings (only when the button is active)
                        if (hasSubscription)
                          ...List.generate(3, (index) {
                            final delay = index * 0.33;
                            final value =
                                (_pulseController.value + delay) % 1.0;
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
                                color: sosColor.withAlpha(102),
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
                              colors: [sosColor, sosColorDark],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: sosColor.withAlpha(153),
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
                hasSubscription
                    ? context.l10n.homeTapToCall
                    : context.l10n.homeTapToSubscribe,
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
                              stops: const [0.0, 0.2, 0.5, 0.7],
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
                                  isAccepted
                                      ? context.l10n.homeInProgress
                                      : context.l10n.homeSearchingSecurity,
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
                  context.l10n.homeServicesNotified,
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
                child: Text(
                  context.l10n.sosCancelCall,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 26 / 2),
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
    final l10n = context.l10n;
    final guard = call.guard;
    final companyName = call.securityCompany?.name ?? l10n.homeSecurityAssigned;
    final displayName = guard != null ? guard.fullName : companyName;
    final companyPhone = call.securityCompany?.phone;

    final hasAvatar = guard?.avatarUrl != null && guard!.avatarUrl!.isNotEmpty;
    final ratingText = guard != null 
        ? '${guard.rating.toStringAsFixed(1)} (${l10n.homeReviews(guard.totalReviews)})'
        : '4.8 (${l10n.homeReviews(127)})';

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
                child: hasAvatar
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(29),
                        child: Image.network(
                          guard.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.person,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.person, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.warning, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          ratingText,
                          style: const TextStyle(
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
                  child: Text(
                    l10n.homeCallDetails,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
          SizedBox(
            width: 36,
            height: 42,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/icons/safe_city_shield.png',
                fit: BoxFit.cover,
              ),
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
                  hasSubscription
                      ? context.l10n.profileSubscriptionActive
                      : context.l10n.homeSubscriptionInactive,
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
