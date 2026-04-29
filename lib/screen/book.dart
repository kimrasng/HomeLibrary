import 'package:flutter/material.dart';
import 'package:homelibrary/controller/controller.dart';
import 'package:homelibrary/model/Library.dart';
import 'package:homelibrary/screen/barcode.dart';
import 'package:homelibrary/screen/addmanually.dart';
import 'package:homelibrary/screen/book_detail.dart';

class Book extends StatefulWidget {
  final LibraryModel library;

  const Book({super.key, required this.library});

  @override
  State<Book> createState() => _BookState();
}

class _BookState extends State<Book> {
  final LibraryController _controller = LibraryController();
  List<BookItemModel> _books = [];
  bool _isLoading = true;
  bool _isGridView = true;

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

      final books = currentLibrary.books;
      books.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddBookChoiceDialog() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search_rounded),
              title: const Text('검색해서 추가'),
              subtitle: const Text('제목이나 저자로 검색'),
              onTap: () async {
                Navigator.of(context).pop();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Addmanually(library: widget.library),
                  ),
                );
                if (result == true) {
                  _loadBooks();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner_rounded),
              title: const Text('바코드로 추가'),
              subtitle: const Text('ISBN 바코드 스캔'),
              onTap: () async {
                Navigator.of(context).pop();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          Barcode(library: widget.library)),
                );
                if (result == true) {
                  _loadBooks();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToDetail(BookItemModel book) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(
          book: book,
          libraryId: widget.library.id,
        ),
      ),
    );
    if (result == true) {
      _loadBooks();
    }
  }

  Color _statusColor(String? status, ColorScheme colorScheme) {
    switch (status) {
      case ReadingStatus.want:
        return colorScheme.tertiary;
      case ReadingStatus.reading:
        return colorScheme.primary;
      case ReadingStatus.done:
        return colorScheme.secondary;
      case ReadingStatus.stopped:
        return colorScheme.outline;
      default:
        return Colors.transparent;
    }
  }

  // ── Cover image builder ──────────────────────────────────────────────

  Widget _buildCoverImage(BookItemModel book, {double? width, double? height}) {
    final colorScheme = Theme.of(context).colorScheme;

    if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
      return Image.network(
        book.coverUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildCoverPlaceholder(
          book.title,
          colorScheme,
          width: width,
          height: height,
        ),
      );
    }
    return _buildCoverPlaceholder(
      book.title,
      colorScheme,
      width: width,
      height: height,
    );
  }

  Widget _buildCoverPlaceholder(
    String title,
    ColorScheme colorScheme, {
    double? width,
    double? height,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.menu_book_rounded,
            size: 32,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ── Grid item ────────────────────────────────────────────────────────

  Widget _buildGridItem(BookItemModel book) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusClr = _statusColor(book.readingStatus, colorScheme);
    final hasStatus =
        book.readingStatus != null && statusClr != Colors.transparent;

    return GestureDetector(
      onTap: () => _navigateToDetail(book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCoverImage(book),
                  if (hasStatus)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusClr.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ReadingStatus.label(book.readingStatus),
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.surface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── List item ────────────────────────────────────────────────────────

  Widget _buildListItem(BookItemModel book, {required bool isLast}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusClr = _statusColor(book.readingStatus, colorScheme);
    final hasStatus =
        book.readingStatus != null && statusClr != Colors.transparent;

    return Column(
      children: [
        ListTile(
          onTap: () => _navigateToDetail(book),
          leading: SizedBox(
            width: 52,
            height: 72,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildCoverImage(book, width: 52, height: 72),
            ),
          ),
          title: Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.3,
            ),
          ),
          subtitle: Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: hasStatus
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusClr.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ReadingStatus.label(book.readingStatus),
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: statusClr,
                    ),
                  ),
                )
              : null,
        ),
        if (!isLast) const Divider(height: 1, indent: 88, endIndent: 16),
      ],
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            '아직 책이 없습니다',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '책을 추가해서 서재를 채워보세요',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: _showAddBookChoiceDialog,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('책 추가'),
          ),
        ],
      ),
    );
  }

  // ── Book count header ────────────────────────────────────────────────

  Widget _buildBookCountHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        '${_books.length}권',
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.library.name),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
                key: ValueKey(_isGridView),
              ),
            ),
            tooltip: _isGridView ? '목록 보기' : '격자 보기',
          ),
          IconButton(
            onPressed: _showAddBookChoiceDialog,
            icon: const Icon(Icons.add_rounded),
            tooltip: '책 추가',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? _buildEmptyState()
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isGridView
                      ? _buildGridView()
                      : _buildListView(),
                ),
    );
  }

  Widget _buildGridView() {
    return CustomScrollView(
      key: const ValueKey('grid'),
      slivers: [
        SliverToBoxAdapter(child: _buildBookCountHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.55,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildGridItem(_books[index]),
              childCount: _books.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: _books.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildBookCountHeader();
        final bookIndex = index - 1;
        return _buildListItem(
          _books[bookIndex],
          isLast: bookIndex == _books.length - 1,
        );
      },
    );
  }
}
