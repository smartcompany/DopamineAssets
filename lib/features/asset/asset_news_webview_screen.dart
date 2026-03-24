import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/dopamine_theme.dart';

/// 뉴스 기사 URL을 앱 안에서 연다 (외부 브라우저로 나가지 않음).
class AssetNewsWebViewScreen extends StatefulWidget {
  const AssetNewsWebViewScreen({
    super.key,
    required this.url,
    this.pageTitle,
    this.userAgent,
  });

  final Uri url;
  final String? pageTitle;

  /// null이면 플랫폼 기본 UA (뉴스 등).
  final String? userAgent;

  static Future<void> open(
    BuildContext context, {
    required Uri url,
    String? pageTitle,
    String? userAgent,
  }) async {
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AssetNewsWebViewScreen(
          url: url,
          pageTitle: pageTitle,
          userAgent: userAgent,
        ),
      ),
    );
  }

  @override
  State<AssetNewsWebViewScreen> createState() => _AssetNewsWebViewScreenState();
}

class _AssetNewsWebViewScreenState extends State<AssetNewsWebViewScreen> {
  late final WebViewController _controller;
  var _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    unawaited(_startWebView());
  }

  Future<void> _startWebView() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    final ua = widget.userAgent?.trim();
    if (ua != null && ua.isNotEmpty) {
      await _controller.setUserAgent(ua);
    }
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (value) {
          if (mounted) {
            setState(() => _progress = value);
          }
        },
        onPageFinished: (_) {
          if (mounted) {
            setState(() => _progress = 100);
          }
        },
      ),
    );
    await _controller.loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DopamineTheme.purpleBottom,
      appBar: AppBar(
        title: Text(
          widget.pageTitle?.trim().isNotEmpty == true
              ? widget.pageTitle!.trim()
              : widget.url.host,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress > 0 ? _progress / 100 : null,
              minHeight: 2,
              backgroundColor: Colors.white12,
              color: DopamineTheme.neonGreen,
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
