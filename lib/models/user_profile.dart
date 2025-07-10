class UserProfile {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final String? profileImageUrl;
  final String? address;
  final String? dateOfBirth;
  final String? emergencyContact;
  final DateTime? joinedAt;
  final bool isActive;
  final Map<String, dynamic>? additionalInfo;
  final List<dynamic>? duesHistory;

  UserProfile({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.profileImageUrl,
    this.address,
    this.dateOfBirth,
    this.emergencyContact,
    this.joinedAt,
    this.isActive = true,
    this.additionalInfo,
    this.duesHistory,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      name: data['name'] ?? data['displayName'],
      email: data['email'],
      phone: data['phone'] ?? data['phoneNumber'],
      role: data['role'] ?? 'Member',
      profileImageUrl: data['profileImageUrl'] ?? data['photoURL'],
      address: data['address'],
      dateOfBirth: data['dateOfBirth'],
      emergencyContact: data['emergencyContact'],
      joinedAt: data['joinedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['joinedAt'].millisecondsSinceEpoch)
          : null,
      isActive: data['isActive'] ?? true,
      additionalInfo: data['additionalInfo'],
      duesHistory: data['duesHistory'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'emergencyContact': emergencyContact,
      'isActive': isActive,
      'additionalInfo': additionalInfo,
      'duesHistory': duesHistory,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? profileImageUrl,
    String? address,
    String? dateOfBirth,
    String? emergencyContact,
    bool? isActive,
    Map<String, dynamic>? additionalInfo,
    List<dynamic>? duesHistory,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      joinedAt: joinedAt,
      isActive: isActive ?? this.isActive,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      duesHistory: duesHistory ?? this.duesHistory,
    );
  }

  String get displayName {
    return name ?? email?.split('@').first ?? 'Parish Member';
  }

  String get initials {
    if (name != null && name!.isNotEmpty) {
      final nameParts = name!.trim().split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else {
        return nameParts[0][0].toUpperCase();
      }
    }
    return 'PM'; // Parish Member
  }

  bool get hasProfileImage => profileImageUrl != null && profileImageUrl!.isNotEmpty;
} 