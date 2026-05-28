/// Generic wrapper for `PaginatedResultOf<T>` payloads from the API.
///
/// Matches the schema:
///   { pageIndex: int, pageSize: int, totalCount: int, data: T[] }
class PaginatedResult<T> {
  const PaginatedResult({
    required this.pageIndex,
    required this.pageSize,
    required this.totalCount,
    required this.data,
  });

  final int pageIndex;
  final int pageSize;
  final int totalCount;
  final List<T> data;

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawItems = (json['data'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => itemFromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
    return PaginatedResult<T>(
      pageIndex: ((json['pageIndex'] ?? 1) as num).toInt(),
      pageSize: ((json['pageSize'] ?? rawItems.length) as num).toInt(),
      totalCount: ((json['totalCount'] ?? rawItems.length) as num).toInt(),
      data: rawItems,
    );
  }
}
