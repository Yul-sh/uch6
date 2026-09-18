int jsonInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

List<int> jsonIntList(dynamic value) {
  if (value is! List) return const [];
  return [for (final item in value) jsonInt(item)];
}

DateTime? jsonDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String jsonString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

String jsonId(dynamic value) {
  if (value == null) return '';
  if (value is Map) return jsonString(value['id']);
  return jsonString(value);
}

List<String> jsonIdList(dynamic value) {
  if (value is! List) return const [];
  return [for (final item in value) jsonId(item)]
      .where((e) => e.isNotEmpty)
      .toList();
}

/// PocketBase `isDeleted` bool → optional tombstone timestamp for UI.
DateTime? deletedAtFromPb(Map<String, dynamic> json) {
  if (json['deletedAt'] != null) return jsonDate(json['deletedAt']);
  final flag = json['isDeleted'];
  if (flag == true) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return null;
}

bool jsonBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
  }
  return fallback;
}
