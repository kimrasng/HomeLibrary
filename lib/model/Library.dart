class Library {
  static int _nextid = 0;

  final int id;
  final String name;
  final String location;
  final List<BookItem> books;

  Library({
    int? id,
    required this.name,
    required this.location,
    required this.books
  }) : id = id ?? _nextid++;

  factory Library.fromJson(Map<String, dynamic> json) => Library(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      books: (json['books'] as List).map<BookItem>((e) => BookItem.fromJson(e)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name' : name,
    'location': location,
    'books' : books.map((e) => e.toJson()).toList(),
  };
}

class BookItem {
  static int _nextId = 0;
  final int id;
  final String title;
  final String author;
  final String? isbn;
  final String? description;
  final String? coverUrl;

  BookItem({
    int? id,
    required this.title,
    required this.author,
    this.isbn,
    this.description,
    this.coverUrl,
  }) : id = id ?? _nextId++;

  factory BookItem.fromJson(Map<String, dynamic> json) => BookItem(
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
