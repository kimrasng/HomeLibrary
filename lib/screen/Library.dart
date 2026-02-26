import 'package:flutter/material.dart';
import 'package:homelibrary/screen/component/addlibrary_dialog.dart';

class Library extends StatelessWidget {
  const Library({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("서재"),
        actions: [
          IconButton(
            onPressed: () async { await showDialog(context: context, builder: (context) => AddlibraryDialog());},
            icon: const Icon(Icons.add),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: const Center(child: Column(children: [Text("adf")])),
    );
  }
}
