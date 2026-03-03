import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  final bool barcodeAutoAdd;

  const Settings(Set<bool> set, {super.key, required this.barcodeAutoAdd});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late bool _currentBarcodeAutoAdd;

  @override
  void initState() {
    super.initState();
    _currentBarcodeAutoAdd = widget.barcodeAutoAdd;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("설정")),
      body: Column(
        children: [
          Row(
            children: [
              const Text("바코드 자동 추가"),
              Switch(
                value: _currentBarcodeAutoAdd,
                onChanged: (bool value) {
                  setState(() {
                    _currentBarcodeAutoAdd = value;
                  });
                },
              )
            ],
          ),
          const Row(children: []),
        ],
      ),
    );
  }
}
