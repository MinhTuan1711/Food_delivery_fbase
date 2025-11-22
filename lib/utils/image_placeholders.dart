String generatePlaceholderImage(String seed,
    {int width = 600, int height = 400}) {
  final normalizedSeed = seed
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .trim()
      .replaceAll(RegExp(r'^-+|-+$'), '');

  final safeSeed = normalizedSeed.isEmpty ? 'food-item' : normalizedSeed;
  return 'https://picsum.photos/seed/$safeSeed/$width/$height';
}









