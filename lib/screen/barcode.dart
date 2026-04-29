import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:homelibrary/controller/controller.dart';
import 'package:homelibrary/model/Library.dart';

class Barcode extends StatefulWidget {
  final LibraryModel library;

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

      final uri = Uri.parse(
        'https://dapi.kakao.com/v3/search/book?query=$isbn&target=isbn',
      );
      final res = await http.get(
        uri,
        headers: {'Authorization': 'KakaoAK $restApiKey'},
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(
          utf8.decode(res.bodyBytes),
        );
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
    final colorScheme = Theme.of(context).colorScheme;

    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(const Offset(0, -50)),
      width: 250,
      height: 200,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('바코드 스캔'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
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
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator(color: Colors.white)),
                );

                await _ISBNSearch(barcodeValue);

                if (!mounted) return;
                Navigator.of(context).pop(); // 로딩 닫기

                if (_error.isNotEmpty) {
                  _showErrorDialog(context, colorScheme);
                  return;
                }

                if (_item != null) {
                  final item = _item!;
                  final imageUrl = item['thumbnail'] ?? '';
                  final title = item['title'] ?? '제목 없음';
                  final authorsList = item['authors'] as List<dynamic>? ?? [];
                  final author = authorsList.join(', ');
                  final scannedIsbn = item['isbn'] as String? ?? '';

                  // 중복 감지: 같은 서재에 동일 ISBN 책이 있는지 확인
                  final libraries = await _libraryController.loadLibraries();
                  final currentLib = libraries.firstWhere(
                    (lib) => lib.id == widget.library.id,
                  );
                  final isDuplicate = scannedIsbn.isNotEmpty &&
                      currentLib.books.any((b) =>
                          b.isbn != null && b.isbn!.contains(scannedIsbn.split(' ').first));

                  if (!mounted) return;

                  if (isDuplicate) {
                    _showDuplicateDialog(context, colorScheme, title);
                    return;
                  }

                  _showConfirmDialog(
                    context,
                    colorScheme,
                    item: item,
                    imageUrl: imageUrl,
                    title: title,
                    author: author,
                  );
                }
              }
            },
          ),
          CustomPaint(painter: ScannerOverlay(scanWindow)),
          // Hint text below scan window
          Positioned(
            left: 0,
            right: 0,
            top: scanWindow.bottom + 32,
            child: Text(
              '바코드를 사각형 안에 맞춰주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error Dialog ─────────────────────────────────────────────────────

  void _showErrorDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: colorScheme.error,
        ),
        title: const Text('오류'),
        content: Text(
          _error,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _controller.start();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // ── Duplicate Dialog ─────────────────────────────────────────────────

  void _showDuplicateDialog(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.library_books,
          color: colorScheme.tertiary,
        ),
        title: const Text('이미 등록된 책'),
        content: Text(
          '"$title"은(는) 이미 서재에 있습니다.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _controller.start();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // ── Confirmation Dialog ──────────────────────────────────────────────

  void _showConfirmDialog(
    BuildContext context,
    ColorScheme colorScheme, {
    required Map<String, dynamic> item,
    required String imageUrl,
    required String title,
    required String author,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // popScop로 감싸서 뒤로가기 버튼눌엇을때 _controller.start가 실행되도록
        return PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              _controller.start();
            }
          },
          child: AlertDialog(
            title: const Text('이 책이 맞나요?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cover image
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                const SizedBox(height: 16),
                // Title
                Text(
                  title,
                  style: Theme.of(dialogContext).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (author.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    author,
                    style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _controller.start(); // 다시 스캔 시작
                },
                child: const Text('아니요'),
              ),
              FilledButton(
                onPressed: () async {
                  // 책 정보를 모델로 변환
                  final newBook = BookItemModel(
                    title: title,
                    author: author,
                    isbn: item['isbn'],
                    coverUrl: item['thumbnail'],
                    detailUrl: item['url'],
                    publisher: item['publisher'],
                    description: item['contents'],
                  );

                  // 서재에 책 추가
                  await _libraryController.addBook(
                    widget.library.id,
                    newBook,
                  );
                  _isSuccess = true;

                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();

                  // TODO: 나중에 설정값에 따라 바로 pop 할지 정할 수 있음
                  // 현재는 연속 스캔을 위해 스캐너 다시 시작
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('책이 추가되었습니다.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  _controller.start();
                },
                child: const Text('네'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ── Scanner Overlay ──────────────────────────────────────────────────

class ScannerOverlay extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlay(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(backgroundWithCutout, backgroundPaint);

    // Corner brackets
    _drawCornerBrackets(canvas, scanWindow);

    // Red scan line
    final linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(scanWindow.left + 16, scanWindow.center.dy),
      Offset(scanWindow.right - 16, scanWindow.center.dy),
      linePaint,
    );
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect) {
    const bracketLength = 28.0;
    const strokeWidth = 3.5;
    const radius = 16.0;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    final topLeft = Path()
      ..moveTo(rect.left, rect.top + bracketLength)
      ..lineTo(rect.left, rect.top + radius)
      ..arcToPoint(
        Offset(rect.left + radius, rect.top),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.left + bracketLength, rect.top);
    canvas.drawPath(topLeft, paint);

    // Top-right corner
    final topRight = Path()
      ..moveTo(rect.right - bracketLength, rect.top)
      ..lineTo(rect.right - radius, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.right, rect.top + bracketLength);
    canvas.drawPath(topRight, paint);

    // Bottom-left corner
    final bottomLeft = Path()
      ..moveTo(rect.left, rect.bottom - bracketLength)
      ..lineTo(rect.left, rect.bottom - radius)
      ..arcToPoint(
        Offset(rect.left + radius, rect.bottom),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.left + bracketLength, rect.bottom);
    canvas.drawPath(bottomLeft, paint);

    // Bottom-right corner
    final bottomRight = Path()
      ..moveTo(rect.right - bracketLength, rect.bottom)
      ..lineTo(rect.right - radius, rect.bottom)
      ..arcToPoint(
        Offset(rect.right, rect.bottom - radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.right, rect.bottom - bracketLength);
    canvas.drawPath(bottomRight, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
