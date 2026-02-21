import 'package:flutter/material.dart';
import 'package:homelibrary/screen/component/barcode.dart';

class Library extends StatelessWidget {
  const Library({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("책 관리"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const Barcode(),
                  ));
            },
            icon: const Icon(Icons.add),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: const Center(child: Column(children: [Text("adf")])),
    );
  }
}
