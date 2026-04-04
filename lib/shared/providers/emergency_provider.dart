import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    } catch (_) {
      // If 404 or fails, it might mean there's no active call
    }
  }

  Future<bool> cancelCall(int callId, String? reason) async {
    try {
      final response = await _apiClient.dio.post('/emergency/call/$callId/cancel', data: {
        'reason': reason,
      });
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
}

final emergencyProvider = NotifierProvider<EmergencyNotifier, EmergencyState>(EmergencyNotifier.new);
