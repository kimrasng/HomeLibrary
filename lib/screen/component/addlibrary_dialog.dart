import 'package:flutter/material.dart';
import 'package:homelibrary/model/Library.dart';
import 'package:homelibrary/controller/controller.dart';

class AddlibraryDialog extends StatefulWidget {
  final LibraryModle? library;

  const AddlibraryDialog({super.key, this.library});

  @override
  State<AddlibraryDialog> createState() => _AddlibraryDialogState();
}

class _AddlibraryDialogState extends State<AddlibraryDialog> {
  final LibraryController _controller = LibraryController();
  late TextEditingController _nameController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.library?.name ?? '');
    _locationController = TextEditingController(text: widget.library?.location ?? '');
  }

  Future<void> _addOrUpdateLibrary() async {
    final name = _nameController.text;
    final location = _locationController.text;

    if (name.isNotEmpty && location.isNotEmpty) {
      if (widget.library != null) {
        final updatedLibrary = LibraryModle(
          id: widget.library!.id,
          name: name,
          location: location,
          books: widget.library!.books,
        );
        await _controller.updateLibrary(updatedLibrary);
      } else {
        final newLibrary = LibraryModle(name: name, location: location, books: []);
        await _controller.addLibrary(newLibrary);
      }
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.library == null ? "서재 추가" : "서재 수정"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "서재 이름",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: "서재 위치",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _addOrUpdateLibrary,
          child: Text(widget.library == null ? '추가' : '수정'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
