import 'package:dopamine_assets/core/network/safe_web_view_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isSafeWebViewUrl', () {
    test('allows http and https URLs with hosts', () {
      expect(isSafeWebViewUrl(Uri.parse('https://example.com/news')), isTrue);
      expect(isSafeWebViewUrl(Uri.parse('http://example.com/news')), isTrue);
    });

    test('rejects non-web schemes', () {
      expect(isSafeWebViewUrl(Uri.parse('javascript:alert(1)')), isFalse);
      expect(isSafeWebViewUrl(Uri.parse('file:///etc/passwd')), isFalse);
      expect(isSafeWebViewUrl(Uri.parse('data:text/html,<h1>x</h1>')), isFalse);
      expect(isSafeWebViewUrl(Uri.parse('intent://scan/#Intent')), isFalse);
    });

    test('rejects relative and hostless URLs', () {
      expect(isSafeWebViewUrl(Uri.parse('/news/today')), isFalse);
      expect(isSafeWebViewUrl(Uri.parse('https:example.com/news')), isFalse);
    });
  });
}
