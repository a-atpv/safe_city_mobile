import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api.dart';
import '../../features/subscription/data/payment_models.dart';

class PaymentState {
  final List<Plan> plans;
  final bool isLoadingPlans;
  final bool isCreating;
  final bool isCancelling;
  final String? error;

  /// Последний созданный платёж — по нему экран статуса отправляет событие
  /// покупки в Meta. Сбрасывается сразу после отправки, чтобы одна оплата не
  /// засчиталась дважды.
  final PendingPayment? pending;

  const PaymentState({
    this.plans = const [],
    this.isLoadingPlans = false,
    this.isCreating = false,
    this.isCancelling = false,
    this.error,
    this.pending,
  });

  PaymentState copyWith({
    List<Plan>? plans,
    bool? isLoadingPlans,
    bool? isCreating,
    bool? isCancelling,
    String? error,
    PendingPayment? pending,
    bool clearPending = false,
  }) {
    return PaymentState(
      plans: plans ?? this.plans,
      isLoadingPlans: isLoadingPlans ?? this.isLoadingPlans,
      isCreating: isCreating ?? this.isCreating,
      isCancelling: isCancelling ?? this.isCancelling,
      error: error,
      pending: clearPending ? null : (pending ?? this.pending),
    );
  }
}

class PaymentNotifier extends Notifier<PaymentState> {
  late final ApiClient _apiClient;

  @override
  PaymentState build() {
    _apiClient = ApiClient();
    return const PaymentState();
  }

  /// Load the subscription plans catalog (source of truth for prices).
  Future<void> fetchPlans() async {
    state = state.copyWith(isLoadingPlans: true, error: null);
    try {
      final response = await _apiClient.dio.get('/payments/plans');
      final list = (response.data['plans'] as List)
          .map((e) => Plan.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(plans: list, isLoadingPlans: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoadingPlans: false,
        error: ApiException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoadingPlans: false, error: e.toString());
    }
  }

  /// Create a pending payment and return the Robokassa payment URL to open.
  /// Returns null on failure (see [PaymentState.error]).
  Future<CreatePaymentResult?> createPayment(
    String planCode, {
    required bool recurring,
  }) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final response = await _apiClient.dio.post(
        '/payments/create',
        data: {'plan': planCode, 'recurring': recurring},
      );
      final result = CreatePaymentResult.fromJson(
        response.data as Map<String, dynamic>,
      );
      state = state.copyWith(
        isCreating: false,
        pending: PendingPayment.of(planCode, result),
      );
      return result;
    } on DioException catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: ApiException.fromDioError(e).message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(isCreating: false, error: e.toString());
      return null;
    }
  }

  /// Забыть подтверждённый платёж — чтобы повторный заход на экран статуса не
  /// отправил событие покупки второй раз.
  void clearPending() {
    state = state.copyWith(clearPending: true);
  }

  /// Turn off auto-renewal. Access is kept until the period ends; only future
  /// recurring charges stop. Returns true on success (see [PaymentState.error]).
  Future<bool> cancelSubscription() async {
    state = state.copyWith(isCancelling: true, error: null);
    try {
      await _apiClient.dio.post('/payments/subscription/cancel');
      state = state.copyWith(isCancelling: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isCancelling: false,
        error: ApiException.fromDioError(e).message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(isCancelling: false, error: e.toString());
      return false;
    }
  }
}

final paymentProvider =
    NotifierProvider<PaymentNotifier, PaymentState>(PaymentNotifier.new);
