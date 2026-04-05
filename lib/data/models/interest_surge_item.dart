final class InterestSurgeItem {
  const InterestSurgeItem({
    required this.rank,
    required this.symbol,
    required this.name,
    required this.category,
    required this.score,
    this.scoreDelta,
    required this.snapshotDate,
  });

  final int rank;
  final String symbol;
  final String name;
  final String category;
  final double score;
  /// 전일(달력 기준) 스냅샷이 있을 때만 — `score - yesterdayScore`
  final double? scoreDelta;
  final String snapshotDate;

  factory InterestSurgeItem.fromJson(Map<String, dynamic> json) {
    final deltaRaw = json['scoreDelta'];
    final double? delta;
    if (deltaRaw == null) {
      delta = null;
    } else if (deltaRaw is num) {
      delta = deltaRaw.toDouble();
    } else {
      delta = double.tryParse('$deltaRaw');
    }
    return InterestSurgeItem(
      rank: (json['rank'] as num).toInt(),
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      category: (json['category'] as String).trim(),
      score: (json['score'] as num).toDouble(),
      scoreDelta: delta,
      snapshotDate: json['snapshotDate'] as String? ?? '',
    );
  }
}
