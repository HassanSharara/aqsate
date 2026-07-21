import 'package:aqsatee/models/installment.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:printing/printing.dart';
import 'package:sharara_usb/models/usb/usb.dart';
import 'package:sharara_usb/sharara_usb_platform_interface.dart';

class _GeneratorParams {
  final img.Image image;
  final PaperSize paperSize;
  final CapabilityProfile profile;

  _GeneratorParams(this.image, this.paperSize, this.profile);
}

List<int> _processEscPosIsolate(_GeneratorParams params) {
  final generator = Generator(params.paperSize, params.profile);
  return generator.image(params.image);
}

final class UsbHandler {
  UsbHandler._();

  static final UsbHandler instance = UsbHandler._();

  final ValueNotifier<UsbDevice?> selectedDevice = ValueNotifier(null);

  Future<List<UsbDevice>?> getDevices() async {
    try {
      return await ShararaUsbPlatform.instance.getConnectedUsbList();
    } catch (_) {}
    return null;
  }

  Future<pw.Document> _buildInstallmentPdf(
      final InstallmentRow r, {
        required PdfPageFormat pageFormat,
        required bool isReceipt,
      }) async {
    final totalRemain = r.remainingTotal;
    final paid = r.installment.paymentAmount;
    final String? paymentDate = r.installment.paymentDate;
    const String projectName = "منفذ الفيض الغالي";

    final font = await PdfGoogleFonts.cairoBold();
    final doc = pw.Document();

    final double titleSize = isReceipt ? 18 : 22;
    // final double subtitleSize = isReceipt ? 14 : 16;
    final double bodySize = isReceipt ? 10 : 14;
    final double highlightSize = isReceipt ? 11 : 15;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          final content = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                projectName,
                style: pw.TextStyle(
                  font: font,
                  fontSize: titleSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              // pw.SizedBox(height: isReceipt ? 4 : 6),
              // pw.Text(
              //   "وصل استلام قسط",
              //   style: pw.TextStyle(
              //     font: font,
              //     fontSize: subtitleSize,
              //   ),
              // ),
              pw.SizedBox(height: isReceipt ? 8 : 16),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: isReceipt ? 8 : 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("تاريخ الدفع:", style: pw.TextStyle(font: font, fontSize: bodySize)),
                  pw.Text(paymentDate ?? 'غير محدد', style: pw.TextStyle(font: font, fontSize: bodySize)),
                ],
              ),
              pw.SizedBox(height: isReceipt ? 4 : 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "المبلغ المدفوع:",
                    style: pw.TextStyle(
                      font: font,
                      fontSize: highlightSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "$paid د.ع",
                    style: pw.TextStyle(
                      font: font,
                      fontSize: highlightSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: isReceipt ? 4 : 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("المتبقي الكلي:", style: pw.TextStyle(font: font, fontSize: bodySize)),
                  pw.Text("$totalRemain د.ع", style: pw.TextStyle(font: font, fontSize: bodySize)),
                ],
              ),
              pw.SizedBox(height: isReceipt ? 8 : 16),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: isReceipt ? 8 : 16),
              pw.Text(
                "شكراً لتعاملكم معنا",
                style: pw.TextStyle(
                  font: font,
                  fontSize: isReceipt ? 10 : 12,
                ),
              ),
            ],
          );

          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: isReceipt
                ? content
                : pw.Container(
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: content,
            ),
          );
        },
      ),
    );

    return doc;
  }

  Future<void> printInstallmentRow(final InstallmentRow r,BuildContext context) async {
    final selectedUsb = selectedDevice.value;
    final sMessenger = ScaffoldMessenger.of(context);

    if (selectedUsb == null) {
      sMessenger.showSnackBar(SnackBar(content: Text("يجب في الاول اختيار الطابعة من اعدادات الطابعة",style:TextStyle(color:Colors.white,
        fontSize:22
      ),),
        backgroundColor:Colors.red,
      ),
      );
      return;
    }

    final snack = SnackBar(content: Row(
      children: [
        SizedBox(
            height:10,
            width:15,
            child: LinearProgressIndicator()),
        const SizedBox(width: 5,),
        Text("جاري ارسال البيانات الى الطابعة"),

      ],
    ),
    );
    sMessenger.showSnackBar(snack,
    );

    try {
      final doc = await _buildInstallmentPdf(
        r,
        pageFormat: PdfPageFormat.roll80,
        isReceipt: true,
      );

      final documentBytes = await doc.save();
      final profile = await CapabilityProfile.load();
      const paperSize = PaperSize.mm80;

      final List<int> bytes = [];
      final pdfx.PdfDocument document = await pdfx.PdfDocument.openData(documentBytes);
      // final Generator generator  = Generator(paperSize, profile);

      for (int i = 0; i < document.pagesCount; i++) {
        final pdfx.PdfPage page = await document.getPage(i + 1);

        final double height = page.height * 3;
        final int width = page.width.toInt() * 2 + 120;

        final pdfx.PdfPageImage? pageImage = await page.render(
          width: width.toDouble(),
          height: height,
        );

        if (pageImage != null) {
          final image = await compute(img.decodeImage, pageImage.bytes);

          if (image != null) {
            final List<int> imageBytes = await compute(
              _processEscPosIsolate,
              _GeneratorParams(image, paperSize, profile),
            );
            bytes.addAll(imageBytes);
          }
        }
        await page.close();
      }

      // bytes.addAll(generator.cut());
      // bytes.addAll(generator.text("hello world"));
      // bytes.addAll(generator.feed(4));
      await document.close();

      if (bytes.isNotEmpty) {
        if(!await selectedUsb.isConnected )await selectedUsb.connect();
        await selectedUsb.writeData(bytes);
      }
    }catch(_){}
    finally {
      try {
        sMessenger.hideCurrentSnackBar();
        sMessenger.showSnackBar(SnackBar(content: Text("تمت الطباعة بنجاح",style:TextStyle(color:Colors.white,
            fontSize:22
        ),),
          backgroundColor:Colors.green,
        ),
        );
      }catch(_){

      }

    }
  }


  Future<void> shareInstallmentPdf(final InstallmentRow r) async {
    final doc = await _buildInstallmentPdf(
      r,
      pageFormat: PdfPageFormat.a4,
      isReceipt: false,
    );

    final pdfBytes = await doc.save();
    final String date = r.installment.paymentDate ?? 'جديد';

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: "وصل_قسط_$date.pdf",
    );
  }
}