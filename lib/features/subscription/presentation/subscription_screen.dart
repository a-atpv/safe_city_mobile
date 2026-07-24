import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/subscription.dart';
import '../../../shared/providers/payment_provider.dart';
import '../../../shared/providers/user_provider.dart';

/// Subscription management + the «Отменить подписку» (unsubscribe) form.
///
/// Cancelling turns off auto-renewal via POST /payments/subscription/cancel.
/// Access is kept until the paid period ends; only future recurring charges
/// stop. Reachable from Profile → «Подписка» when a subscription is active.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    // Make sure we show the freshest status when the screen opens.
    Future.microtask(() => ref.read(userProvider.notifier).fetchUser());
  }

  String _fmt(DateTime? d) => d == null ? '—' : DateFormat('dd.MM.yyyy').format(d);

  String _planName(String planType) =>
      planType == 'yearly' ? 'Годовая' : 'Месячная';

  Future<void> _confirmCancel(Subscription sub) async {
    final until = _fmt(sub.expiresAt);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Отменить подписку?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Автоматические списания прекратятся. Доступ к функциям сохранится '
          'до $until, деньги за оставшийся период не списываются и не '
          'возвращаются. Возобновить подписку можно в любой момент.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Не отменять',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Отменить подписку',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref.read(paymentProvider.notifier).cancelSubscription();
    if (!mounted) return;
    if (ok) {
      await ref.read(userProvider.notifier).fetchUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Автопродление отключено')),
      );
    } else {
      final err = ref.read(paymentProvider).error ?? 'Не удалось отменить подписку';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(userProvider).user?.subscription;
    final cancelling = ref.watch(paymentProvider).isCancelling;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Управление подпиской'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: (sub == null || !sub.isActive)
              ? _inactive(context)
              : _active(context, sub, cancelling),
        ),
      ),
    );
  }

  Widget _inactive(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.workspace_premium_outlined,
            color: AppColors.textHint, size: 56),
        const SizedBox(height: 16),
        const Text(
          'Подписка неактивна',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Оформите подписку, чтобы пользоваться кнопкой SOS и связью с '
          'диспетчером.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        _primaryButton('Оформить', () => context.push('/subscribe')),
      ],
    );
  }

  Widget _active(BuildContext context, Subscription sub, bool cancelling) {
    final cancelled = sub.isCancelled;
    final autoRenewOn = sub.autoRenew && !cancelled;

    final String note;
    if (cancelled) {
      note = 'Автопродление отключено. Подписка действует до '
          '${_fmt(sub.expiresAt)}, после чего доступ прекратится. '
          'Списаний больше не будет.';
    } else if (autoRenewOn) {
      note = 'Подписка продлевается автоматически. Вы можете отключить '
          'автопродление в любой момент — доступ сохранится до конца '
          'оплаченного периода.';
    } else {
      note = 'Подписка действует до ${_fmt(sub.expiresAt)}. '
          'Автопродление не подключено.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${_planName(sub.planType)} подписка',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Активна',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _row(Icons.event_available_outlined,
                  cancelled ? 'Доступ до' : 'Активна до', _fmt(sub.expiresAt)),
              const SizedBox(height: 10),
              _row(
                autoRenewOn ? Icons.autorenew : Icons.autorenew_outlined,
                'Автопродление',
                autoRenewOn ? 'Включено' : 'Отключено',
                valueColor: autoRenewOn ? AppColors.success : AppColors.textHint,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          note,
          style: const TextStyle(color: AppColors.textHint, fontSize: 13),
        ),
        const SizedBox(height: 24),
        if (cancelled)
          _primaryButton('Возобновить подписку', () => context.push('/subscribe'))
        else
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: cancelling ? null : () => _confirmCancel(sub),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: cancelling
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : const Text(
                      'Отменить подписку',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
