bool isSafeWebUrl(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  return (scheme == 'http' || scheme == 'https') && uri.host.trim().isNotEmpty;
}

Uri? parseSafeWebUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !isSafeWebUrl(uri)) return null;
  return uri;
}
