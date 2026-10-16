/// Helper utility to reliably unwrap data objects and lists from backend API response envelopes.
class ResponseReader {
  ResponseReader._();

  /// Extracts a List from [data].
  /// Accepts:
  /// - A bare `List`
  /// - A `Map` containing [key] (or 'items', 'list', etc.)
  /// - A nested `data` map containing [key] or 'items'
  static List<dynamic> list(dynamic data, [String? key]) {
    if (data == null) return const [];
    if (data is List) return data;

    if (data is Map) {
      if (key != null && data.containsKey(key)) {
        final val = data[key];
        if (val is List) return val;
        if (val is Map) return val.values.toList();
      }
      if (data.containsKey('items') && data['items'] is List) {
        return data['items'] as List;
      }
      if (data.containsKey('data')) {
        final nested = data['data'];
        if (nested is List) return nested;
        if (nested is Map) return list(nested, key);
      }
    }
    return const [];
  }

  /// Extracts an Object (Map) from [data].
  /// Accepts:
  /// - A `Map` containing [key]
  /// - A `Map` containing `data` -> [key]
  /// - The `Map` itself if no key is present or matching
  static Map<String, dynamic> object(dynamic data, [String? key]) {
    if (data == null) return const {};

    if (data is Map<String, dynamic>) {
      if (key != null && data.containsKey(key)) {
        final val = data[key];
        if (val is Map<String, dynamic>) return val;
        if (val is Map) return Map<String, dynamic>.from(val);
      }
      if (data.containsKey('data')) {
        final nested = data['data'];
        if (nested is Map<String, dynamic>) {
          if (key != null && nested.containsKey(key)) {
            final val = nested[key];
            if (val is Map<String, dynamic>) return val;
            if (val is Map) return Map<String, dynamic>.from(val);
          }
          return nested;
        } else if (nested is Map) {
          return Map<String, dynamic>.from(nested);
        }
      }
      return data;
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (key != null && map.containsKey(key)) {
        final val = map[key];
        if (val is Map) return Map<String, dynamic>.from(val);
      }
      return map;
    }
    return const {};
  }

  /// Unwraps the standard success envelope { "success": true, "data": ... }
  static dynamic unwrap(dynamic data) {
    if (data == null) return null;
    if (data is Map && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  /// Convenience alias for list()
  static List<dynamic> asList(dynamic data, [String? key]) => list(data, key);

  /// Convenience alias for object()
  static Map<String, dynamic> asMap(dynamic data, [String? key]) => object(data, key);
}
