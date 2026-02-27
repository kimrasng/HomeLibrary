import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Addmanually extends StatefulWidget {
  const Addmanually({super.key});

  @override
  State<Addmanually> createState() => _AddmanuallyState();
}

class _AddmanuallyState extends State<Addmanually> {
  List<dynamic>? _items;
  String _error = '';
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(text);
    });
  }

  Future<void> _search(String text) async {
    if (text.isEmpty) {
      setState(() {
        _items = null;
        _error = '';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _items = null;
      _error = '';
    });

    try {
      final clientId = dotenv.env["N_CLIENT_ID"];
      final clientSecret = dotenv.env["N_CLIENT_SECRET"];

      if (clientId == null || clientSecret == null) {
        setState(() {
          _error = 'API 키를 .env 파일에서 찾을 수 없습니다.';
        });
        return;
      }

      final uri = Uri.parse('https://openapi.naver.com/v1/search/book.json?query=$text&display=50');

      final res = await http.get(uri, headers: {
        'X-Naver-Client-Id': clientId,
        'X-Naver-Client-Secret': clientSecret
      });

      if (res.statusCode == 200) {
        try {
          final Map<String, dynamic> json = jsonDecode(utf8.decode(res.bodyBytes));

          final items = json['items'] as List<dynamic>?;
          if (json['total'] == 0 || items == null || items.isEmpty) {
            setState(() {
              _error = '책 정보를 찾을 수 없습니다.';
            });
            return;
          }
          
          setState(() {
            _items = items;
          });
        } on FormatException {
          setState(() {
            _error = 'API 응답을 파싱하는데 실패했습니다. 응답: ${res.body}';
          });
        }
      } else {
        setState(() {
          _error = '서버 오류 : ${res.statusCode}\n${res.body}';
        });
      }
    } catch (e) {
      setState(() {
        _error = '요청 실패 : $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("수동으로 추가하기"),),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                  labelText: "책 이름 또는 ISBN", border: OutlineInputBorder()),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _AutoSearch(
              items: _items,
              error: _error,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoSearch extends StatelessWidget {
  final List<dynamic>? items;
  final String error;
  final bool isLoading;

  const _AutoSearch({
    required this.items,
    required this.error,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(error, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (items == null) {
      return const Center(child: Text('검색어를 입력해주세요.'));
    }
    
    if (items!.isEmpty) {
        return const Center(child: Text('검색 결과가 없습니다.'));
    }

    return ListView.builder(
      itemCount: items!.length,
      itemBuilder: (context, index) {
        final item = items![index];
        final title = item['title']?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '') ?? '제목 없음';
        final imageUrl = item['image'];
        final author = item['author']?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').replaceAll('^', ', ') ?? '저자 없음';
        final publisher = item['publisher']?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '') ?? '출판사 없음';

        return InkWell(
          onTap: () {
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null && imageUrl.toString().isNotEmpty)
                  Image.network(
                    imageUrl,
                    width: 80,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 120,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Text('이미지\n오류', textAlign: TextAlign.center),
                      );
                    },
                  )
                else
                  Container(
                    width: 80,
                    height: 120,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Text('이미지\n없음', textAlign: TextAlign.center),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text('저자: $author'),
                      const SizedBox(height: 4),
                      Text('출판사: $publisher'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}