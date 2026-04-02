class CallMessage {
  final int id;
  final int callId;
  final String senderType; // user or guard
  final int senderId;
  final String message;
  final DateTime createdAt;

  CallMessage({
    required this.id,
    required this.callId,
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  bool get isFromUser => senderType == 'user';

  factory CallMessage.fromJson(Map<String, dynamic> json) {
    return CallMessage(
      id: json['id'],
      callId: json['call_id'],
      senderType: json['sender_type'],
      senderId: json['sender_id'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}
