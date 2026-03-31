import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../auth/present_dopamine_auth_screen.dart';
import '../../core/feed/home_asset_suggestions.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../core/storage/community_post_image_upload.dart';
import '../../core/text/ugc_banned_words.dart';
import '../../data/models/asset_comment.dart';
import '../../data/models/community_post.dart';
import '../../data/models/ranked_asset.dart';
import '../../data/models/theme_item.dart';
import '../../theme/dopamine_theme.dart';

// 글쓰기 본문 에디터 — 글자 크기·줄간격은 여기만 조정하면 됩니다.
abstract final class _CommunityComposeBodyFieldText {
  static const double fontSize = 16.0;
  static const double lineHeight = 1.4;
  static const double hintLineHeight = 1.35;
  static const double hintAlpha = 0.75;
}

/// [patch] 응답으로 목록·상세에 넘길 [CommunityPost]를 만듭니다.
CommunityPost _communityPostAfterPatch(
  AssetComment updated, {
  CommunityPost? base,
}) {
  if (base != null) {
    return CommunityPost(
      id: base.id,
      body: updated.body,
      title: updated.title,
      imageUrls: updated.imageUrls,
      authorUid: base.authorUid,
      authorDisplayName: updated.authorDisplayName,
      authorPhotoUrl: base.authorPhotoUrl,
      createdAt: base.createdAt,
      assetSymbol: base.assetSymbol,
      assetClass: base.assetClass,
      assetDisplayName: updated.assetDisplayName ?? base.assetDisplayName,
      replyCount: base.replyCount,
      likeCount: updated.likeCount,
      likedByMe: updated.likedByMe,
      moderationHiddenFromPublic: updated.moderationHiddenFromPublic,
    );
  }
  return CommunityPost(
    id: updated.id,
    body: updated.body,
    title: updated.title,
    imageUrls: updated.imageUrls,
    authorUid: updated.authorUid,
    authorDisplayName: updated.authorDisplayName,
    authorPhotoUrl: null,
    createdAt: updated.createdAt,
    assetSymbol: updated.assetSymbol ?? '',
    assetClass: updated.assetClass ?? 'us_stock',
    assetDisplayName: updated.assetDisplayName,
    replyCount: 0,
    likeCount: updated.likeCount,
    likedByMe: updated.likedByMe,
    moderationHiddenFromPublic: updated.moderationHiddenFromPublic,
  );
}

class CommunityComposeScreen extends StatefulWidget {
  const CommunityComposeScreen({
    super.key,
    this.initialSymbol,
    this.initialAssetClass,
    this.initialDisplayName,
    this.initialThemeId,
    this.editCommentId,
    this.editPrefill,
  });

  final String? initialSymbol;
  final String? initialAssetClass;

  /// [initialSymbol] 이 홈 랭킹 목록에 없을 때 표시명(예: 종목 상세에서 진입)
  final String? initialDisplayName;

  /// 테마 상세에서 진입 시 — 목록에서 동일 테마를 골라 둠
  final String? initialThemeId;

  /// 프로필 등에서 수정 시 — 전체 댓글을 GET으로 불러옴
  final String? editCommentId;

  /// 커뮤니티 목록에서 수정 시 — 동일 데이터로 GET 생략
  final CommunityPost? editPrefill;

  @override
  State<CommunityComposeScreen> createState() => _CommunityComposeScreenState();
}

class _CommunityComposeScreenState extends State<CommunityComposeScreen> {
  static const _maxImages = 6;

  /// 제목 필드와 동일한 한 줄 입력 높이(패딩) — 드롭다운 기본 터치 타깃 여백 제거용
  static const EdgeInsets _composeFieldContentPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 12,
  );

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _bodyFocusNode = FocusNode();

  String _assetClass = 'us_stock';
  RankedAsset? _selectedAsset;
  final List<XFile> _images = [];
  final List<String> _existingImageUrls = [];
  bool _submitting = false;

  bool _editLoading = false;
  bool _isReplyEdit = false;

  static const _classes = <String>[
    'us_stock',
    'kr_stock',
    'crypto',
    'commodity',
    'theme',
  ];

  List<ThemeItem>? _themeCatalog;
  bool _themeCatalogLoading = false;
  Object? _themeCatalogError;

  bool get _isEditMode =>
      widget.editPrefill != null || widget.editCommentId != null;

  String? get _effectiveEditId =>
      widget.editPrefill?.id ?? widget.editCommentId;

  bool get _lockAssetPick => _isEditMode && !_isReplyEdit;

  @override
  void initState() {
    super.initState();
    final c = widget.initialAssetClass?.trim();
    if (c != null && _classes.contains(c)) {
      _assetClass = c;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.editPrefill != null) {
        _applyCommunityPostPrefill(widget.editPrefill!);
      } else if (widget.editCommentId != null) {
        _loadEditComment();
      } else {
        final sug = context.read<HomeAssetSuggestions>();
        setState(() => _syncSelectionFromSuggestions(sug));
      }
      _loadThemeCatalog();
    });
    _bodyFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  RankedAsset _resolveAsset(
    HomeAssetSuggestions sug,
    String symbol,
    String assetClass,
    String? displayName,
  ) {
    final list = sug.assetsForClass(assetClass);
    for (final a in list) {
      if (a.symbol == symbol) return a;
    }
    return RankedAsset.communityShell(
      symbol: symbol,
      assetClass: assetClass,
      displayName: displayName,
    );
  }

  ThemeItem _legacyThemePickerRow(String name) {
    return ThemeItem(
      id: '__legacy__',
      name: name,
      avgChangePct: 0,
      volumeLiftPct: 0,
      symbolCount: 0,
      themeScore: 0,
      symbols: const <String>[],
      detailSymbol: '',
      detailAssetClass: 'us_stock',
    );
  }

  Future<void> _loadThemeCatalog() async {
    if (_themeCatalog != null) {
      if (_assetClass == 'theme' &&
          widget.editPrefill == null &&
          widget.editCommentId == null) {
        _applyInitialThemeSelection();
      }
      return;
    }
    if (_themeCatalogLoading) return;
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      _themeCatalogLoading = true;
      _themeCatalogError = null;
    });
    try {
      final hot = await DopamineApi.fetchThemes('hot', locale: lang);
      final crashed = await DopamineApi.fetchThemes('crashed', locale: lang);
      final emerging = await DopamineApi.fetchThemes('emerging', locale: lang);
      final byId = <String, ThemeItem>{};
      for (final t in [...hot, ...crashed, ...emerging]) {
        byId[t.id] = t;
      }
      final merged = byId.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _themeCatalog = merged;
        _themeCatalogLoading = false;
      });
      final editing =
          widget.editPrefill != null || widget.editCommentId != null;
      if (_assetClass == 'theme' && !editing) {
        _applyInitialThemeSelection();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _themeCatalogLoading = false;
        _themeCatalogError = e;
      });
    }
  }

  void _applyInitialThemeSelection() {
    if (!mounted || _assetClass != 'theme' || _themeCatalog == null) return;
    final editing = widget.editPrefill != null || widget.editCommentId != null;
    if (editing) return;
    final tid = widget.initialThemeId?.trim();
    final sym = widget.initialSymbol?.trim();
    final dn = widget.initialDisplayName?.trim();
    ThemeItem? found;
    if (tid != null && tid.isNotEmpty) {
      for (final t in _themeCatalog!) {
        if (t.id == tid) {
          found = t;
          break;
        }
      }
    }
    if (found == null && sym != null && sym.isNotEmpty) {
      for (final t in _themeCatalog!) {
        if (t.name == sym) {
          found = t;
          break;
        }
      }
    }
    if (found == null && dn != null && dn.isNotEmpty) {
      for (final t in _themeCatalog!) {
        if (t.name == dn) {
          found = t;
          break;
        }
      }
    }
    setState(() {
      if (found != null) {
        _selectedAsset = RankedAsset.communityShell(
          symbol: found.name,
          assetClass: 'theme',
          displayName: found.name,
        );
      } else if (sym != null && sym.isNotEmpty) {
        _selectedAsset = RankedAsset.communityShell(
          symbol: sym,
          assetClass: 'theme',
          displayName: dn ?? sym,
        );
      }
    });
  }

  List<ThemeItem> _themeRowsForDropdown() {
    final catalog = _themeCatalog ?? const <ThemeItem>[];
    final sel = _selectedAsset;
    if (sel != null &&
        sel.assetClass == 'theme' &&
        sel.symbol.trim().isNotEmpty &&
        !catalog.any((t) => t.name == sel.symbol)) {
      return [_legacyThemePickerRow(sel.symbol), ...catalog];
    }
    return List<ThemeItem>.from(catalog);
  }

  void _applyCommunityPostPrefill(CommunityPost p) {
    final sug = context.read<HomeAssetSuggestions>();
    setState(() {
      _isReplyEdit = false;
      _assetClass = p.assetClass;
      _titleController.text = p.title ?? '';
      _bodyController.text = p.body;
      _existingImageUrls
        ..clear()
        ..addAll(p.imageUrls);
      _images.clear();
      _selectedAsset = _resolveAsset(
        sug,
        p.assetSymbol,
        p.assetClass,
        p.assetDisplayName,
      );
    });
  }

  Future<void> _loadEditComment() async {
    setState(() => _editLoading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final fb = FirebaseAuth.instance.currentUser;
      if (fb == null) {
        if (mounted) Navigator.of(context).pop(false);
        return;
      }
      final token = await fb.getIdToken();
      if (token == null || token.isEmpty) {
        if (mounted) Navigator.of(context).pop(false);
        return;
      }
      final c = await DopamineApi.fetchAssetCommentById(
        id: widget.editCommentId!,
        idToken: token,
      );
      if (!mounted) return;
      final sug = context.read<HomeAssetSuggestions>();
      final sym = c.assetSymbol;
      final cls = c.assetClass;
      setState(() {
        _isReplyEdit = c.parentId != null;
        _titleController.text = c.title ?? '';
        _bodyController.text = c.body;
        _existingImageUrls
          ..clear()
          ..addAll(c.imageUrls);
        _images.clear();
        if (sym != null &&
            sym.isNotEmpty &&
            cls != null &&
            cls.isNotEmpty &&
            _classes.contains(cls)) {
          _assetClass = cls;
          _selectedAsset = _resolveAsset(sug, sym, cls, c.assetDisplayName);
        } else {
          _selectedAsset = null;
        }
        _editLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop(false);
    }
  }

  void _syncSelectionFromSuggestions(HomeAssetSuggestions sug) {
    final sym = widget.initialSymbol?.trim();
    if (_assetClass == 'theme') {
      _selectedAsset = null;
      return;
    }
    final list = sug.assetsForClass(_assetClass);
    if (sym != null && sym.isNotEmpty) {
      for (final a in list) {
        if (a.symbol == sym) {
          _selectedAsset = a;
          return;
        }
      }
      final dn = widget.initialDisplayName?.trim();
      _selectedAsset = RankedAsset.communityShell(
        symbol: sym,
        assetClass: _assetClass,
        displayName: (dn != null && dn.isNotEmpty) ? dn : sym,
      );
      return;
    }
    _selectedAsset = list.isNotEmpty ? list.first : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  String _classLabel(String code, AppLocalizations l10n) {
    switch (code) {
      case 'us_stock':
        return l10n.assetClassBadgeUsStock;
      case 'kr_stock':
        return l10n.assetClassBadgeKrStock;
      case 'crypto':
        return l10n.assetClassBadgeCrypto;
      case 'commodity':
        return l10n.assetClassBadgeCommodity;
      case 'theme':
        return l10n.assetClassBadgeTheme;
      default:
        return code;
    }
  }

  RankedAsset? _matchingSelection(List<RankedAsset> list) {
    if (_selectedAsset == null) return null;
    for (final a in list) {
      if (a.symbol == _selectedAsset!.symbol &&
          a.assetClass == _selectedAsset!.assetClass) {
        return a;
      }
    }
    return null;
  }

  String _extFromPath(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0 || i >= path.length - 1) return 'jpg';
    return path.substring(i + 1).toLowerCase();
  }

  String _mimeForExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  int get _totalImageCount => _existingImageUrls.length + _images.length;

  Future<void> _pickImages() async {
    if (_totalImageCount >= _maxImages) return;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 82);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      for (final p in picked) {
        if (_totalImageCount >= _maxImages) break;
        _images.add(p);
      }
    });
    if (mounted && !kIsWeb) {
      _bodyFocusNode.requestFocus();
    }
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      await presentDopamineAuthScreen(context);
      return;
    }

    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.communityComposeNeedBody)));
      return;
    }

    final badBody = UgcBannedWords.firstMatch(body);
    if (badBody != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ugcBannedWordsMessage(badBody))),
      );
      return;
    }
    final titleText = _titleController.text.trim();
    if (!_isReplyEdit && titleText.isNotEmpty) {
      final badTitle = UgcBannedWords.firstMatch(titleText);
      if (badTitle != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.ugcBannedWordsMessage(badTitle))),
        );
        return;
      }
    }

    final editId = _effectiveEditId;
    if (editId == null) {
      final sel = _selectedAsset;
      if (sel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityComposeNeedSymbol)),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final token = await fb.getIdToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.assetPostsSendError)));
        }
        return;
      }

      Future<List<String>> uploadNewPicks() async {
        final urls = <String>[];
        for (final x in _images) {
          final bytes = await x.readAsBytes();
          final ext = _extFromPath(x.path);
          final url = await uploadCommunityPostImage(
            idToken: token,
            bytes: bytes,
            filename: 'upload.$ext',
            contentType: _mimeForExt(ext),
          );
          urls.add(url);
        }
        return urls;
      }

      if (editId != null) {
        final newUrls = await uploadNewPicks();
        final allUrls = [..._existingImageUrls, ...newUrls];
        final updated = await DopamineApi.patchAssetComment(
          id: editId,
          body: body,
          title: _isReplyEdit ? null : (titleText.isEmpty ? null : titleText),
          imageUrls: allUrls,
          idToken: token,
        );
        if (!mounted) return;
        Navigator.of(context).pop(
          _communityPostAfterPatch(updated, base: widget.editPrefill),
        );
        return;
      }

      final sel = _selectedAsset!;
      final urls = await uploadNewPicks();
      final ac = sel.assetClass;
      if (ac == null || ac.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.communityComposeNeedSymbol)),
          );
        }
        return;
      }

      await DopamineApi.postAssetComment(
        symbol: sel.symbol,
        assetClass: ac,
        body: body,
        parentId: null,
        title: titleText.isEmpty ? null : titleText,
        imageUrls: urls.isEmpty ? null : urls,
        assetDisplayName: sel.name.trim().isEmpty ? null : sel.name.trim(),
        idToken: token,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.assetPostsSendError;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _thumbnailStrip({
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(12, 4, 12, 8),
  }) {
    final n = _existingImageUrls.length + _images.length;
    if (n == 0) return const SizedBox.shrink();
    return SizedBox(
      height: 76,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: n,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final existingCount = _existingImageUrls.length;
          if (i < existingCount) {
            final url = _existingImageUrls[i];
            return Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    url,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 72,
                      height: 72,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: const CircleBorder(),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: Colors.white,
                      onPressed: () {
                        setState(() => _existingImageUrls.removeAt(i));
                      },
                    ),
                  ),
                ),
              ],
            );
          }
          final j = i - existingCount;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FutureBuilder<Uint8List>(
                  future: _images[j].readAsBytes(),
                  builder: (context, snap) {
                    if (snap.hasData) {
                      return Image.memory(
                        snap.data!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      );
                    }
                    return Container(
                      width: 72,
                      height: 72,
                      color: Colors.white.withValues(alpha: 0.06),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DopamineTheme.neonGreen,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: const CircleBorder(),
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    color: Colors.white,
                    onPressed: () {
                      setState(() => _images.removeAt(j));
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _webBodyAddPhotoButton(AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 8, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _totalImageCount >= _maxImages ? null : _pickImages,
          icon: const Icon(
            Icons.add_photo_alternate_outlined,
            color: DopamineTheme.neonGreen,
          ),
          label: Text(
            l10n.communityComposeAddPhotoShort,
            style: theme.textTheme.labelLarge?.copyWith(
              color: DopamineTheme.neonGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobilePhotoChrome(AppLocalizations l10n, ThemeData theme) {
    // Keep primary focus on the body field so the bar stays visible while
    // tapping add-photo (IconButton would otherwise steal focus).
    return Focus(
      canRequestFocus: false,
      descendantsAreFocusable: false,
      child: Material(
        elevation: 6,
        color: const Color(0xFF15101C),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 8, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: _totalImageCount >= _maxImages
                      ? null
                      : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  color: DopamineTheme.neonGreen,
                  tooltip: l10n.communityComposeAddPhotoShort,
                ),
                Expanded(
                  child: Text(
                    l10n.communityComposeAddPhotoShort,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: DopamineTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sug = context.watch<HomeAssetSuggestions>();
    final symbols = sug.assetsForClass(_assetClass);

    if (_editLoading &&
        widget.editCommentId != null &&
        widget.editPrefill == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.communityComposeEditTitle)),
        body: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DopamineTheme.neonGreen,
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_submitting,
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
        title: Text(
          _isEditMode
              ? l10n.communityComposeEditTitle
              : l10n.communityComposeTitle,
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => _submit(l10n),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DopamineTheme.neonGreen,
                    ),
                  )
                : Text(
                    _isEditMode
                        ? l10n.communityComposeSave
                        : l10n.communityComposeSubmit,
                    style: const TextStyle(
                      color: DopamineTheme.neonGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                if (_isReplyEdit) ...[
                  Text(
                    l10n.communityComposeEditReplyTitle,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: DopamineTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_selectedAsset?.symbol ?? ''} · ${_classLabel(_assetClass, l10n)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: DopamineTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Text(
                    l10n.communityComposeAssetClassLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: DopamineTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InputDecorator(
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: _composeFieldContentPadding,
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isDense: true,
                        isExpanded: true,
                        value: _assetClass,
                        dropdownColor: const Color(0xFF1E1A28),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: DopamineTheme.textPrimary,
                        ),
                        items: [
                          for (final c in _classes)
                            DropdownMenuItem(
                              value: c,
                              child: Text(_classLabel(c, l10n)),
                            ),
                        ],
                        onChanged: _lockAssetPick
                            ? null
                            : (v) {
                                if (v == null) return;
                                setState(() {
                                  _assetClass = v;
                                  if (v == 'theme') {
                                    _selectedAsset = null;
                                    if (_themeCatalog != null) {
                                      _applyInitialThemeSelection();
                                    }
                                  } else {
                                    final next = sug.assetsForClass(v);
                                    _selectedAsset = next.isNotEmpty
                                        ? next.first
                                        : null;
                                  }
                                });
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _assetClass == 'theme'
                        ? l10n.communityComposeThemePickerLabel
                        : l10n.communityComposeSymbolLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: DopamineTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_assetClass == 'theme')
                    _themeCatalogError != null
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              l10n.errorLoadFailed,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: DopamineTheme.accentRed,
                              ),
                            ),
                          )
                        : _themeCatalogLoading && _themeCatalog == null
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DopamineTheme.neonGreen,
                                ),
                              ),
                            ),
                          )
                        : Builder(
                            builder: (ctx) {
                              final rows = _themeRowsForDropdown();
                              if (rows.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    l10n.emptyState,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: DopamineTheme.textSecondary,
                                    ),
                                  ),
                                );
                              }
                              final selName =
                                  _selectedAsset?.assetClass == 'theme' &&
                                      (_selectedAsset?.symbol ?? '')
                                          .trim()
                                          .isNotEmpty
                                  ? _selectedAsset!.symbol.trim()
                                  : null;
                              final names = rows.map((e) => e.name).toSet();
                              final value =
                                  selName != null && names.contains(selName)
                                  ? selName
                                  : null;
                              return InputDecorator(
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: _composeFieldContentPadding,
                                  filled: true,
                                  fillColor: Colors.black.withValues(
                                    alpha: 0.22,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    key: ValueKey<String>(
                                      rows.map((e) => e.id).join(','),
                                    ),
                                    isDense: true,
                                    isExpanded: true,
                                    value: value,
                                    hint: Text(
                                      l10n.communityComposePickTheme,
                                      style: TextStyle(
                                        color: DopamineTheme.textSecondary
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                    dropdownColor: const Color(0xFF1E1A28),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: DopamineTheme.textPrimary,
                                    ),
                                    items: [
                                      for (final t in rows)
                                        DropdownMenuItem<String>(
                                          value: t.name,
                                          child: Text(
                                            t.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                    onChanged: _lockAssetPick
                                        ? null
                                        : (String? v) {
                                            if (v == null) return;
                                            setState(() {
                                              _selectedAsset =
                                                  RankedAsset.communityShell(
                                                    symbol: v,
                                                    assetClass: 'theme',
                                                    displayName: v,
                                                  );
                                            });
                                          },
                                  ),
                                ),
                              );
                            },
                          )
                  else if (symbols.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.communityComposeNoRankedSymbols,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DopamineTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    )
                  else
                    InputDecorator(
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: _composeFieldContentPadding,
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<RankedAsset>(
                          key: ValueKey(_assetClass),
                          isDense: true,
                          isExpanded: true,
                          value: _matchingSelection(symbols),
                          hint: Text(
                            l10n.communityComposePickSymbol,
                            style: TextStyle(
                              color: DopamineTheme.textSecondary.withValues(
                                alpha: 0.85,
                              ),
                            ),
                          ),
                          dropdownColor: const Color(0xFF1E1A28),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: DopamineTheme.textPrimary,
                          ),
                          items: [
                            for (final a in symbols)
                              DropdownMenuItem(
                                value: a,
                                child: Text(
                                  '${a.symbol} · ${a.name}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _lockAssetPick
                              ? null
                              : (v) {
                                  if (v != null) {
                                    setState(() => _selectedAsset = v);
                                  }
                                },
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.communityComposeOptionalTitle,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: DopamineTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    maxLength: 200,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: DopamineTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: _composeFieldContentPadding,
                      hintText: l10n.communityComposeTitleHint,
                      hintStyle: TextStyle(
                        color: DopamineTheme.textSecondary.withValues(
                          alpha: 0.85,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      counterStyle: TextStyle(
                        color: DopamineTheme.textSecondary.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  l10n.communityComposeBodyLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: DopamineTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _bodyController,
                        focusNode: _bodyFocusNode,
                        minLines: 6,
                        maxLines: 14,
                        maxLength: 2000,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: _CommunityComposeBodyFieldText.fontSize,
                          color: DopamineTheme.textPrimary,
                          height: _CommunityComposeBodyFieldText.lineHeight,
                        ),
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          hintText: l10n.communityComposeBodyHint,
                          hintStyle: TextStyle(
                            fontSize: _CommunityComposeBodyFieldText.fontSize,
                            color: DopamineTheme.textSecondary.withValues(
                              alpha: _CommunityComposeBodyFieldText.hintAlpha,
                            ),
                            height: _CommunityComposeBodyFieldText.hintLineHeight,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.fromLTRB(
                            14,
                            14,
                            14,
                            8,
                          ),
                          counterStyle: TextStyle(
                            color: DopamineTheme.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                      _thumbnailStrip(),
                      if (kIsWeb) _webBodyAddPhotoButton(l10n, theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!kIsWeb && _bodyFocusNode.hasFocus)
            _mobilePhotoChrome(l10n, theme),
        ],
      ),
    ),
          if (_submitting)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DopamineTheme.neonGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
