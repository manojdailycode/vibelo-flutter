class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final bool isPremium;
  final DateTime? premiumExpiry;
  final List<String> likedSongIds;
  final List<String> followedArtists;
  final String language; // 'en' or 'te'

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.isPremium = false,
    this.premiumExpiry,
    this.likedSongIds = const [],
    this.followedArtists = const [],
    this.language = 'en',
  });

  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiry == null) return false;
    return premiumExpiry!.isAfter(DateTime.now());
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? 'Vibelo User',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      isPremium: map['isPremium'] ?? false,
      premiumExpiry: map['premiumExpiry'] != null
          ? DateTime.parse(map['premiumExpiry'])
          : null,
      likedSongIds: List<String>.from(map['likedSongIds'] ?? []),
      followedArtists: List<String>.from(map['followedArtists'] ?? []),
      language: map['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'isPremium': isPremium,
      'premiumExpiry': premiumExpiry?.toIso8601String(),
      'likedSongIds': likedSongIds,
      'followedArtists': followedArtists,
      'language': language,
    };
  }

  UserModel copyWith({
    String? name,
    String? photoUrl,
    bool? isPremium,
    DateTime? premiumExpiry,
    List<String>? likedSongIds,
    String? language,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      likedSongIds: likedSongIds ?? this.likedSongIds,
      followedArtists: followedArtists,
      language: language ?? this.language,
    );
  }
}
