import 'package:flutter/material.dart';

class AddlibraryDialog extends StatefulWidget {
  const AddlibraryDialog({super.key});

  @override
  State<AddlibraryDialog> createState() => _AddlibraryDialogState();
}

class _AddlibraryDialogState extends State<AddlibraryDialog> {
  String name = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("서재 추가"),
      content: TextField(
        decoration: const InputDecoration(
          labelText: "서재 이름",
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => name,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            if (name.isNotEmpty) {
              Navigator.of(context).pop(name);
              debugPrint(name);
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
