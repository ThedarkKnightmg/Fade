class Barber {
  const Barber({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviewCount,
    required this.yearsExperience,
    required this.imageUrl,
    required this.bio,
  });

  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int reviewCount;
  final int yearsExperience;
  final String imageUrl;
  final String bio;
}
