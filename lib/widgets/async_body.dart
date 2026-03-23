import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';

typedef AsyncBodyDataBuilder<T> = Widget Function(BuildContext context, T data);

Widget buildAsyncBody<T>({
  required BuildContext context,
  required AsyncSnapshot<T> snapshot,
  required AsyncBodyDataBuilder<T> onData,
}) {
  final l10n = AppLocalizations.of(context)!;
  if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: Text(l10n.loading));
  }
  if (snapshot.hasError) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.errorLoadFailed),
          const SizedBox(height: 8),
          Text(
            snapshot.error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  final data = snapshot.data;
  if (data == null) {
    return Center(child: Text(l10n.emptyState));
  }
  return onData(context, data);
}
