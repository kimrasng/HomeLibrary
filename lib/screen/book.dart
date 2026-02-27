import 'package:flutter/material.dart';
import 'package:homelibrary/screen/component/addbook_dialog.dart';

class Book extends StatelessWidget {
  const Book({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('책'),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AddbookDialog();
                },
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(children: []),
    );
  }
}
