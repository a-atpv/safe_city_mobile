import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/payment_provider.dart';
import '../../../shared/providers/user_provider.dart';

/// Shown after the payment page closes. Polls the backend subscription status
/// (the server-side ResultURL callback is what actually activates it) until it
/// becomes active, or times out.
class PaymentStatusScreen extends ConsumerStatefulWidget {
  const PaymentStatusScreen({super.key});

  @override
  ConsumerState<PaymentStatusScreen> createState() =>
      _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _attempts = 0;
  static const int _maxAttempts = 40; // ~2 min at 3s intervals
  bool _active = false;
  bool _timedOut = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted || _active) return;
    // Coming back from the browser is the moment the payment is most likely to
    // have just gone through, so re-check immediately instead of waiting out
    // the interval. Paying in another app easily takes longer than the two
    // minutes this screen allows, so a wait that gave up while we were away
    // starts over rather than greeting the user with a dead end.
    if (_timedOut) {
      _startPolling();
    } else {
      _poll();
    }
  }

  void _startPolling() {
    _timer?.cancel();
    setState(() {
      _timedOut = false;
      _attempts = 0;
    });
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_active || _checking || !mounted) return;
    _checking = true;
    try {
      await ref.read(userProvider.notifier).fetchUser();
      final active =
          ref.read(userProvider).user?.hasActiveSubscription ?? false;
      if (!mounted) return;
      if (active) {
        _timer?.cancel();
        _reportPurchase();
        setState(() => _active = true);
      } else {
        _attempts++;
        if (_attempts >= _maxAttempts) {
          _timer?.cancel();
          setState(() => _timedOut = true);
        }
      }
    } finally {
      _checking = false;
    }
  }

  /// Покупка засчитывается один раз: платёж, по которому отправили событие,
  /// сразу забывается. Продления подписки сюда не попадают — их проводит
  /// бэкенд без участия приложения.
  void _reportPurchase() {
    final pending = ref.read(paymentProvider).pending;
    if (pending == null) return;
    ref.read(paymentProvider.notifier).clearPending();
    unawaited(
      AppAnalytics.logPurchase(
        amountTiyn: pending.amount,
        currency: pending.currency,
        plan: pending.planCode,
        orderId: pending.paymentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // No back arrow on purpose: popping lands on the paywall, and offering
        // to pay again while a payment is being confirmed is the wrong exit.
        automaticallyImplyLeading: false,
        // Waiting still needs a way out. The poll runs for two minutes before
        // it gives up, and until it does this screen has nothing to press.
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text(
              context.l10n.commonClose,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _active
              ? _buildSuccess()
              : _timedOut
                  ? _buildPending()
                  : _buildWaiting(),
        ),
      ),
    );
  }

  Widget _buildWaiting() {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.paymentConfirming,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.paymentMayTakeSeconds,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final l10n = context.l10n;
    final expiresAt = ref.read(userProvider).user?.subscription?.expiresAt;
    final until = expiresAt != null
        ? l10n.paymentActiveUntil(DateFormat('dd.MM.yyyy').format(expiresAt))
        : l10n.paymentSubscriptionActive;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 72),
        const SizedBox(height: 20),
        Text(
          l10n.paymentSubscribed,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          until,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              l10n.paymentDone,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPending() {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.hourglass_bottom, color: AppColors.warning, size: 64),
        const SizedBox(height: 20),
        Text(
          l10n.paymentStillProcessing,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.paymentStillProcessingBody,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _startPolling,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              l10n.paymentCheckAgain,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go('/home'),
          child: Text(
            l10n.paymentBackHome,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
