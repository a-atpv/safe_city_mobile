import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';

// User model
class User {
  final int id;
  final String email;
  final String? phone;
  final String? fullName;
  final String? avatarUrl;
  final bool isVerified;
  final Subscription? subscription;
  
  User({
    required this.id,
    required this.email,
    this.phone,
    this.fullName,
    this.avatarUrl,
    this.isVerified = false,
    this.subscription,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      isVerified: json['is_verified'] ?? false,
      subscription: json['subscription'] != null 
          ? Subscription.fromJson(json['subscription'])
          : null,
    );
  }
  
  bool get hasActiveSubscription => subscription?.isActive ?? false;
}

class Subscription {
  final int id;
  final String status;
  final String planType;
  final DateTime? expiresAt;
  
  Subscription({
    required this.id,
    required this.status,
    required this.planType,
    this.expiresAt,
  });
  
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      status: json['status'],
      planType: json['plan_type'],
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'])
          : null,
    );
  }
  
  bool get isActive => status == 'active';
}

// User state
class UserState {
  final User? user;
  final bool isLoading;
  final String? error;
  
  const UserState({
    this.user,
    this.isLoading = false,
    this.error,
  });
  
  UserState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  late final ApiClient _apiClient;
  
  @override
  UserState build() {
    _apiClient = ApiClient();
    return const UserState();
  }
  
  Future<void> fetchUser() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiClient.dio.get('/user/me');
      
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        state = state.copyWith(isLoading: false, user: user);
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<bool> updateProfile({String? fullName, String? phone}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone'] = phone;
      
      final response = await _apiClient.dio.patch('/user/me', data: data);
      
      if (response.statusCode == 200) {
        await fetchUser();
        return true;
      }
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  Future<bool> updateLocation(double latitude, double longitude) async {
    try {
      await _apiClient.dio.post('/user/location', data: {
        'latitude': latitude,
        'longitude': longitude,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
  
  void clear() {
    state = const UserState();
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(UserNotifier.new);
