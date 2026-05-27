bool isSafeWebViewUrl(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return false;
  return uri.host.trim().isNotEmpty;
}
