class WatchlistFolder {
  final String id;
  final String name;
  final List<String> instrumentTokens;

  const WatchlistFolder({
    required this.id,
    required this.name,
    required this.instrumentTokens,
  });

  WatchlistFolder copyWith({
    String? id,
    String? name,
    List<String>? instrumentTokens,
  }) {
    return WatchlistFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      instrumentTokens: instrumentTokens ?? this.instrumentTokens,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'instrumentTokens': instrumentTokens,
  };

  factory WatchlistFolder.fromJson(Map<String, dynamic> json) => WatchlistFolder(
    id: json['id'] as String,
    name: json['name'] as String,
    instrumentTokens: (json['instrumentTokens'] as List<dynamic>).map((e) => e as String).toList(),
  );
}

class WatchlistGroup {
  final String id;
  final String name;
  final List<String> instrumentTokens;
  final List<WatchlistFolder> folders;
  final bool isDefault;

  const WatchlistGroup({
    required this.id,
    required this.name,
    required this.instrumentTokens,
    this.folders = const [],
    this.isDefault = false,
  });

  WatchlistGroup copyWith({
    String? id,
    String? name,
    List<String>? instrumentTokens,
    List<WatchlistFolder>? folders,
    bool? isDefault,
  }) {
    return WatchlistGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      instrumentTokens: instrumentTokens ?? this.instrumentTokens,
      folders: folders ?? this.folders,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'instrumentTokens': instrumentTokens,
    'folders': folders.map((e) => e.toJson()).toList(),
    'isDefault': isDefault,
  };

  factory WatchlistGroup.fromJson(Map<String, dynamic> json) {
    final rawTokens = json['symbols'] ?? json['instrumentTokens'] ?? json['tokens'] ?? [];
    final List<String> tokens = rawTokens is List
        ? rawTokens.map((e) => e.toString()).toList()
        : const [];

    final rawFolders = json['folders'];
    final List<WatchlistFolder> fList = rawFolders is List
        ? rawFolders
            .whereType<Map<String, dynamic>>()
            .map((e) => WatchlistFolder.fromJson(e))
            .toList()
        : const [];

    return WatchlistGroup(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Watchlist').toString(),
      instrumentTokens: tokens,
      folders: fList,
      isDefault: json['isDefault'] == true,
    );
  }
}
