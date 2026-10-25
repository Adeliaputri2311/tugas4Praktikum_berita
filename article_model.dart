
class Article {
  final String title;
  final String? description;
  final String? urlToImage;

  Article({
    required this.title,
    this.description,
    this.urlToImage,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? 'Tanpa Judul',
      description: json['description'],
      urlToImage: json['urlToImage'],
    );
  }

  get url => null;
}
