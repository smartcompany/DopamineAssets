import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/dopamine_theme.dart';
import 'giphy_api.dart';

/// GIPHY 검색·트렌딩 피커. 선택 시 GIPHY CDN `https` GIF URL만 `pop`합니다 (Supabase 업로드 없음).
Future<String?> showGiphyPickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _GiphyPickerBody(),
  );
}

class _GiphyPickerBody extends StatefulWidget {
  const _GiphyPickerBody();

  @override
  State<_GiphyPickerBody> createState() => _GiphyPickerBodyState();
}

class _GiphyPickerBodyState extends State<_GiphyPickerBody> {
  static const _pageSize = 24;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  final _items = <GiphyGifSummary>[];
  bool _loading = true;
  bool _loadingMore = false;
  String? _errorCode;
  int _offset = 0;
  bool _hasMore = true;
  String _activeQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading || _loadingMore) return;
    final pos = _scrollController.position;
    if (!pos.hasPixels) return;
    if (pos.pixels > pos.maxScrollExtent - 480) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _errorCode = null;
      _items.clear();
      _offset = 0;
      _hasMore = true;
    });
    try {
      final list = _activeQuery.isEmpty
          ? await giphyFetchTrending(limit: _pageSize, offset: 0)
          : await giphyFetchSearch(
              query: _activeQuery,
              limit: _pageSize,
              offset: 0,
            );
      if (!mounted) return;
      setState(() {
        _items.addAll(list);
        _offset = list.length;
        _hasMore = list.length >= _pageSize;
        _loading = false;
      });
    } on GiphyApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorCode = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorCode = 'unknown';
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final list = _activeQuery.isEmpty
          ? await giphyFetchTrending(limit: _pageSize, offset: _offset)
          : await giphyFetchSearch(
              query: _activeQuery,
              limit: _pageSize,
              offset: _offset,
            );
      if (!mounted) return;
      setState(() {
        _items.addAll(list);
        _offset += list.length;
        if (list.length < _pageSize) _hasMore = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final next = v.trim();
      if (next == _activeQuery) return;
      setState(() => _activeQuery = next);
      _loadInitial();
    });
  }

  void _onSelect(GiphyGifSummary g) {
    final l10n = AppLocalizations.of(context)!;
    if (g.downloadSizeBytes != null &&
        g.downloadSizeBytes! > kGiphyMaxDownloadBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityComposeGiphyTooLarge)),
      );
      return;
    }
    final u = g.downloadUrl.trim();
    if (!u.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityComposeGiphyDownloadError)),
      );
      return;
    }
    Navigator.of(context).pop(u);
  }

  Future<void> _openGiphySite() async {
    final u = Uri.parse('https://giphy.com');
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final h = MediaQuery.sizeOf(context).height * 0.88;

    return Material(
      color: const Color(0xFF15101C),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: h,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DopamineTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.communityComposeGiphySearchHint,
                      hintStyle: TextStyle(
                        color: DopamineTheme.textSecondary.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: DopamineTheme.textSecondary,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: DopamineTheme.neonGreen,
                          width: 1.2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildGrid(l10n)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: GestureDetector(
                    onTap: _openGiphySite,
                    child: Text(
                      l10n.communityComposeGiphyPoweredBy,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: DopamineTheme.textSecondary.withValues(
                          alpha: 0.85,
                        ),
                        decoration: TextDecoration.underline,
                        decorationColor: DopamineTheme.textSecondary
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(AppLocalizations l10n) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DopamineTheme.neonGreen,
          ),
        ),
      );
    }
    if (_errorCode != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorCode == 'rate_limited'
                    ? l10n.communityComposeGiphyRateLimited
                    : l10n.communityComposeGiphyLoadError,
                textAlign: TextAlign.center,
                style: TextStyle(color: DopamineTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadInitial,
                child: Text(l10n.communityComposeGiphyRetry),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          l10n.communityComposeGiphyEmpty,
          style: TextStyle(color: DopamineTheme.textSecondary),
        ),
      );
    }
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: _items.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= _items.length) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: DopamineTheme.neonGreen,
              ),
            ),
          );
        }
        final g = _items[i];
        return Material(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _onSelect(g),
            child: Image.network(
              g.previewUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DopamineTheme.neonGreen.withValues(alpha: 0.8),
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (c, error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    l10n.communityComposeGiphyThumbError,
                    textAlign: TextAlign.center,
                    style: Theme.of(c).textTheme.labelSmall?.copyWith(
                      color: DopamineTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
