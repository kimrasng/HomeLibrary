import 'dart:convert';

import 'package:homelibrary/model/Library.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryController {
  static const String _libraryKey = 'library';

  Future<void> saveLibrary(Library library) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(library.toJson());
    await prefs.setString(_libraryKey, jsonString);
  }

  Future<Library?> loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_libraryKey);
    if (jsonString != null) {
      final jsonMap = jsonDecode(jsonString);
      return Library.fromJson(jsonMap);
    }
    return null;
  }

  Future<void> addBook(BookItem book) async {
    final library = await loadLibrary();
    if (library != null) {
      library.books.add(book);
      await saveLibrary(library);
    }
  }

  Future<void> updateBook(BookItem book) async {
    final library = await loadLibrary();
    if (library != null) {
      final index = library.books.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        library.books[index] = book;
        await saveLibrary(library);
      }
    }
  }

  Future<void> deleteBook(int bookId) async {
    final library = await loadLibrary();
    if (library != null) {
      library.books.removeWhere((b) => b.id == bookId);
      await saveLibrary(library);
    }
  }
}
