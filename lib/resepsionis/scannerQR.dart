import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  final Function(String, String, String, String) onScannedData;

  QRScannerScreen({required this.onScannedData});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool isProcessing = false; // Prevent multiple scans

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan QR Code")),
      body: MobileScanner(
        controller: MobileScannerController(facing: CameraFacing.front),
        onDetect: (BarcodeCapture capture) {
          if (isProcessing) return; // Prevent duplicate execution

          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            List<String> scannedValues = barcodes.first.rawValue!.split('|');
            if (scannedValues.length == 4) {
              isProcessing = true; // Set flag to prevent multiple calls
              widget.onScannedData(
                scannedValues[0],
                scannedValues[1],
                scannedValues[2],
                scannedValues[3],
              );
              Navigator.pop(context); // Close scanner after scanning
            }
          }
        },
      ),
    );
  }
}
