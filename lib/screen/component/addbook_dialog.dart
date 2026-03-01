import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:homelibrary/controller/controller.dart';
import 'package:homelibrary/model/Library.dart';
import 'package:http/http.dart' as http;

class AddBookManuallyScreen extends StatefulWidget {
  final LibraryModle library;

  const AddBookManuallyScreen({super.key, required this.library});

  @override
  State<AddBookManuallyScreen> createState() => _AddBookManuallyScreenState();
}

class _AddBookManuallyScreenState extends State<AddBookManuallyScreen> {
  final LibraryController _controller = LibraryController();
  final _searchController = TextEditingController();

  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _error = '';

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
      _searchResults = [];
    });

    try {
      final clientId = dotenv.env["CLIENT_ID"];
      final clientSecret = dotenv.env["CLIENT_SECRET"];
      final uri = Uri.parse('https://openapi.naver.com/v1/search/book.json?query=$query&display=10');
      final res = await http.get(uri, headers: {
        'X-Naver-Client-Id': clientId!,
        'X-Naver-Client-Secret': clientSecret!
      });

      if (res.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _searchResults = json['items'] as List<dynamic>? ?? [];
          if (_searchResults.isEmpty) {
            _error = '검색 결과가 없습니다.';
          }
        });
      } else {
        setState(() {
          _error = '서버 오류: ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = '검색 실패: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBookDetailsDialog(Map<String, dynamic> book) {
    final title = book['title']?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ') ?? '제목 없음';
    final author = book['author']?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ') ?? '저자 없음';
    final imageUrl = book['image'] as String? ?? '';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("책 정보"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl.isNotEmpty)
                  Center(child: Image.network(imageUrl, height: 150, fit: BoxFit.contain)),
                const SizedBox(height: 16),
                Text('제목: $title', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('저자: $author'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
              },
              child: const Text("취소"),
            ),
            TextButton(
              onPressed: () async {
                final newBook = BookItemModel(
                  title: title,
                  author: author,
                  isbn: book['isbn'],
                  coverUrl: book['image'],
                  detailUrl: book['link'],
                );
                await _controller.addBook(widget.library.id, newBook);

                Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
                Navigator.of(context).pop(true); // 이전 화면으로 돌아가기
              },
              child: const Text("추가"),
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
        title: const Text('책 검색하여 추가'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: '책 이름 검색',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _searchBooks(value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchBooks(_searchController.text),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(child: Text(_error))
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final book = _searchResults[index];
                            final title = book['title']?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ') ?? '';
                            final author = book['author']?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ') ?? '';
                            final imageUrl = book['image'] as String? ?? '';

                            return ListTile(
                              leading: imageUrl.isNotEmpty
                                  ? Image.network(imageUrl, width: 50, fit: BoxFit.cover)
                                  : const Icon(Icons.book, size: 50),
                              title: Text(title),
                              subtitle: Text(author),
                              onTap: () {
                                _showBookDetailsDialog(book);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
