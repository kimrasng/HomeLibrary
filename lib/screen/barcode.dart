import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Barcode extends StatefulWidget {
  const Barcode({super.key});

  @override
  State<Barcode> createState() => _BarcodeState();
}

class _BarcodeState extends State<Barcode> {

  Map<String, dynamic>? _item;
  String _error = '';

  final MobileScannerController _controller = MobileScannerController();

  Future<void> _ISBNSearch(String text) async {
    if (text.isEmpty) {
      setState(() {
        _item = null;
        _error = '';
      });
      return;
    }

    setState(() {
      _item = null;
      _error = '';
    });

    try {
      final clientId = dotenv.env["CLIENT_ID"];
      final clientSecret = dotenv.env["CLIENT_SECRET"];

      if (clientId == null || clientSecret == null) {
        setState(() {
            _error = 'API 키를 .env 파일에서 찾을 수 없습니다.';
        });
        return;
      }

      final uri = Uri.parse('https://openapi.naver.com/v1/search/book.json?query=$text&display=1');

      final res = await http.get(uri, headers: {
        'X-Naver-Client-Id': clientId,
        'X-Naver-Client-Secret': clientSecret
      });
      
      if (res.statusCode == 200) {
        try {
          final Map<String, dynamic> json = jsonDecode(utf8.decode(res.bodyBytes));

          final items = json['items'] as List<dynamic>?;
          if (json['total'] == 0 || items == null || items.isEmpty) {
            setState(() {
              _error = '책 정보를 찾을 수 없습니다.';
            });
            return;
          }

          final Map<String, dynamic> item = items.first as Map<String, dynamic>;

          setState(() {
            _item = item;
          });
        } on FormatException {
            setState(() {
              _error = 'API 응답을 파싱하는데 실패했습니다. 응답: ${res.body}';
            });
        }
      } else {
        setState(() {
          _error = '서버 오류 : ${res.statusCode}\n${res.body}';
        });
      }
    } catch (e) {
      setState(() {
        _error = '요청 실패 : $e';
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(const Offset(0, -50)),
      width: 250,
      height: 200,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('바코드 스캔')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            scanWindow: scanWindow,
            onDetect: (capture) async {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                _controller.stop();
                final barcodeValue = barcodes.first.rawValue;

                if (barcodeValue == null) {
                  _controller.start();
                  return;
                }

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                await _ISBNSearch(barcodeValue);

                Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

                if (!mounted) return;

                if (_error.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('오류'),
                      content: Text(_error),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _controller.start();
                          },
                          child: const Text('확인'),
                        )
                      ],
                    )
                  );
                  return;
                }

                if (_item != null) {
                  final item = _item!;
                  final imageUrl = item['image'] ?? '';
                  final title = item['title']?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ') ?? '제목 없음';
                  final author = item['author']?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ') ?? '저자 없음';

                  final dialogResult = await showDialog<Map<String, dynamic>>(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('이 책이 맞나요?'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (imageUrl.isNotEmpty)
                                Center(child: Image.network(imageUrl, height: 150, fit: BoxFit.contain)),
                              const SizedBox(height: 16),
                              Text('제목: $title', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('저자: $author'),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('아니요'),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('네'),
                            onPressed: () {
                              Navigator.of(dialogContext).pop(item);
                            },
                          ),
                        ],
                      );
                    },
                  );

                  if (!mounted) return;

                  if (dialogResult != null) {
                    Navigator.of(context).pop(dialogResult);
                  } else {
                    _controller.start();
                  }
                }
              }
            },
          ),
          CustomPaint(
            painter: ScannerOverlay(scanWindow),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ScannerOverlay extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlay(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()..addRect(scanWindow);

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    canvas.drawPath(backgroundWithCutout, backgroundPaint);
    canvas.drawRect(scanWindow, borderPaint);

    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.center.dy),
      Offset(scanWindow.right, scanWindow.center.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

}
