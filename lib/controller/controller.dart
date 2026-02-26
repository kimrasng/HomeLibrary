import 'dart:convert';

import 'package:homelibrary/model/Library.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryController {
  static const String _libraryKey = 'libraries'; // Key for storing a list of libraries

  // Saves a list of libraries to SharedPreferences
  Future<void> saveLibraries(List<LibraryModle> libraries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(libraries.map((lib) => lib.toJson()).toList());
    await prefs.setString(_libraryKey, jsonString);
  }

  // Loads a list of libraries from SharedPreferences
  Future<List<LibraryModle>> loadLibraries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_libraryKey);
    if (jsonString != null) {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((jsonMap) => LibraryModle.fromJson(jsonMap)).toList();
    }
    return []; // Return an empty list if no libraries are found
  }

  // Adds a new library to the list
  Future<void> addLibrary(LibraryModle newLibrary) async {
    final libraries = await loadLibraries();
    libraries.add(newLibrary);
    await saveLibraries(libraries);
  }

  Future<void> addBook(int libraryId, BookItemModel book) async {
    final libraries = await loadLibraries();
    final libraryIndex = libraries.indexWhere((lib) => lib.id == libraryId);
    if (libraryIndex != -1) {
      libraries[libraryIndex].books.add(book);
      await saveLibraries(libraries);
    }
  }

  Future<void> updateBook(int libraryId, BookItemModel book) async {
    final libraries = await loadLibraries();
    final libraryIndex = libraries.indexWhere((lib) => lib.id == libraryId);
    if (libraryIndex != -1) {
      final bookIndex = libraries[libraryIndex].books.indexWhere((b) => b.id == book.id);
      if (bookIndex != -1) {
        libraries[libraryIndex].books[bookIndex] = book;
        await saveLibraries(libraries);
      }
    }
  }

  Future<void> deleteBook(int libraryId, int bookId) async {
    final libraries = await loadLibraries();
    final libraryIndex = libraries.indexWhere((lib) => lib.id == libraryId);
    if (libraryIndex != -1) {
      libraries[libraryIndex].books.removeWhere((b) => b.id == bookId);
      await saveLibraries(libraries);
    }
  }
}
