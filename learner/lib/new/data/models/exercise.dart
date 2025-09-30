class Exercise {
  final String title;
  final String duration;
  final String imagePath;
  final Function() onTap;

  Exercise({
    required this.title,
    required this.duration,
    required this.imagePath,
    required this.onTap,
  });
}