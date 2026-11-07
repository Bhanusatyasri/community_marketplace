class UserModel {
  final String id, name, email, phone, profileImage, location;
  final double rating;
  final int reviewCount;
  final bool online;

  const UserModel({required this.id, required this.name, required this.email, required this.phone, required this.profileImage, required this.location, required this.rating, required this.reviewCount, this.online=false});

  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      profileImage: data['profileImage'] as String? ?? '',
      location: data['location'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      online: data['online'] as bool? ?? false,
    );
  }
}
