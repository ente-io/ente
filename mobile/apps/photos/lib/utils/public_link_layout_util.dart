String normalizePublicLinkLayout(String? layout) {
  if (layout == null ||
      layout.isEmpty ||
      layout == 'masonry' ||
      layout == 'continuous') {
    return 'masonry';
  }
  if (layout == 'grouped' || layout == 'trip') {
    return layout;
  }
  return 'masonry';
}
