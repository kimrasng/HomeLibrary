import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:homelibrary/controller/controller.dart';
import 'package:homelibrary/model/Library.dart';
import 'package:http/http.dart' as http;

class Addmanually extends StatefulWidget {
  final LibraryModel library;

  const Addmanually({super.key, required this.library});

  @override
  State<Addmanually> createState() => _AddmanuallyState();
}

class _AddmanuallyState extends State<Addmanually> {
  final LibraryController _controller = LibraryController();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic>? _items;
  String _error = '';
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
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
      final restApiKey = dotenv.env["REST_API_KEY"];

      if (restApiKey == null) {
        setState(() {
          _error = 'API 키를 .env 파일에서 찾을 수 없습니다.';
        });
        return;
      }

      final uri =
          Uri.parse('https://dapi.kakao.com/v3/search/book?query=$text&size=50');

      final res = await http.get(uri, headers: {
        'Authorization': 'KakaoAK $restApiKey',
      });

      if (res.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(utf8.decode(res.bodyBytes));
        final items = json['documents'] as List<dynamic>?;

        if (items == null || items.isEmpty) {
          setState(() {
            _error = '책 정보를 찾을 수 없습니다.';
          });
          return;
        }

        setState(() {
          _items = items;
        });
      } else {
        setState(() {
          _error = '서버 오류 : ${res.statusCode}';
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

  void _showBookDetailsDialog(Map<String, dynamic> book) {
    final title = book['title'] ?? '제목 없음';
    final authorsList = book['authors'] as List<dynamic>? ?? [];
    final author = authorsList.join(', ');
    final publisher = book['publisher'] as String? ?? '';
    final imageUrl = book['thumbnail'] as String? ?? '';

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: SizedBox(
            height: 200,
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  )
                : SizedBox(
                    width: 140,
                    child: ColoredBox(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
          ),
          title: Text(
            title,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (author.isNotEmpty)
                Text(
                  author,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (publisher.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  publisher,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                final newBook = BookItemModel(
                  title: title,
                  author: author,
                  isbn: book['isbn'],
                  coverUrl: book['thumbnail'],
                  detailUrl: book['url'],
                  publisher: book['publisher'],
                  description: book['contents'],
                );
                await _controller.addBook(widget.library.id, newBook);

                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('책 검색')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '책 이름 또는 ISBN',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          setState(() {});
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (text) {
                _onSearchChanged(text);
                setState(() {});
              },
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: _AutoSearch(
              items: _items,
              error: _error,
              isLoading: _isLoading,
              onTapItem: _showBookDetailsDialog,
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
  final Function(Map<String, dynamic>) onTapItem;

  const _AutoSearch({
    required this.items,
    required this.error,
    required this.isLoading,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (items == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '검색어를 입력해주세요',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '제목, 저자, ISBN으로 검색할 수 있어요',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    if (items!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items!.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items![index];
        final title = item['title'] ?? '제목 없음';
        final imageUrl = item['thumbnail'];
        final authorsList = item['authors'] as List<dynamic>? ?? [];
        final author = authorsList.join(', ');
        final publisher = item['publisher'] ?? '';

        final subtitle = [
          if (author.isNotEmpty) author,
          if (publisher.isNotEmpty) publisher,
        ].join(' · ');

        return ListTile(
          leading: SizedBox(
            width: 48,
            height: 64,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: imageUrl != null && imageUrl.toString().isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 48,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    )
                  : ColoredBox(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ),
          title: Text(
            title,
            style: textTheme.bodyLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: subtitle.isNotEmpty
              ? Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => onTapItem(item),
        );
      },
    );
  }
}
