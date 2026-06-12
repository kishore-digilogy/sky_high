import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// ignore: depend_on_referenced_packages
import 'package:syncfusion_flutter_core/theme.dart';

class MiniPdfPreview extends StatelessWidget {
  final String pdfUrl;

  const MiniPdfPreview({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: IgnorePointer(
        child: SfPdfViewerTheme(
          data: SfPdfViewerThemeData(
            backgroundColor: Colors.transparent,
          ),
          child: SfPdfViewer.network(
            pdfUrl,
            enableDoubleTapZooming: false,
            enableTextSelection: false,
            canShowScrollHead: false,
            canShowScrollStatus: false,
            canShowPaginationDialog: false,
            pageLayoutMode: PdfPageLayoutMode.single,
            onDocumentLoadFailed: (details) {
              debugPrint('Mini PDF Load Failed: ${details.error}');
            },
          ),
        ),
      ),
    );
  }
}
