import 'package:flutter/material.dart';
import 'package:homelibrary/model/Library.dart';
import 'package:homelibrary/controller/controller.dart';
import 'package:url_launcher/url_launcher.dart';

class BookDetailScreen extends StatefulWidget {
  final BookItemModel book;
  final int libraryId;

  const BookDetailScreen({
    super.key,
    required this.book,
    required this.libraryId,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final LibraryController _controller = LibraryController();
  late TextEditingController _memoController;
  late BookItemModel _book;
  bool _isModified = false;
  bool _descriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _memoController = TextEditingController(text: _book.memo ?? '');
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _updateBook(BookItemModel updated) async {
    setState(() {
      _book = updated;
      _isModified = true;
    });
    await _controller.updateBook(widget.libraryId, updated);
  }

  void _onStatusChanged(String status) {
    final updated = _book.copyWith(readingStatus: status);
    _updateBook(updated);
  }

  void _onRatingChanged(int star) {
    // Tap same star to clear: rebuild with rating null
    final BookItemModel updated;
    if (_book.rating == star) {
      updated = BookItemModel(
        id: _book.id,
        title: _book.title,
        author: _book.author,
        isbn: _book.isbn,
        description: _book.description,
        coverUrl: _book.coverUrl,
        detailUrl: _book.detailUrl,
        publisher: _book.publisher,
        pageCount: _book.pageCount,
        readingStatus: _book.readingStatus,
        rating: null,
        memo: _book.memo,
        dateAdded: _book.dateAdded,
      );
    } else {
      updated = _book.copyWith(rating: star);
    }
    _updateBook(updated);
  }

  void _onMemoSubmitted() {
    final text = _memoController.text.trim();
    final BookItemModel updated;
    if (text.isEmpty) {
      updated = BookItemModel(
        id: _book.id,
        title: _book.title,
        author: _book.author,
        isbn: _book.isbn,
        description: _book.description,
        coverUrl: _book.coverUrl,
        detailUrl: _book.detailUrl,
        publisher: _book.publisher,
        pageCount: _book.pageCount,
        readingStatus: _book.readingStatus,
        rating: _book.rating,
        memo: null,
        dateAdded: _book.dateAdded,
      );
    } else {
      updated = _book.copyWith(memo: text);
    }
    _updateBook(updated);
  }

  Future<void> _openDetailUrl() async {
    if (_book.detailUrl != null && _book.detailUrl!.isNotEmpty) {
      final url = Uri.parse(_book.detailUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('책 삭제'),
        content: Text('"${_book.title}"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _controller.deleteBook(widget.libraryId, _book.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && result == null && _isModified) {
          Navigator.of(context).maybePop(true);
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // --- SliverAppBar ---
            SliverAppBar(
              pinned: true,
              expandedHeight: 0,
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    Navigator.of(context).pop(_isModified ? true : null),
              ),
              elevation: 0,
              scrolledUnderElevation: 0.5,
            ),

            // --- Hero Cover Image ---
            SliverToBoxAdapter(
              child: _buildHeroCover(colorScheme),
            ),

            // --- Content ---
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Title & Author & Publisher ---
                    _buildBookInfo(textTheme, colorScheme),
                    const SizedBox(height: 28),

                    // --- Reading Status ---
                    _buildStatusChips(colorScheme, textTheme),
                    const SizedBox(height: 24),

                    // --- Star Rating ---
                    _buildStarRating(colorScheme, textTheme),
                    const SizedBox(height: 28),

                    // --- Memo ---
                    _buildMemoField(textTheme),
                    const SizedBox(height: 28),

                    // --- ISBN & Page Count ---
                    _buildMetadata(colorScheme),

                    // --- Description ---
                    if (_book.description != null &&
                        _book.description!.isNotEmpty)
                      _buildDescription(textTheme, colorScheme),

                    const SizedBox(height: 32),

                    // --- Action Buttons ---
                    _buildActions(colorScheme),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Cover ──────────────────────────────────────────────────────

  Widget _buildHeroCover(ColorScheme colorScheme) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Stack(
          children: [
            Positioned.fill(
              child: _book.coverUrl != null && _book.coverUrl!.isNotEmpty
                  ? Image.network(
                      _book.coverUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildCoverPlaceholder(colorScheme);
                      },
                    )
                  : _buildCoverPlaceholder(colorScheme),
            ),
            // Bottom gradient fade to surface
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.0),
                      colorScheme.surface.withValues(alpha: 0.6),
                      colorScheme.surface,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            '표지 없음',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Book Info ───────────────────────────────────────────────────────

  Widget _buildBookInfo(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _book.title,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _book.author,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (_book.publisher != null && _book.publisher!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _book.publisher!,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ],
    );
  }

  // ── Status Chips (M3 ChoiceChip) ────────────────────────────────────

  Widget _buildStatusChips(ColorScheme colorScheme, TextTheme textTheme) {
    final statuses = [
      ReadingStatus.want,
      ReadingStatus.reading,
      ReadingStatus.done,
      ReadingStatus.stopped,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '읽기 상태',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statuses.map((status) {
            final isSelected = _book.readingStatus == status;
            return ChoiceChip(
              label: Text(ReadingStatus.label(status)),
              selected: isSelected,
              onSelected: (_) => _onStatusChanged(status),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Star Rating ─────────────────────────────────────────────────────

  Widget _buildStarRating(ColorScheme colorScheme, TextTheme textTheme) {
    final currentRating = _book.rating ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '평점',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(5, (index) {
            final star = index + 1;
            final isFilled = star <= currentRating;
            return GestureDetector(
              onTap: () => _onRatingChanged(star),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFilled
                      ? colorScheme.tertiary
                      : colorScheme.outlineVariant,
                  size: 36,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Memo Field (M3 OutlinedTextField) ───────────────────────────────

  Widget _buildMemoField(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '한줄평',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _memoController,
          decoration: const InputDecoration(
            hintText: '이 책에 대한 한마디...',
            border: OutlineInputBorder(),
          ),
          maxLines: 1,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _onMemoSubmitted(),
          onTapOutside: (_) {
            FocusScope.of(context).unfocus();
            _onMemoSubmitted();
          },
        ),
      ],
    );
  }

  // ── Metadata (M3 Chip) ─────────────────────────────────────────────

  Widget _buildMetadata(ColorScheme colorScheme) {
    final hasIsbn = _book.isbn != null && _book.isbn!.isNotEmpty;
    final hasPageCount = _book.pageCount != null && _book.pageCount! > 0;

    if (!hasIsbn && !hasPageCount) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          if (hasIsbn)
            Chip(
              avatar: Icon(Icons.qr_code_rounded, size: 18, color: colorScheme.onSurfaceVariant),
              label: Text('ISBN ${_book.isbn!}'),
            ),
          if (hasPageCount)
            Chip(
              avatar: Icon(Icons.auto_stories_rounded, size: 18, color: colorScheme.onSurfaceVariant),
              label: Text('${_book.pageCount}쪽'),
            ),
        ],
      ),
    );
  }

  // ── Description (AnimatedCrossFade + Card.filled) ───────────────────

  Widget _buildDescription(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _descriptionExpanded = !_descriptionExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  '책 소개',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _descriptionExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: SizedBox(
            width: double.infinity,
            child: Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _book.description!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.7,
                  ),
                ),
              ),
            ),
          ),
          crossFadeState: _descriptionExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  // ── Action Buttons ──────────────────────────────────────────────────

  Widget _buildActions(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_book.detailUrl != null && _book.detailUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton.tonal(
              onPressed: _openDetailUrl,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('자세히 보기'),
            ),
          ),
        TextButton(
          onPressed: _confirmDelete,
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.error,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('삭제'),
        ),
      ],
    );
  }
}
