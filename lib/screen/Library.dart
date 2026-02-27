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
  late Future<List<LibraryModle>> _librariesFuture;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("서재"),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => const AddlibraryDialog(),
              );

              if (result == true) {
                _refreshLibraries();
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: libraryListView(),
    );
  }

  Widget libraryListView() {
    return FutureBuilder<List<LibraryModle>>(
      future: _librariesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('오류! ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('서재를 추가해주세요.'));
        }

        final libraries = snapshot.data!;
        return ListView.builder(
          itemCount: libraries.length,
          itemBuilder: (context, index) {
            final library = libraries[index];
            return Card(
              child: ListTile(
                title: Text(library.name),
                subtitle: Text(library.location),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
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
                          builder: (context) => AddlibraryDialog(library: library),
                        );
                        if (result == true) {
                          _refreshLibraries();
                        }
                      },
                    );
                  },
                ),
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const Book()));
                },
              ),
            );
          },
        );
      },
    );
  }
}
