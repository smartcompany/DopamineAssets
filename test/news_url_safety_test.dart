import 'package:dopamine_assets/core/news_url_safety.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSafeWebUrl', () {
    test('accepts http and https URLs with hosts', () {
      expect(
        parseSafeWebUrl('https://example.com/article?id=1'),
        Uri.parse('https://example.com/article?id=1'),
      );
      expect(
        parseSafeWebUrl(' http://news.example/path '),
        Uri.parse('http://news.example/path'),
      );
    });

    test('rejects script, data, file, and custom-scheme URLs', () {
      expect(parseSafeWebUrl('javascript:alert(1)'), isNull);
      expect(parseSafeWebUrl('data:text/html,<script>alert(1)</script>'), isNull);
      expect(parseSafeWebUrl('file:///etc/passwd'), isNull);
      expect(parseSafeWebUrl('intent://scan/#Intent;scheme=zxing;end'), isNull);
    });

    test('rejects URLs without an http or https host', () {
      expect(parseSafeWebUrl('https:example.com/article'), isNull);
      expect(parseSafeWebUrl('//example.com/article'), isNull);
      expect(parseSafeWebUrl('/relative/article'), isNull);
      expect(parseSafeWebUrl(''), isNull);
    });
  });
}
