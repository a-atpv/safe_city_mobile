import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/payment_provider.dart';
import '../application/payment_launcher.dart';
import '../data/payment_models.dart';

const _offerUrl = 'https://www.safe-city.kz/legal/public-offer';
const _privacyUrl = 'https://www.safe-city.kz/legal/privacy-policy';

const _termsStyle = TextStyle(
  color: AppColors.textHint,
  fontSize: 12,
  height: 1.45,
);

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _selected; // selected plan code
  bool _consentGiven = false; // gates the pay button, see [_consentBlock]

  late final TapGestureRecognizer _offerRecognizer =
      TapGestureRecognizer()..onTap = () => _openUrl(_offerUrl);
  late final TapGestureRecognizer _privacyRecognizer =
      TapGestureRecognizer()..onTap = () => _openUrl(_privacyUrl);

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(paymentProvider.notifier).fetchPlans();
      if (!mounted) return;
      final plans = ref.read(paymentProvider).plans;
      if (plans.isNotEmpty) setState(() => _selected = plans.first.code);
    });
  }

  @override
  void dispose() {
    _offerRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched) throw Exception('launchUrl returned false');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть документ')),
      );
    }
  }

  Future<void> _subscribe() async {
    final code = _selected;
    if (code == null || !_consentGiven) return;

    final result = await ref
        .read(paymentProvider.notifier)
        .createPayment(code, recurring: AppConstants.subscriptionRecurring);
    if (!mounted) return;

    if (result == null) {
      final err =
          ref.read(paymentProvider).error ?? 'Не удалось создать платёж';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    await PaymentLauncher.open(context, result.paymentUrl);
    if (!mounted) return;
    context.push('/subscribe/status');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentProvider);
    final loading = state.isLoadingPlans && state.plans.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Подписка'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            child: const Text(
              'Позже',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Text(
                          'Полный доступ ко всем функциям',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Кнопка SOS, геолокация в реальном времени и связь '
                          'с диспетчером 24/7.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        for (final p in state.plans) _planCard(p),
                        const SizedBox(height: 16),
                        const _Features(),
                        const SizedBox(height: 16),
                        _recurringTerms(state.plans),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _consentBlock(),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: (_selected == null ||
                                    !_consentGiven ||
                                    state.isCreating)
                                ? null
                                : _subscribe,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: AppColors.backgroundCard,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: state.isCreating
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Оформить',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Recurring terms Robokassa requires on the subscription form itself:
  /// amount, frequency, duration, and how to switch the charges off. The
  /// consent to those charges lives in [_consentBlock], next to the button.
  Widget _recurringTerms(List<Plan> plans) {
    return Text(
      AppConstants.subscriptionRecurringCopy
          ? 'Подписка продлевается автоматически: ${_chargeAmounts(plans)} '
              '— бессрочно, до отмены. Отключить автопродление можно в '
              'любой момент: Профиль → Подписка → «Отменить подписку», '
              'либо обратившись в службу поддержки. После отмены списаний '
              'больше не будет, доступ сохранится до конца оплаченного '
              'периода.'
          : 'Оплата за выбранный период.',
      style: _termsStyle,
      textAlign: TextAlign.center,
    );
  }

  /// The consent the payment systems require *on the checkout form*, right
  /// above the pay button: recurring charges, personal-data processing, and
  /// acceptance of the public оферта (which spells out the recurring rules).
  /// Ticking the box is the act of consent — until then «Оформить» is disabled,
  /// so no payment can start without it. Tapping anywhere in the block toggles
  /// the box; the two links win the tap over their own spans.
  Widget _consentBlock() {
    final link = _termsStyle.copyWith(
      color: AppColors.primary,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _consentGiven = !_consentGiven),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _consentGiven ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _consentGiven,
                onChanged: (v) => setState(() => _consentGiven = v ?? false),
                activeColor: AppColors.primary,
                checkColor: Colors.white,
                side: const BorderSide(color: AppColors.textHint, width: 1.5),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: _termsStyle,
                  children: [
                    const TextSpan(text: 'Я даю согласие '),
                    if (AppConstants.subscriptionRecurringCopy)
                      const TextSpan(
                        text: 'на регулярные (автоматические) списания, ',
                      ),
                    const TextSpan(text: 'на '),
                    TextSpan(
                      text: 'обработку персональных данных',
                      style: link,
                      recognizer: _privacyRecognizer,
                    ),
                    const TextSpan(text: ' и принимаю условия '),
                    TextSpan(
                      text: 'публичной оферты',
                      style: link,
                      recognizer: _offerRecognizer,
                    ),
                    TextSpan(
                      text: AppConstants.subscriptionRecurringCopy
                          ? ', в которой подробно описаны правила '
                              'рекуррентных платежей.'
                          : '.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// «800 ₸ каждый месяц или 6900 ₸ каждый год», built from the live plans so
  /// the terms can never drift from the prices on the cards above.
  String _chargeAmounts(List<Plan> plans) {
    if (plans.isEmpty) {
      return '${AppConstants.monthlyPriceKzt} ₸ каждый месяц или '
          '${AppConstants.yearlyPriceKzt} ₸ каждый год';
    }
    return plans
        .map((p) =>
            '${p.priceTenge} ₸ ${p.isYearly ? 'каждый год' : 'каждый месяц'}')
        .join(' или ');
  }

  Widget _planCard(Plan p) {
    final selected = _selected == p.code;
    return GestureDetector(
      onTap: () => setState(() => _selected = p.code),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        p.isYearly ? 'Годовая' : 'Месячная',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (p.isYearly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            // success green @ ~15% alpha
                            color: const Color(0x2622C55E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'выгодно',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p.priceTenge} ₸ / ${p.isYearly ? 'год' : 'мес'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Features extends StatelessWidget {
  const _Features();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Кнопка SOS в одно касание',
      'Геолокация в реальном времени',
      'Связь с диспетчером 24/7',
      'Приложение для iOS и Android',
    ];
    return Column(
      children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
