/// Used to store the display settings of a code.
class CodeDisplay {
  final bool pinned;
  final bool trashed;
  final int lastUsedAt;
  final int tapCount;

  CodeDisplay({
    this.pinned = false,
    this.trashed = false,
    this.lastUsedAt = 0,
    this.tapCount = 0,
  });

  // copyWith
  CodeDisplay copyWith({
    bool? pinned,
    bool? trashed,
    int? lastUsedAt,
    int? tapCount,
  }) {
    final bool updatedPinned = pinned ?? this.pinned;
    final bool updatedTrashed = trashed ?? this.trashed;
    final int updatedLastUsedAt = lastUsedAt ?? this.lastUsedAt;
    final int updatedTapCount = tapCount ?? this.tapCount;
    return CodeDisplay(
      pinned: updatedPinned,
      trashed: updatedTrashed,
      lastUsedAt: updatedLastUsedAt,
      tapCount: updatedTapCount,
    );
  }

  factory CodeDisplay.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CodeDisplay();
    }
    return CodeDisplay(
      pinned: json['pinned'] ?? false,
      trashed: json['trashed'] ?? false,
      lastUsedAt: json['lastUsedAt'] ?? 0,
      tapCount: json['tapCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pinned': pinned,
      'trashed': trashed,
      'lastUsedAt': lastUsedAt,
      'tapCount': tapCount,
    };
  }
}
