import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/services/push_notification_service.dart';

// Auth state
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? email;
  final bool isLoading;
  final String? error;
  
  const AuthState({
    this.status = AuthStatus.unknown,
    this.email,
    this.isLoading = false,
    this.error,
  });
  
  AuthState copyWith({
    AuthStatus? status,
    String? email,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final ApiClient _apiClient;
  
  @override
  AuthState build() {
    _apiClient = ApiClient();
    _apiClient.onLogout = logout;
    _checkAuthStatus();
    return const AuthState();
  }
  
  Future<void> _checkAuthStatus() async {
    final hasToken = await _apiClient.hasValidToken();
    if (hasToken) {
      _registerDevice();
    }
    state = state.copyWith(
      status: hasToken ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> _registerDevice() async {
    try {
      final token = await PushNotificationService().getFcmToken();
      if (token != null) {
        await _apiClient.registerDevice(
          token: token,
          type: Platform.isIOS ? 'ios' : 'android',
        );
        debugPrint('User device registered successfully');
      }
    } catch (e) {
      debugPrint('Failed to register user device: $e');
    }
  }
  
  Future<bool> requestOtp(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiClient.dio.post(
        '/auth/request-otp',
        data: {'email': email},
      );
      
      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false, email: email);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Не удалось отправить код');
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  Future<bool> verifyOtp(String email, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiClient.dio.post(
        '/auth/verify-otp',
        data: {'email': email, 'code': code},
      );
      
      if (response.statusCode == 200) {
        await _apiClient.setTokens(
          response.data['access_token'],
          response.data['refresh_token'],
        );
        await _registerDevice();
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.authenticated,
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Неверный код');
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  Future<void> logout() async {
    await _apiClient.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// A [ChangeNotifier] that notifies GoRouter when auth state changes.
class AuthChangeNotifier extends ChangeNotifier {
  late final ProviderSubscription<AuthState> _subscription;

  AuthChangeNotifier(Ref ref) {
    _subscription = ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  final notifier = AuthChangeNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});
