import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/dopamine_theme.dart';

/// 뉴스·외부 URL을 앱 안 WebView로 연다. 상·하단 세이프 영역은 침범하지 않으며, 상단에는 뒤로가기만 겹친다.
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
    if (kIsWeb) {
      final launched = await launchUrl(url, webOnlyWindowName: '_blank');
      if (launched || !context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => _ExternalUrlFallbackScreen(
            url: url,
            pageTitle: pageTitle,
          ),
        ),
      );
      return;
    }
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

class _ExternalUrlFallbackScreen extends StatelessWidget {
  const _ExternalUrlFallbackScreen({required this.url, this.pageTitle});

  final Uri url;
  final String? pageTitle;

  @override
  Widget build(BuildContext context) {
    final title = pageTitle?.trim().isNotEmpty == true
        ? pageTitle!.trim()
        : url.host;

    return Scaffold(
      backgroundColor: DopamineTheme.purpleBottom,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                url.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DopamineTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => launchUrl(url, webOnlyWindowName: '_blank'),
                child: const Text('Open link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetNewsWebViewScreenState extends State<AssetNewsWebViewScreen> {
  WebViewController? _controller;
  var _progress = 0;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    _controller = WebViewController();
    unawaited(_startWebView());
  }

  Future<void> _startWebView() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    final ua = widget.userAgent?.trim();
    if (ua != null && ua.isNotEmpty) {
      await controller.setUserAgent(ua);
    }
    await controller.setNavigationDelegate(
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
    await controller.loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (kIsWeb || controller == null) {
      return _ExternalUrlFallbackScreen(
        url: widget.url,
        pageTitle: widget.pageTitle,
      );
    }
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final title = widget.pageTitle?.trim().isNotEmpty == true
        ? widget.pageTitle!.trim()
        : widget.url.host;

    return Scaffold(
      backgroundColor: DopamineTheme.purpleBottom,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: topInset,
                bottom: bottomInset,
              ),
              child: Semantics(
                label: title,
                child: WebViewWidget(controller: controller),
              ),
            ),
          ),
          if (_progress < 100)
            Positioned(
              left: 0,
              right: 0,
              top: topInset,
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress / 100 : null,
                minHeight: 2,
                backgroundColor: Colors.white12,
                color: DopamineTheme.neonGreen,
              ),
            ),
          Positioned(
            top: topInset + 6,
            left: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(10),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
