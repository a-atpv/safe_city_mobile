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
  });

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
    };
  }
}
