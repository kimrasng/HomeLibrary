import 'package:flutter/material.dart';
import 'package:homelibrary/screen/component/barcode.dart';
import 'package:homelibrary/screen/component/addmanually.dart';

class AddDialog extends StatefulWidget {
  const AddDialog({super.key});

  @override
  State<AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("추가할 방법을 선택하세요"),
      actions: <Widget>[
        TextButton(onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const Addmanually()));
        }, child: Text("직접 추가하기")),
        TextButton(onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const Barcode()));
        }, child: Text("바코드로 추가하기")),
      ],
    );
  }
}
