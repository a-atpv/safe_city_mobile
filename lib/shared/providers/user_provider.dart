import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../models/subscription.dart';
import '../models/user_settings.dart';

// User model
class User {
  final int id;
  final String email;
  final String? phone;
  final String? fullName;
  final String? avatarUrl;
  final bool isVerified;
  final Subscription? subscription;
  final String? secretPhrase;
  final bool isNew;
  
  User({
    required this.id,
    required this.email,
    this.phone,
    this.fullName,
    this.avatarUrl,
    this.isVerified = false,
    this.subscription,
    this.secretPhrase,
    this.isNew = false,
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
      secretPhrase: json['secret_phrase'],
      isNew: json['is_new'] ?? false,
    );
  }
  
  bool get hasActiveSubscription => subscription?.isActive ?? false;
}


class UserState {
  final User? user;
  final bool isLoading;
  final String? error;
  final UserSettings? settings;
  final Subscription? fetchedSubscription;
  
  const UserState({
    this.user,
    this.isLoading = false,
    this.error,
    this.settings,
    this.fetchedSubscription,
  });
  
  UserState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    UserSettings? settings,
    Subscription? fetchedSubscription,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      settings: settings ?? this.settings,
      fetchedSubscription: fetchedSubscription ?? this.fetchedSubscription,
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
      state = state.copyWith(
        isLoading: false,
        error: ApiException.fromAny(e).message,
      );
    }
  }
  
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? secretPhrase,
    bool isNew = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final data = <String, dynamic>{'is_new': isNew};
      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone'] = phone;
      
      final response = await _apiClient.dio.patch('/user/me', data: data);
      
      if (response.statusCode == 200) {
        if (secretPhrase != null) {
          await _apiClient.dio.post(
            '/user/me/secret-phrase',
            data: {'secret_phrase': secretPhrase},
          );
        }
        await fetchUser();
        return true;
      }
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiException.fromAny(e).message,
      );
      return false;
    }
  }
  
  Future<bool> uploadAvatar(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _apiClient.dio.post(
        '/user/me/avatar',
        data: formData,
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        state = state.copyWith(isLoading: false, user: user);
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteAvatar() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.dio.delete('/user/me/avatar');

      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchUser();
        return true;
      }
      state = state.copyWith(isLoading: false);
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

  Future<void> fetchSubscription() async {
    try {
      final response = await _apiClient.dio.get('/user/subscription');
      if (response.statusCode == 200) {
        state = state.copyWith(fetchedSubscription: Subscription.fromJson(response.data));
      }
    } catch (_) {}
  }

  Future<void> fetchSettings() async {
    try {
      final response = await _apiClient.dio.get('/user/settings');
      if (response.statusCode == 200) {
        state = state.copyWith(settings: UserSettings.fromJson(response.data));
      }
    } catch (_) {}
  }

  Future<bool> updateSettings(UserSettings settings) async {
    try {
      final response = await _apiClient.dio.patch('/user/settings', data: settings.toJson());
      if (response.statusCode == 200) {
        state = state.copyWith(settings: settings);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final response = await _apiClient.dio.delete('/user/me');
      if (response.statusCode == 200 || response.statusCode == 204) {
        clear();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
  
  void clear() {
    state = const UserState();
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(UserNotifier.new);
