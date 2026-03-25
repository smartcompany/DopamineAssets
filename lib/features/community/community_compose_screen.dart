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
import '../../data/models/ranked_asset.dart';
import '../../theme/dopamine_theme.dart';

class CommunityComposeScreen extends StatefulWidget {
  const CommunityComposeScreen({
    super.key,
    this.initialSymbol,
    this.initialAssetClass,
  });

  final String? initialSymbol;
  final String? initialAssetClass;

  @override
  State<CommunityComposeScreen> createState() => _CommunityComposeScreenState();
}

class _CommunityComposeScreenState extends State<CommunityComposeScreen> {
  static const _maxImages = 6;

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _bodyFocusNode = FocusNode();

  String _assetClass = 'us_stock';
  RankedAsset? _selectedAsset;
  final List<XFile> _images = [];
  bool _submitting = false;

  static const _classes = <String>[
    'us_stock',
    'kr_stock',
    'crypto',
    'commodity',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.initialAssetClass?.trim();
    if (c != null && _classes.contains(c)) {
      _assetClass = c;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sug = context.read<HomeAssetSuggestions>();
      setState(() => _syncSelectionFromSuggestions(sug));
    });
    _bodyFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _syncSelectionFromSuggestions(HomeAssetSuggestions sug) {
    final sym = widget.initialSymbol?.trim();
    final list = sug.assetsForClass(_assetClass);
    if (sym != null && sym.isNotEmpty) {
      for (final a in list) {
        if (a.symbol == sym) {
          _selectedAsset = a;
          return;
        }
      }
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

  Future<void> _pickImages() async {
    if (_images.length >= _maxImages) return;
    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 82,
    );
    if (picked.isEmpty || !mounted) return;
    setState(() {
      for (final p in picked) {
        if (_images.length >= _maxImages) break;
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

    final sel = _selectedAsset;
    final body = _bodyController.text.trim();
    if (sel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityComposeNeedSymbol)),
      );
      return;
    }
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityComposeNeedBody)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = await fb.getIdToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.assetPostsSendError)),
          );
        }
        return;
      }

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

      final titleText = _titleController.text.trim();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _thumbnailStrip({EdgeInsetsGeometry padding =
      const EdgeInsets.fromLTRB(12, 4, 12, 8)}) {
    if (_images.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 76,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FutureBuilder<Uint8List>(
                  future: _images[i].readAsBytes(),
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
                      setState(() => _images.removeAt(i));
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
          onPressed: _images.length >= _maxImages ? null : _pickImages,
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
                  onPressed:
                      _images.length >= _maxImages ? null : _pickImages,
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(l10n.communityComposeTitle),
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
                    l10n.communityComposeSubmit,
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
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _assetClass = v;
                          final next = sug.assetsForClass(v);
                          _selectedAsset =
                              next.isNotEmpty ? next.first : null;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.communityComposeSymbolLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: DopamineTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                if (symbols.isEmpty)
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
                        isExpanded: true,
                        value: _matchingSelection(symbols),
                        hint: Text(
                          l10n.communityComposePickSymbol,
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
                        onChanged: (v) {
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
                    hintText: l10n.communityComposeTitleHint,
                    hintStyle: TextStyle(
                      color: DopamineTheme.textSecondary.withValues(alpha: 0.85),
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
                      color: DopamineTheme.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                          color: DopamineTheme.textPrimary,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          hintText: l10n.communityComposeBodyHint,
                          hintStyle: TextStyle(
                            color: DopamineTheme.textSecondary
                                .withValues(alpha: 0.75),
                            height: 1.35,
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
                            color: DopamineTheme.textSecondary
                                .withValues(alpha: 0.7),
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
    );
  }
}
