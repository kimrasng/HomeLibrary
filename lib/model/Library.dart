class LibraryModle {
  final int id;
  final String name;
  final String location;
  final List<BookItemModel> books;

  LibraryModle({
    int? id,
    required this.name,
    required this.location,
    required this.books,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch;

  factory LibraryModle.fromJson(Map<String, dynamic> json) => LibraryModle(
    id: json['id'],
    name: json['name'],
    location: json['location'],
    books: (json['books'] as List).map<BookItemModel>((e) => BookItemModel.fromJson(e)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'books': books.map((e) => e.toJson()).toList(),
  };
}

class BookItemModel {
  final int id;
  final String title;
  final String author;
  final String? isbn;
  final String? description;
  final String? coverUrl;

  BookItemModel({
    int? id,
    required this.title,
    required this.author,
    this.isbn,
    this.description,
    this.coverUrl,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch;

  factory BookItemModel.fromJson(Map<String, dynamic> json) => BookItemModel(
    id: json['id'],
    title: json['title'],
    author: json['author'],
    isbn: json['isbn'],
    description: json['description'],
    coverUrl: json['coverUrl'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'isbn': isbn,
    'description': description,
    'coverUrl': coverUrl,
  };
}
