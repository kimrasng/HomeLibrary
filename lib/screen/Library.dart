import 'package:flutter/material.dart';
import 'package:homelibrary/model/Library.dart';
import 'package:homelibrary/screen/component/addlibrary_dialog.dart';
import 'package:homelibrary/controller/controller.dart';
import 'package:homelibrary/screen/component/library_cupertino.dart';
import 'package:homelibrary/screen/book.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  final LibraryController _controller = LibraryController();
  late Future<List<LibraryModel>> _librariesFuture;

  @override
  void initState() {
    super.initState();
    _librariesFuture = _controller.loadLibraries();
  }

  void _refreshLibraries() {
    setState(() {
      _librariesFuture = _controller.loadLibraries();
    });
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddlibraryDialog(),
    );
    if (result == true) {
      _refreshLibraries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('서재'),
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_rounded),
            tooltip: '서재 추가',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<LibraryModel>>(
      future: _librariesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('오류! ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final libraries = snapshot.data!;
        libraries.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        return _buildLibraryList(libraries);
      },
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shelves,
                  size: 64,
                  color: colorScheme.outline,
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
                  '오른쪽 위 + 버튼으로 첫 서재를 만들어보세요',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.tonalIcon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('서재 추가'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Library list ─────────────────────────────────────────────────────

  Widget _buildLibraryList(List<LibraryModel> libraries) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Card.filled(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (int i = 0; i < libraries.length; i++) ...[
              _buildLibraryTile(libraries[i]),
              if (i < libraries.length - 1)
                const Divider(height: 1, indent: 72),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryTile(LibraryModel library) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.secondaryContainer,
        child: Icon(
          Icons.shelves,
          size: 20,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(
        library.name,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: library.location.isNotEmpty
          ? Text(
              library.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${library.books.length}권',
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              LibraryCupertino.showActionSheet(
                context,
                library,
                onDelete: () async {
                  await _controller.deleteLibrary(library.id);
                  _refreshLibraries();
                },
                onRename: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) =>
                        AddlibraryDialog(library: library),
                  );
                  if (result == true) {
                    _refreshLibraries();
                  }
                },
              );
            },
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Book(library: library),
          ),
        );
      },
    );
  }
}
