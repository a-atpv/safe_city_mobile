import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api/api.dart';
import '../models/emergency_call.dart';
import '../models/call_message.dart';

class EmergencyState {
  final EmergencyCall? activeCall;
  final bool isLoading;
  final String? error;
  final List<CallMessage> messages;

  const EmergencyState({
    this.activeCall,
    this.isLoading = false,
    this.error,
    this.messages = const [],
  });

  EmergencyState copyWith({
    EmergencyCall? activeCall,
    bool? isLoading,
    String? error,
    List<CallMessage>? messages,
  }) {
    return EmergencyState(
      activeCall: activeCall ?? this.activeCall,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      messages: messages ?? this.messages,
    );
  }
}

class EmergencyNotifier extends Notifier<EmergencyState> {
  late final ApiClient _apiClient;

  @override
  EmergencyState build() {
    _apiClient = ApiClient();
    return const EmergencyState();
  }

  Future<bool> createCall(double lat, double lng, String? address) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.dio.post('/emergency/call', data: {
        'latitude': lat,
        'longitude': lng,
        'address': address,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(
          isLoading: false,
          activeCall: EmergencyCall.fromJson(response.data),
        );
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

  Future<void> getActiveCall() async {
    try {
      final response = await _apiClient.dio.get('/emergency/call/active');
      if (response.statusCode == 200) {
        state = state.copyWith(activeCall: EmergencyCall.fromJson(response.data));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // If it's a 404, the call has been completed or cancelled by system/user.
        // As a fallback, transition it to 'completed' so that active screens (like EmergencyScreen or ChatScreen)
        // trigger their redirection handlers.
        if (state.activeCall != null && state.activeCall!.status != 'completed') {
          state = state.copyWith(
            activeCall: state.activeCall!.copyWith(status: 'completed'),
          );
        }
      }
    } catch (_) {
      // Other network errors should not alter state
    }
  }

  Future<bool> cancelCall(int callId, String? reason, {String? secretPhrase}) async {
    try {
      final data = <String, dynamic>{'reason': reason};
      if (secretPhrase != null && secretPhrase.isNotEmpty) {
        data['secret_phrase'] = secretPhrase;
      }
      final response = await _apiClient.dio.post(
        '/emergency/call/$callId/cancel',
        data: data,
      );
      if (response.statusCode == 200) {
        state = const EmergencyState(); // clear state
        return true;
      }
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Не удалось отменить вызов');
      return false;
    }
  }

  Future<void> getMessages(int callId) async {
    try {
      final response = await _apiClient.dio.get('/emergency/call/$callId/messages');
      if (response.statusCode == 200) {
        final messagesData = response.data['messages'] as List;
        final messages = messagesData.map((e) => CallMessage.fromJson(e)).toList();
        state = state.copyWith(messages: messages);
      }
    } catch (_) {}
  }

  Future<bool> sendMessage(int callId, String message) async {
    try {
      final response = await _apiClient.dio.post('/emergency/call/$callId/message', data: {
        'message': message,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        await getMessages(callId);
        return true;
      }
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Не удалось отправить сообщение');
      return false;
    }
  }

  Future<bool> submitReview(int callId, int rating, String? comment) async {
    try {
      final response = await _apiClient.dio.post('/emergency/call/$callId/review', data: {
        'rating': rating,
        'comment': comment,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  void clearActiveCall() {
    state = const EmergencyState();
  }

  void updateActiveCallStatus(String status) {
    if (state.activeCall != null) {
      state = state.copyWith(
        activeCall: state.activeCall!.copyWith(status: status),
      );
    }
  }

  void updateActiveCall(EmergencyCall call) {
    state = state.copyWith(activeCall: call);
  }
}

final emergencyProvider = NotifierProvider<EmergencyNotifier, EmergencyState>(EmergencyNotifier.new);
