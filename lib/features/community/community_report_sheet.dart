import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/dopamine_theme.dart';

/// LetsMeet `UGCModeration._showReportSheet` 와 동일한 흐름: 사유 라디오 + 선택 상세 + 제출.
/// 취소 시 `null`, 제출 시 API용 문자열(선택 사유 + 줄바꿈 + 상세).
Future<String?> showCommunityReportSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  CommunityReportReason? selected;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.communityReportSheetTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.communityReportSheetSubtitle,
                        style: TextStyle(
                          color: DopamineTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final r in CommunityReportReason.values)
                            ChoiceChip(
                              label: Text(r.label(l10n)),
                              selected: selected == r,
                              onSelected: (_) =>
                                  setModalState(() => selected = r),
                              selectedColor: DopamineTheme.neonGreen
                                  .withValues(alpha: 0.22),
                              checkmarkColor: DopamineTheme.neonGreen,
                              labelStyle: TextStyle(
                                color: selected == r
                                    ? DopamineTheme.neonGreen
                                    : DopamineTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              side: BorderSide(
                                color: selected == r
                                    ? DopamineTheme.neonGreen
                                        .withValues(alpha: 0.65)
                                    : Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: l10n.communityReportDetailHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: selected == null
                              ? null
                              : () => Navigator.of(ctx).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: DopamineTheme.neonGreen,
                            foregroundColor: const Color(0xFF0A0A0A),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            l10n.communityReportSubmitButton,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );

  String? out;
  if (result == true && selected != null) {
    final category = selected!.label(l10n);
    final detail = controller.text.trim();
    out = detail.isEmpty ? category : '$category\n$detail';
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.dispose();
  });
  return out;
}

enum CommunityReportReason {
  spam,
  abuse,
  sexual,
  violence,
  other;

  String label(AppLocalizations l10n) {
    switch (this) {
      case CommunityReportReason.spam:
        return l10n.communityReportReasonSpam;
      case CommunityReportReason.abuse:
        return l10n.communityReportReasonAbuse;
      case CommunityReportReason.sexual:
        return l10n.communityReportReasonSexual;
      case CommunityReportReason.violence:
        return l10n.communityReportReasonViolence;
      case CommunityReportReason.other:
        return l10n.communityReportReasonOther;
    }
  }
}
