import 'package:flutter/material.dart';
import 'package:homelibrary/model/Library.dart';
import 'package:homelibrary/controller/controller.dart';

class AddlibraryDialog extends StatefulWidget {
  const AddlibraryDialog({super.key});

  @override
  State<AddlibraryDialog> createState() => _AddlibraryDialogState();
}

class _AddlibraryDialogState extends State<AddlibraryDialog> {
  final LibraryController _controller = LibraryController();
  String name = '';
  String location = '';

  Future<void> _addLibrary() async {
    if (name.isNotEmpty && location.isNotEmpty) {
      final newLibrary = LibraryModle(name: name, location: location, books: []);
      await _controller.addLibrary(newLibrary);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("서재 추가"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: "서재 이름",
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() {
              name = value;
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: "서재 위치",
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() {
              location = value;
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _addLibrary,
          child: const Text('추가'),
        ),
      ],
    );
  }
}
