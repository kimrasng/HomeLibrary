import 'package:flutter/material.dart';
import 'package:homelibrary/model/Library.dart';
import 'package:homelibrary/controller/controller.dart';

class AddlibraryDialog extends StatefulWidget {
  final LibraryModel? library;

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
    _locationController =
        TextEditingController(text: widget.library?.location ?? '');
  }

  Future<void> _addOrUpdateLibrary() async {
    final name = _nameController.text;
    final location = _locationController.text;

    if (name.isNotEmpty && location.isNotEmpty) {
      if (widget.library != null) {
        final updatedLibrary = LibraryModel(
          id: widget.library!.id,
          name: name,
          location: location,
          books: widget.library!.books,
        );
        await _controller.updateLibrary(updatedLibrary);
      } else {
        final newLibrary =
            LibraryModel(name: name, location: location, books: []);
        await _controller.addLibrary(newLibrary);
      }
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.library != null;

    return AlertDialog(
      icon: Icon(isEditing ? Icons.edit : Icons.shelves),
      title: Text(isEditing ? '서재 수정' : '서재 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '서재 이름',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.bookmark),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: '서재 위치',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addOrUpdateLibrary(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _addOrUpdateLibrary,
          child: Text(isEditing ? '수정' : '추가'),
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
