class LibraryModel {
  final int id;
  final String name;
  final String location;
  final List<BookItemModel> books;

  LibraryModel({
    int? id,
    required this.name,
    required this.location,
    required this.books,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch;

  factory LibraryModel.fromJson(Map<String, dynamic> json) => LibraryModel(
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

// 읽기 상태 상수
class ReadingStatus {
  static const String want = 'want';
  static const String reading = 'reading';
  static const String done = 'done';
  static const String stopped = 'stopped';

  static String label(String? status) {
    switch (status) {
      case want:
        return '읽고 싶은';
      case reading:
        return '읽고 있는';
      case done:
        return '다 읽은';
      case stopped:
        return '중단한';
      default:
        return '미분류';
    }
  }
}

class BookItemModel {
  final int id;
  final String title;
  final String author;
  final String? isbn;
  final String? description;
  final String? coverUrl;
  final String? detailUrl;
  final String? publisher;
  final int? pageCount;
  final String? readingStatus;
  final int? rating;
  final String? memo;
  final DateTime? dateAdded;

  BookItemModel({
    int? id,
    required this.title,
    required this.author,
    this.isbn,
    this.description,
    this.coverUrl,
    this.detailUrl,
    this.publisher,
    this.pageCount,
    this.readingStatus,
    this.rating,
    this.memo,
    DateTime? dateAdded,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch,
       dateAdded = dateAdded ?? DateTime.now();

  BookItemModel copyWith({
    String? title,
    String? author,
    String? isbn,
    String? description,
    String? coverUrl,
    String? detailUrl,
    String? publisher,
    int? pageCount,
    String? readingStatus,
    int? rating,
    String? memo,
    DateTime? dateAdded,
  }) {
    return BookItemModel(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      detailUrl: detailUrl ?? this.detailUrl,
      publisher: publisher ?? this.publisher,
      pageCount: pageCount ?? this.pageCount,
      readingStatus: readingStatus ?? this.readingStatus,
      rating: rating ?? this.rating,
      memo: memo ?? this.memo,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  factory BookItemModel.fromJson(Map<String, dynamic> json) => BookItemModel(
    id: json['id'],
    title: json['title'],
    author: json['author'],
    isbn: json['isbn'],
    description: json['description'],
    coverUrl: json['coverUrl'],
    detailUrl: json['detailUrl'],
    publisher: json['publisher'],
    pageCount: json['pageCount'],
    readingStatus: json['readingStatus'],
    rating: json['rating'],
    memo: json['memo'],
    dateAdded: json['dateAdded'] != null ? DateTime.tryParse(json['dateAdded']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'isbn': isbn,
    'description': description,
    'coverUrl': coverUrl,
    'detailUrl': detailUrl,
    'publisher': publisher,
    'pageCount': pageCount,
    'readingStatus': readingStatus,
    'rating': rating,
    'memo': memo,
    'dateAdded': dateAdded?.toIso8601String(),
  };
}
