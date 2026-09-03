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

  const WatchlistGroup({
    required this.id,
    required this.name,
    required this.instrumentTokens,
    this.folders = const [],
  });

  WatchlistGroup copyWith({
    String? id,
    String? name,
    List<String>? instrumentTokens,
    List<WatchlistFolder>? folders,
  }) {
    return WatchlistGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      instrumentTokens: instrumentTokens ?? this.instrumentTokens,
      folders: folders ?? this.folders,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'instrumentTokens': instrumentTokens,
    'folders': folders.map((e) => e.toJson()).toList(),
  };

  factory WatchlistGroup.fromJson(Map<String, dynamic> json) => WatchlistGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    instrumentTokens: (json['instrumentTokens'] as List<dynamic>).map((e) => e as String).toList(),
    folders: (json['folders'] as List<dynamic>?)
            ?.map((e) => WatchlistFolder.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}
