import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api.dart';
import '../../features/subscription/data/payment_models.dart';

class PaymentState {
  final List<Plan> plans;
  final bool isLoadingPlans;
  final bool isCreating;
  final String? error;

  const PaymentState({
    this.plans = const [],
    this.isLoadingPlans = false,
    this.isCreating = false,
    this.error,
  });

  PaymentState copyWith({
    List<Plan>? plans,
    bool? isLoadingPlans,
    bool? isCreating,
    String? error,
  }) {
    return PaymentState(
      plans: plans ?? this.plans,
      isLoadingPlans: isLoadingPlans ?? this.isLoadingPlans,
      isCreating: isCreating ?? this.isCreating,
      error: error,
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
      state = state.copyWith(isCreating: false);
      return CreatePaymentResult.fromJson(
        response.data as Map<String, dynamic>,
      );
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
}

final paymentProvider =
    NotifierProvider<PaymentNotifier, PaymentState>(PaymentNotifier.new);
