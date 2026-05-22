class PagedResponse<T> {
  PagedResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
  });

  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;

  bool get hasMore => number + 1 < totalPages;

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawContent = json['content'] as List<dynamic>? ?? [];
    return PagedResponse(
      content: rawContent
          .map((e) => itemFromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int? ?? rawContent.length,
      totalPages: json['totalPages'] as int? ?? 1,
      number: json['number'] as int? ?? 0,
      size: json['size'] as int? ?? rawContent.length,
    );
  }

  factory PagedResponse.fromDynamic(
    dynamic json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) =>
      PagedResponse.fromJson(json as Map<String, dynamic>, itemFromJson);
}
