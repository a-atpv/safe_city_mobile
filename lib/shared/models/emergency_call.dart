class SecurityCompanyBrief {
  final int id;
  final String name;
  final String? logoUrl;
  final String phone;

  SecurityCompanyBrief({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.phone,
  });

  factory SecurityCompanyBrief.fromJson(Map<String, dynamic> json) {
    return SecurityCompanyBrief(
      id: json['id'],
      name: json['name'],
      logoUrl: json['logo_url'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'phone': phone,
    };
  }
}

class EmergencyCall {
  final int id;
  final String status; // searching, offer_sent, accepted, en_route, arrived, completed, cancelled_by_user, cancelled_by_system
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? enRouteAt;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final SecurityCompanyBrief? securityCompany;
  final CallUser? user;
  final CallGuard? guard;

  EmergencyCall({
    required this.id,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.createdAt,
    this.acceptedAt,
    this.enRouteAt,
    this.arrivedAt,
    this.completedAt,
    this.securityCompany,
    this.user,
    this.guard,
  });

  EmergencyCall copyWith({
    String? status,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? enRouteAt,
    DateTime? arrivedAt,
    DateTime? completedAt,
    SecurityCompanyBrief? securityCompany,
    CallUser? user,
    CallGuard? guard,
  }) {
    return EmergencyCall(
      id: id,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      enRouteAt: enRouteAt ?? this.enRouteAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      completedAt: completedAt ?? this.completedAt,
      securityCompany: securityCompany ?? this.securityCompany,
      user: user ?? this.user,
      guard: guard ?? this.guard,
    );
  }

  factory EmergencyCall.fromJson(Map<String, dynamic> json) {
    return EmergencyCall(
      id: json['id'],
      status: json['status'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']).toLocal() : null,
      enRouteAt: json['en_route_at'] != null ? DateTime.parse(json['en_route_at']).toLocal() : null,
      arrivedAt: json['arrived_at'] != null ? DateTime.parse(json['arrived_at']).toLocal() : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']).toLocal() : null,
      securityCompany: json['security_company'] != null
          ? SecurityCompanyBrief.fromJson(json['security_company'])
          : null,
      user: json['user'] != null ? CallUser.fromJson(json['user']) : null,
      guard: json['guard'] != null ? CallGuard.fromJson(json['guard']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'created_at': createdAt.toUtc().toIso8601String(),
      'accepted_at': acceptedAt?.toUtc().toIso8601String(),
      'en_route_at': enRouteAt?.toUtc().toIso8601String(),
      'arrived_at': arrivedAt?.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'security_company': securityCompany?.toJson(),
      'user': user?.toJson(),
      'guard': guard?.toJson(),
    };
  }
}

class CallUser {
  final String fullName;
  final String phone;
  final String? avatarUrl;

  CallUser({
    required this.fullName,
    required this.phone,
    this.avatarUrl,
  });

  factory CallUser.fromJson(Map<String, dynamic> json) {
    return CallUser(
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
    };
  }
}

class CallGuard {
  final int id;
  final String fullName;
  final String? avatarUrl;
  final double rating;
  final int totalReviews;

  CallGuard({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.rating,
    required this.totalReviews,
  });

  factory CallGuard.fromJson(Map<String, dynamic> json) {
    return CallGuard(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      avatarUrl: json['avatar_url'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'rating': rating,
      'total_reviews': totalReviews,
    };
  }
}
