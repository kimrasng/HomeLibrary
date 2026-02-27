import 'package:flutter/cupertino.dart';
import 'package:homelibrary/model/Library.dart';

class LibraryCupertino {
  static void showActionSheet(BuildContext context, LibraryModle library,
      {required VoidCallback onDelete, required VoidCallback onRename}) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('${library.name} 설정'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('이름 변경'),
            onPressed: () {
              Navigator.pop(context);
              onRename();
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text('삭제'),
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('취소'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
