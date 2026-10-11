class Attendee {
  final String id;
  final String name;
  final String avatarUrl;
  final String subtitle;
  final String followersCount;
  final List<double>? faceVector;
  final bool isCurrentUser;
  bool isFollowing;

  Attendee({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.subtitle,
    this.followersCount = '1.2K',
    this.faceVector,
    this.isCurrentUser = false,
    this.isFollowing = false,
  });

  Attendee copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? subtitle,
    String? followersCount,
    List<double>? faceVector,
    bool? isCurrentUser,
    bool? isFollowing,
  }) {
    return Attendee(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      subtitle: subtitle ?? this.subtitle,
      followersCount: followersCount ?? this.followersCount,
      faceVector: faceVector ?? this.faceVector,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
