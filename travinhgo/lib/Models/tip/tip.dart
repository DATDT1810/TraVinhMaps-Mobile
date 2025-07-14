class Tip {
  final String id;
  final String title;
  final String content;
  final String tagId;

  Tip(
      {required this.id,
      required this.title,
      required this.content,
      required this.tagId});

  factory Tip.fromJson(Map<String, dynamic> json) {
    return Tip(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      tagId: json['tagId'],
    );
  }
}
