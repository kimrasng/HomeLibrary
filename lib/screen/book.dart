import 'package:flutter/material.dart';
import 'package:homelibrary/controller/controller.dart';
import 'package:homelibrary/model/Library.dart';
import 'package:homelibrary/screen/barcode.dart';
import 'package:homelibrary/screen/component/addbook_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class Book extends StatefulWidget {
  final LibraryModle library;

  const Book({super.key, required this.library});

  @override
  State<Book> createState() => _BookState();
}

class _BookState extends State<Book> {
  final LibraryController _controller = LibraryController();
  List<BookItemModel> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final libraries = await _controller.loadLibraries();
      final currentLibrary = libraries.firstWhere(
        (lib) => lib.id == widget.library.id,
      );
      setState(() {
        _books = currentLibrary.books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddBookChoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('책 추가 방법 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('검색해서 추가'),
              onTap: () async {
                Navigator.of(context).pop();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddBookManuallyScreen(library: widget.library),
                  ),
                );
                if (result == true) {
                  _loadBooks();
                }
              },
            ),
            ListTile(
              title: const Text('바코드로 추가'),
              onTap: () async {
                Navigator.of(context).pop();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Barcode()),
                );
                if (result != null) {
                  // Kakao API 필드명에 맞게 수정
                  final authorsList = result['authors'] as List<dynamic>? ?? [];
                  final author = authorsList.join(', ');
                  
                  final newBook = BookItemModel(
                    title: result['title'] ?? '제목 없음',
                    author: author,
                    isbn: result['isbn'],
                    coverUrl: result['thumbnail'],
                    detailUrl: result['url'],
                  );
                  await _controller.addBook(widget.library.id, newBook);
                  _loadBooks();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookDetail(BookItemModel book) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(book.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (book.coverUrl != null && book.coverUrl!.isNotEmpty)
                  Center(child: Image.network(book.coverUrl!, height: 150, fit: BoxFit.contain)),
                const SizedBox(height: 16),
                Text(book.author, style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if (book.detailUrl != null) {
                  final url = Uri.parse(book.detailUrl!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                }
              },
              child: const Text("자세히 보기"),
            ),
            TextButton(
              onPressed: () async {
                await _controller.deleteBook(widget.library.id, book.id);
                Navigator.of(dialogContext).pop();
                _loadBooks();
              },
              child: const Text("삭제", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("취소"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.library.name),
        actions: [
          IconButton(
            onPressed: _showAddBookChoiceDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? const Center(child: Text('책을 추가해주세요.'))
              : ListView.builder(
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return ListTile(
                      leading: book.coverUrl != null && book.coverUrl!.isNotEmpty
                          ? Image.network(
                              book.coverUrl!,
                              fit: BoxFit.cover,
                              width: 50,
                            )
                          : const Icon(Icons.book, size: 50),
                      title: Text(book.title),
                      subtitle: Text(book.author),
                      onTap: () {
                        _bookDetail(book);
                      },
                    );
                  },
                ),
    );
  }
}
