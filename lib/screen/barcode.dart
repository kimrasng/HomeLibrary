import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:homelibrary/controller/controller.dart';
import 'package:homelibrary/model/Library.dart';

class Barcode extends StatefulWidget {
  final LibraryModle library;

  const Barcode({super.key, required this.library});

  @override
  State<Barcode> createState() => _BarcodeState();
}

class _BarcodeState extends State<Barcode> {
  final LibraryController _libraryController = LibraryController();
  Map<String, dynamic>? _item;
  String _error = '';
  bool _isSuccess = false; // 책이 하나라도 추가되었는지 여부

  final MobileScannerController _controller = MobileScannerController();

  Future<void> _ISBNSearch(String isbn) async {
    if (isbn.isEmpty) {
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
      final restApiKey = dotenv.env["REST_API_KEY"];
      if (restApiKey == null) {
        setState(() {
          _error = 'API 키를 찾을 수 없습니다.';
        });
        return;
      }

      final uri = Uri.parse('https://dapi.kakao.com/v3/search/book?query=$isbn&target=isbn');
      final res = await http.get(uri, headers: {
        'Authorization': 'KakaoAK $restApiKey',
      });
      
      if (res.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(utf8.decode(res.bodyBytes));
        final items = json['documents'] as List<dynamic>?;

        if (items == null || items.isEmpty) {
          setState(() {
            _error = '책 정보를 찾을 수 없습니다.';
          });
          return;
        }

        setState(() {
          _item = items.first as Map<String, dynamic>;
        });
      } else {
        setState(() {
          _error = '서버 오류 : ${res.statusCode}';
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
      appBar: AppBar(
        title: const Text('바코드 스캔'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 나갈 때 책이 추가되었다면 true를 반환하여 목록 새로고침 유도
            Navigator.of(context).pop(_isSuccess);
          },
        ),
      ),
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

                if (!mounted) return;
                Navigator.of(context).pop(); // 로딩 닫기

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
                  final imageUrl = item['thumbnail'] ?? '';
                  final title = item['title'] ?? '제목 없음';
                  final authorsList = item['authors'] as List<dynamic>? ?? [];
                  final author = authorsList.join(', ');

                  showDialog(
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
                              _controller.start(); // 다시 스캔 시작
                            },
                          ),
                          TextButton(
                            child: const Text('네'),
                            onPressed: () async {
                              // 책 정보를 모델로 변환
                              final newBook = BookItemModel(
                                title: title,
                                author: author,
                                isbn: item['isbn'],
                                coverUrl: item['thumbnail'],
                                detailUrl: item['url'],
                              );
                              
                              // 서재에 책 추가
                              await _libraryController.addBook(widget.library.id, newBook);
                              _isSuccess = true;

                              if (!mounted) return;
                              Navigator.of(dialogContext).pop();
                              
                              // TODO: 나중에 설정값에 따라 바로 pop 할지 정할 수 있음
                              // 현재는 연속 스캔을 위해 스캐너 다시 시작
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('책이 추가되었습니다.'), duration: Duration(seconds: 1)),
                              );
                              _controller.start(); 
                            },
                          ),
                        ],
                      );
                    },
                  );
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
