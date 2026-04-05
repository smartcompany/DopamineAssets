import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_lib/share_lib.dart';

import '../../theme/dopamine_theme.dart';
import '../config/api_config.dart';

/// 홈 「오늘 가장 미친 상승」 4·5위 사이.
/// 서버: `ios_banner_ad`/`android_banner_ad` 가 가리키는 `ref` 키 → [AdService.bannerAdId].
class HomeRankingBannerAd extends StatefulWidget {
  const HomeRankingBannerAd({super.key});

  @override
  State<HomeRankingBannerAd> createState() => _HomeRankingBannerAdState();
}

/// 적응형 배너 로드 전·중 레이아웃 점프 완화 (대표 높이 ~50–90).
const double _kBannerPlaceholderHeight = 60;

class _HomeRankingBannerAdState extends State<HomeRankingBannerAd> {
  BannerAd? _banner;
  bool _loaded = false;
  bool _started = false;
  bool _slotDismissed = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _dismissSlot() {
    if (!mounted) return;
    setState(() => _slotDismissed = true);
  }

  Future<void> _load() async {
    if (kIsWeb || _started || !mounted) return;
    _started = true;

    try {
      AdService.shared.setBaseUrl(ApiConfig.baseUrl);
      final ok = await AdService.shared.loadSettings();
      if (!mounted) return;
      final id = AdService.shared.bannerAdId;
      if (!ok || id == null || id.isEmpty) {
        _dismissSlot();
        return;
      }

      final mq = MediaQuery.sizeOf(context);
      final width = (mq.width - 40).clamp(0, mq.width).truncate();

      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            width,
          );
      if (!mounted) return;
      if (size == null) {
        _dismissSlot();
        return;
      }

      final banner = BannerAd(
        adUnitId: id,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('[HomeRankingBannerAd] failed: $error');
            ad.dispose();
            _dismissSlot();
          },
        ),
      );

      await banner.load();
      if (!mounted) {
        banner.dispose();
        return;
      }
      setState(() => _banner = banner);
    } catch (e, st) {
      debugPrint('[HomeRankingBannerAd] load error: $e\n$st');
      _dismissSlot();
    }
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    if (_slotDismissed) {
      return const SizedBox.shrink();
    }

    if (_loaded && _banner != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Center(
          child: SizedBox(
            width: _banner!.size.width.toDouble(),
            height: _banner!.size.height.toDouble(),
            child: AdWidget(ad: _banner!),
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: _HomeRankingBannerPlaceholder(),
    );
  }
}

class _HomeRankingBannerPlaceholder extends StatelessWidget {
  const _HomeRankingBannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: _kBannerPlaceholderHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.ads_click_rounded,
              size: 22,
              color: DopamineTheme.accentOrange.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: DopamineTheme.accentOrange.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
