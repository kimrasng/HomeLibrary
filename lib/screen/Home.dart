import 'package:flutter/material.dart';
import 'package:homelibrary/model/Library.dart';
import '../controller/controller.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final LibraryController _controller = LibraryController();
  List<LibraryModel> _libraries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final libraries = await _controller.loadLibraries();
      setState(() {
        _libraries = libraries;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("데이터 로딩 중 오류 발생: \$e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  int get _totalBooks =>
      _libraries.fold(0, (sum, lib) => sum + lib.books.length);

  Map<String, int> get _statusCounts {
    final counts = <String, int>{
      ReadingStatus.want: 0,
      ReadingStatus.reading: 0,
      ReadingStatus.done: 0,
      ReadingStatus.stopped: 0,
    };
    for (final lib in _libraries) {
      for (final book in lib.books) {
        final status = book.readingStatus;
        if (status != null && counts.containsKey(status)) {
          counts[status] = counts[status]! + 1;
        }
      }
    }
    return counts;
  }

  List<BookItemModel> get _recentBooks {
    final allBooks = <BookItemModel>[];
    for (final lib in _libraries) {
      allBooks.addAll(lib.books);
    }
    allBooks.sort((a, b) {
      final aDate = a.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return allBooks.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _libraries.isEmpty
                  ? _buildEmptyState(colorScheme, textTheme)
                  : _buildDashboard(colorScheme, textTheme),
            ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.library_books_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 28),
                Text(
                  '아직 서재가 없습니다',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '서재 탭에서 첫 서재를 만들어보세요',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Dashboard ────────────────────────────────────────────────────────

  Widget _buildDashboard(ColorScheme colorScheme, TextTheme textTheme) {
    final statusCounts = _statusCounts;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar.medium(
          title: const Text('내 서재'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RichText(
              text: TextSpan(
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: '총 '),
                  TextSpan(
                    text: '$_totalBooks',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  const TextSpan(text: '권의 책을 보관하고 있어요'),
                ],
              ),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(top: 28)),

        // ── Status cards (horizontal scroll) ──
        SliverToBoxAdapter(
          child: _buildStatusRow(statusCounts, colorScheme, textTheme),
        ),
        const SliverPadding(padding: EdgeInsets.only(top: 32)),

        // ── Recent books ──
        SliverToBoxAdapter(
          child: _buildRecentBooksSection(colorScheme, textTheme),
        ),
        const SliverPadding(padding: EdgeInsets.only(top: 32)),

        // ── Library breakdown ──
        SliverToBoxAdapter(
          child: _buildLibraryBreakdownSection(colorScheme, textTheme),
        ),
        const SliverPadding(padding: EdgeInsets.only(top: 24)),
      ],
    );
  }

  // ── Status row (horizontal scroll) ───────────────────────────────────

  Widget _buildStatusRow(
    Map<String, int> statusCounts,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final items = [
      _StatusCardData(
        label: ReadingStatus.label(ReadingStatus.reading),
        count: statusCounts[ReadingStatus.reading] ?? 0,
        icon: Icons.menu_book_rounded,
        tint: colorScheme.primary,
      ),
      _StatusCardData(
        label: ReadingStatus.label(ReadingStatus.want),
        count: statusCounts[ReadingStatus.want] ?? 0,
        icon: Icons.bookmark_outline_rounded,
        tint: colorScheme.tertiary,
      ),
      _StatusCardData(
        label: ReadingStatus.label(ReadingStatus.done),
        count: statusCounts[ReadingStatus.done] ?? 0,
        icon: Icons.check_circle_outline_rounded,
        tint: colorScheme.secondary,
      ),
      _StatusCardData(
        label: ReadingStatus.label(ReadingStatus.stopped),
        count: statusCounts[ReadingStatus.stopped] ?? 0,
        icon: Icons.pause_circle_outline_rounded,
        tint: colorScheme.outline,
      ),
      _StatusCardData(
        label: '서재',
        count: _libraries.length,
        icon: Icons.shelves,
        tint: colorScheme.primary,
      ),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _buildStatusCard(items[index], colorScheme, textTheme),
      ),
    );
  }

  Widget _buildStatusCard(
    _StatusCardData data,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return SizedBox(
      width: 110,
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(data.icon, size: 22, color: data.tint),
              const Spacer(),
              Text(
                '${data.count}',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Recent books (horizontal scroll) ─────────────────────────────────

  Widget _buildRecentBooksSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final recentBooks = _recentBooks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '최근 추가된 책',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (recentBooks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card.filled(
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 36,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '아직 추가된 책이 없습니다',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: recentBooks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final book = recentBooks[index];
                return _buildRecentBookCard(book, colorScheme, textTheme);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentBookCard(
    BookItemModel book,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final hasCover = book.coverUrl != null && book.coverUrl!.isNotEmpty;

    return SizedBox(
      width: 130,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            SizedBox(
              width: 130,
              height: 160,
              child: hasCover
                  ? Image.network(
                      book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildBookPlaceholder(
                        colorScheme,
                        book.title,
                        textTheme,
                      ),
                    )
                  : _buildBookPlaceholder(colorScheme, book.title, textTheme),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                book.title,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                book.author,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookPlaceholder(
    ColorScheme colorScheme,
    String title,
    TextTheme textTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            title,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // ── Library breakdown ────────────────────────────────────────────────

  Widget _buildLibraryBreakdownSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '서재별 현황',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          Card.filled(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(_libraries.length, (index) {
                final lib = _libraries[index];
                final isLast = index == _libraries.length - 1;

                return Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.shelves,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      title: Text(
                        lib.name,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: lib.location.isNotEmpty
                          ? Text(lib.location)
                          : null,
                      trailing: Badge(
                        label: Text('${lib.books.length}권'),
                        backgroundColor: colorScheme.primary,
                        textColor: colorScheme.onPrimary,
                      ),
                    ),
                    if (!isLast)
                      const Divider(height: 1, indent: 56, endIndent: 16),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────

class _StatusCardData {
  final String label;
  final int count;
  final IconData icon;
  final Color tint;

  const _StatusCardData({
    required this.label,
    required this.count,
    required this.icon,
    required this.tint,
  });
}
