class RecentMoveEntry {
  final String moveId;
  final String moveName;
  String? lastStat;
  int useCount;
  DateTime lastUsed;
  bool isFavorite;

  RecentMoveEntry({
    required this.moveId,
    required this.moveName,
    this.lastStat,
    this.useCount = 1,
    DateTime? lastUsed,
    this.isFavorite = false,
  }) : lastUsed = lastUsed ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'moveId': moveId,
      'moveName': moveName,
      'lastStat': lastStat,
      'useCount': useCount,
      'lastUsed': lastUsed.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory RecentMoveEntry.fromJson(Map<String, dynamic> json) {
    return RecentMoveEntry(
      moveId: json['moveId'],
      moveName: json['moveName'],
      lastStat: json['lastStat'],
      useCount: json['useCount'] ?? 1,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'])
          : DateTime.now(),
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}
