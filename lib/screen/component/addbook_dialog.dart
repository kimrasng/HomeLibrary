import 'package:flutter/material.dart';
import 'package:homelibrary/screen/barcode.dart';
import 'package:homelibrary/screen/addmanually.dart';

class AddbookDialog extends StatefulWidget {
  const AddbookDialog({super.key});

  @override
  State<AddbookDialog> createState() => _AddbookDialogState();
}

class _AddbookDialogState extends State<AddbookDialog> {

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
