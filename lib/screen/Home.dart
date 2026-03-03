import 'package:flutter/material.dart';
import '../controller/controller.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final LibraryController _controller = LibraryController();
  int _libraryCount = 0;
  int _bookCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final libraries = await _controller.loadLibraries();
      int totalBooks = 0;
      for (var library in libraries) {
        totalBooks += library.books.length;
      }

      setState(() {
        _libraryCount = libraries.length;
        _bookCount = totalBooks;
      });
    } catch (e) {
      debugPrint("데이터 로딩 중 오류 발생: \$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("홈"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("서재 $_libraryCount 개"), Text("책 $_bookCount권")],
        ),
      ),
    );
  }
}
