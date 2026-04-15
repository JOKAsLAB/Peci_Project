class Topic {
  final String name;
  final int order;

  Topic({
    required this.name,
    required this.order,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}