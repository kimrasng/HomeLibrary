import 'package:flutter/material.dart';

import 'package:homelibrary/model/Library.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {

    int libraycount = 0;
    int bookcount = 0;

    return Scaffold(
      appBar: AppBar(title: const Text("홈"),),
      body: Center(
        child: Column(
          children: [
            Text("서재 $libraycount"),
            Text("책 $bookcount")
          ],
        ),
      ),
    );
  }
}
