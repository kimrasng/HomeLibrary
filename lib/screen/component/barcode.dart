import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Barcode extends StatefulWidget {
  const Barcode({super.key});

  @override
  State<Barcode> createState() => _BarcodeState();
}

class _BarcodeState extends State<Barcode> {
  // mobile_scanner 컨트롤러
  final MobileScannerController _controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    // 스캔 영역 설정
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(const Offset(0, -50)), // 스캔 창을 약간 위로 이동
      width: 250,
      height: 200,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('QR Scan')),
      body: Stack(
        children: [
          // 바코드 스캔 위젯
          MobileScanner(
            controller: _controller, // 컨트롤러 연결
            scanWindow: scanWindow, // 스캔 영역 지정
            onDetect: (capture) { // 바코드 감지하면 실행
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                _controller.stop(); // 바코드 감지하면 스캔 중지
                final barcodeValue = barcodes.first.rawValue; // 감지된 바코드 값

                // 임시 팝업
                showDialog(
                  context: context,
                  barrierDismissible: false, // 팝업 영역 이외의 공간 눌러도 닫히는거 방지
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('스캔 완료'),
                      content: Text(barcodeValue ?? "데이터 없음"),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('다시 스캔'),
                          onPressed: () {
                            Navigator.of(context).pop(); // 팝업 닫기
                            _controller.start(); // 스캔 다시 시작
                          },
                        ),
                        TextButton(
                          child: const Text('확인'),
                          onPressed: () {
                            Navigator.of(context).pop(); // 팝업 닫기
                            Navigator.of(context).pop(barcodeValue); // 이전 화면으로 바코드 값과 함께 돌아가기
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
          // 스캐너 위에 겹쳐서 보여줄 UI
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

    // 스캔 영역을 제외한 배경을 어둡게
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    // 스캔 영역의 테두리를 그리기
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 스캔 영역 중앙의 빨간 선을 그리기
    final linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    canvas.drawPath(backgroundWithCutout, backgroundPaint); // 어두운 배경 그리기
    canvas.drawRect(scanWindow, borderPaint); // 테두리 그리기

    // 중앙의 빨간 선 그리기
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
